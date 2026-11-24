#!/usr/bin/env python3
"""Run the 30-day Pawprint Days economy scenario using Python 3.9+."""

import argparse
import csv
import re
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

HERE = Path(__file__).resolve().parent
APP = HERE.parents[1] / "PawprintDays"
DAYS = 30
PROFILES = {"light": 3_000, "medium": 7_000, "heavy": 12_000}
WEATHER_WEEK = ("overcast", "lightRain", "postRain", "clearMorning", "overcast", "dusk", "lightRain")
STARTER_PET = "pet.03"
STARTER_GOODIES = ("goodie.folded_towel", "goodie.wool_blanket", "goodie.cloth_ball")

# Coordinator rules and scenario inputs. See docs/economy-report.md for the source and cadence.
INDOOR_LIMITS = {"tea": 1, "origami": 1, "hide_seek": 1, "origami_charm": 3}
WISHES_PER_DAY, COINS_PER_WISH = 3, 2
FAVORITE_GREETING_COINS = 2
STREET_GIFT_BOND_DAYS, STREET_GIFT_COINS = 6, 1
LOVED_CURIO_GIFT_COINS = 1
BASE_FIND_CAP, SATCHEL_FIND_CAP = 3, 4
TOWEL_CAP_BONUS = 1
THERMOS_PRICE, SHORT_THERMOS_REFUND, FULL_THERMOS_REFUND = 6, 2, 9
PATINA_USES = 25
# ErrandSupplyPack and collectReturnedErrand (cost, reward, curio).
ERRANDS = {"bakery_bun": (0, 2, False), "ginger_flask": (3, 4, True), "paper_umbrella": (5, 5, True)}
INFLOWS = (
    "steps", "tea", "origami", "hide_seek", "origami_charm", "wishes", "favorite_greeting",
    "street_gift", "walk_quest", "curio_gift", "curio_set", "errand_return", "thermos_refund",
)
SINKS = ("treats", "outings", "wardrobe", "goodies", "rooms", "patch_mend", "errand_supply", "thermos")


@dataclass(frozen=True)
class ShopItem:
    id: str
    name: str
    category: str
    price: int
    capacity: int


def swift_int(source, name):
    match = re.search(rf"\bstatic let {name}(?:: Int)?\s*=\s*([0-9_]+)\b", source)
    if match is None:
        raise ValueError(f"Could not read Swift constant {name}")
    return int(match[1])


def read_rules():
    catalog = (APP / "Models/PetCatalog.swift").read_text(encoding="utf-8")
    ledger = (APP / "Engine/StepCoinLedgerEngine.swift").read_text(encoding="utf-8")
    coordinator = (APP / "Engine/GameCoordinator.swift").read_text(encoding="utf-8")
    indoor = (APP / "Models/IndoorAndRaisingModels.swift").read_text(encoding="utf-8")
    shop_entries = re.findall(r"\bShopItemSpec\((.*?)\n        \)", catalog, re.S)
    pet_entries = re.findall(r"\bPetSpec\((.*?)\n        \)", catalog, re.S)
    curio_entries = re.findall(r"\bCurioSpec\((.*?)\n        \)", catalog, re.S)
    if not all((shop_entries, pet_entries, curio_entries)):
        raise ValueError("Could not read the shop, companion and curio catalogs")

    def field(entry, key, pattern):
        match = re.search(rf"^\s*{key}: {pattern}", entry, re.M)
        if match is None:
            raise ValueError(f"Could not read {key} in catalog entry {entry.strip()}")
        return match[1]

    def string(entry, key):
        return field(entry, key, r'"([^"]+)"')

    items = {}
    for entry in shop_entries:
        item = ShopItem(
            string(entry, "id"), string(entry, "name"), field(entry, "category", r"\.(\w+)"),
            int(field(entry, "priceCoins", r"(\d+)")), int(field(entry, "capacitySlots", r"(\d+)")),
        )
        items[item.id] = item
    pets = {
        string(entry, "id"): (string(entry, "name"), field(entry, "resonantWeathers", r"(\[[^\]]*\])"))
        for entry in pet_entries
    }
    pets = {pet_id: (name, set(re.findall(r"\.(\w+)", tags))) for pet_id, (name, tags) in pets.items()}
    curios = defaultdict(list)
    for entry in curio_entries:
        curios[field(entry, "weatherTag", r"\.(\w+)")].append(string(entry, "id"))
    return items, pets, curios, (
        swift_int(ledger, "stepsPerCoin"),
        swift_int(ledger, "stepsPerPocketFind"),
        swift_int(catalog, "patchMendPriceCoins"),
        swift_int(coordinator, "gingerThermosFullRefundSteps"),
        swift_int(indoor, "rewardCoins"),
    )


def simulate(profile, daily_steps, items, pets, curios, rules):
    steps_per_coin, steps_per_find, mend_price, thermos_threshold, quest_reward = rules
    balance = step_carry = find_carry = total_curios = 0
    new_pets = iter(pet_id for pet_id in pets if pet_id != STARTER_PET)
    invited = {STARTER_PET: 0}
    owned = set(STARTER_GOODIES)
    uses = dict.fromkeys(STARTER_GOODIES, 0)
    mended = set()
    first_mend = None
    first_affordable = dict.fromkeys(owned, 0)
    first_bought = {}
    bond_days = defaultdict(int)
    found = set()
    claimed_sets = set()
    rows = []
    shopping_list = sorted(
        (item for item in items.values() if item.category != "treats" and item.id not in owned),
        key=lambda item: item.price,  # Equal prices keep catalog order.
    )
    weekly_treats = [item for item in items.values() if item.category == "treats"]

    for day in range(1, DAYS + 1):
        opening = balance
        earned = dict.fromkeys(INFLOWS, 0)
        spent = dict.fromkeys(SINKS, 0)
        purchases = []
        weather = WEATHER_WEEK[(day - 1) % len(WEATHER_WEEK)]
        pool = curios[weather]

        # Pack at the start of the walk, before any earnings.
        if balance >= THERMOS_PRICE:
            spent["thermos"] = THERMOS_PRICE
            earned["thermos_refund"] = FULL_THERMOS_REFUND if daily_steps >= thermos_threshold else SHORT_THERMOS_REFUND

        pet_id = next(new_pets, STARTER_PET)
        new_invite = pet_id not in invited
        invited.setdefault(pet_id, day)
        bond_days[pet_id] += 1
        earned["favorite_greeting"] = FAVORITE_GREETING_COINS
        if bond_days[pet_id] >= STREET_GIFT_BOND_DAYS:
            earned["street_gift"] = STREET_GIFT_COINS
        # Assume every third encounter offers a stroll chain. All walks cover any 500–800 step quest.
        if day % 3 != 0 and daily_steps >= 800:
            earned["walk_quest"] = quest_reward

        earned["steps"], step_carry = divmod(step_carry + daily_steps, steps_per_coin)
        cap = SATCHEL_FIND_CAP if "outfit.forager_satchel" in owned else BASE_FIND_CAP
        if "outing.towel_pack" in owned:
            cap += TOWEL_CAP_BONUS
        found_today = []
        skipped_finds = 0
        # Eight accepted 15-minute buckets. The Swift picker uses the growing ledger count.
        batch, extra_steps = divmod(daily_steps, 8)
        for bucket in range(8):
            accepted = batch + (bucket < extra_steps)
            finds, find_carry = divmod(find_carry + accepted, steps_per_find)
            allowed = min(finds, cap - len(found_today))
            skipped_finds += finds - allowed
            for offset in range(allowed):
                found_today.append(pool[(total_curios + offset + accepted) % len(pool)])
                total_curios += 1
        pocket_finds = len(found_today)

        earned.update(INDOOR_LIMITS)
        if "pet.02" not in invited:
            earned["origami_charm"] = 0

        # Errands unlock on the first street encounter. Complete one per day.
        supply = {6: "ginger_flask", 0: "paper_umbrella"}.get(day % 7, "bakery_bun")
        cost, reward, errand_find = ERRANDS[supply]
        if opening + sum(earned.values()) - spent["thermos"] < cost:
            supply = "bakery_bun"
            cost, reward, errand_find = ERRANDS[supply]
        spent["errand_supply"], earned["errand_return"] = cost, reward
        if errand_find:
            found_today.append(pool[(total_curios + 7) % len(pool)])
            total_curios += 1
        earned["wishes"] = WISHES_PER_DAY * COINS_PER_WISH

        # Gift all of today's matching finds to a resident, preferring today's greeted pet.
        recipients = [pet_id, *(pet for pet in invited if pet != pet_id)]
        recipient = next((pet for pet in recipients if weather in pets[pet][1]), None)
        if found_today and recipient is not None:
            earned["curio_gift"] = len(found_today) * LOVED_CURIO_GIFT_COINS
            if recipient != pet_id:
                bond_days[recipient] += 1
        found.update(found_today)
        if weather not in claimed_sets and found.issuperset(pool):
            claimed_sets.add(weather)
            earned["curio_set"] = 10 + 2 * len(pool)

        balance += sum(earned.values()) - sum(spent.values())

        # One occupied room solve a day. Keep the three starter placements in slot order.
        remaining_pets = len(invited)
        patches = []
        for goodie_id in STARTER_GOODIES:
            if remaining_pets <= 0:
                break
            uses[goodie_id] += 1
            remaining_pets -= items[goodie_id].capacity
            if uses[goodie_id] >= PATINA_USES and goodie_id not in mended and balance >= mend_price:
                balance -= mend_price
                spent["patch_mend"] += mend_price
                mended.add(goodie_id)
                patches.append(goodie_id)
                first_mend = first_mend or day

        for item in items.values():
            if balance >= item.price:
                first_affordable.setdefault(item.id, day)
        cash_before_shop = balance

        # Buy at most one scheduled treat and one cheapest unowned lasting item or trial outing.
        to_buy = []
        if day % 7 == 0:
            to_buy.append(weekly_treats[(day // 7 - 1) % len(weekly_treats)])
        if shopping_list:
            to_buy.append(shopping_list[0])
        for item in to_buy:
            if balance < item.price:
                continue
            balance -= item.price
            spent[item.category] += item.price
            purchases.append(item.id)
            first_bought.setdefault(item.id, day)
            if item.category != "treats":
                shopping_list.pop(0)
                owned.add(item.id)

        rows.append({
            "profile": profile, "day": day, "accepted_steps": daily_steps, "weather": weather,
            "opening_balance": opening, **{f"earned_{key}": value for key, value in earned.items()},
            "total_inflow": sum(earned.values()), **{f"spent_{key}": value for key, value in spent.items()},
            "total_spend": sum(spent.values()), "cash_before_shop": cash_before_shop, "closing_balance": balance,
            "pocket_find_cap": cap, "pocket_finds": pocket_finds, "pocket_finds_discarded_at_cap": skipped_finds,
            "errand_supply": supply, "new_companion_id": pet_id if new_invite else "",
            "purchases": "|".join(purchases), "mended_placements": "|".join(patches),
        })

    milestones = [
        (profile, "companion", pet_id, name, 0, invited.get(pet_id), None)
        for pet_id, (name, _) in pets.items()
    ] + [
        (profile, item.category, item.id, item.name, item.price, first_affordable.get(item.id), first_bought.get(item.id))
        for item in items.values()
    ] + [
        (profile, "patch", "patch.mend", "First patch mend", mend_price, first_mend, first_mend),
    ]
    return rows, milestones


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=HERE, help="Directory for the generated CSVs")
    args = parser.parse_args()
    rules = read_rules()
    daily = []
    milestones = []
    for profile, steps in PROFILES.items():
        rows, events = simulate(profile, steps, *rules)
        daily.extend(rows)
        milestones.extend(events)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    with (args.output_dir / "daily.csv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=daily[0].keys(), lineterminator="\n")
        writer.writeheader()
        writer.writerows(daily)
    with (args.output_dir / "affordability.csv").open("w", encoding="utf-8", newline="") as stream:
        writer = csv.writer(stream, lineterminator="\n")
        writer.writerow(("profile", "category", "id", "name", "list_price", "first_available_day", "first_purchase_day"))
        writer.writerows(milestones)


if __name__ == "__main__":
    main()
