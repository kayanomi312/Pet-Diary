# Pawprint Days economy simulation

The 30-day run models a fresh save for light (3,000 accepted steps/day), medium (7,000), and heavy (12,000) walkers. All three can buy a ribbon on day 1 and invite all five additional companions by day 5 given the assumed encounters. The light walker buys four of the six paid furniture goodies. Medium buys all six but ends 3 coins short of the first room theme. Heavy buys two room themes. All three mend three starter placements.

Run `python3 scripts/economy-sim/simulate.py` from the repo root to regenerate the [daily ledger](../scripts/economy-sim/daily.csv) and [affordability table](../scripts/economy-sim/affordability.csv) with Python 3.9+. Use `--output-dir PATH` to write elsewhere. The simulator reads catalog entries, step rates, quest reward, thermos threshold, and patch price from the Swift sources. The remaining payout rules and activity schedule are defined in the [simulator](../scripts/economy-sim/simulate.py).

## Coins over 30 days

| Inflow or spend | Light | Medium | Heavy |
|---|---:|---:|---:|
| Step coins | 450 | 1,050 | 1,800 |
| Tea / origami / hide-and-seek | 30 / 30 / 30 | 30 / 30 / 30 | 30 / 30 / 30 |
| Origami charm drops | 90 | 90 | 90 |
| Daily wishes | 180 | 180 | 180 |
| Favorite greetings / street gifts / walk quests | 60 / 22 / 60 | 60 / 22 / 60 | 60 / 22 / 60 |
| Loved curio gifts / weather sets | 72 / 82 | 141 / 82 | 141 / 82 |
| Errand returns | 80 | 80 | 80 |
| Thermos refunds | 252 | 252 | 252 |
| **Total inflow** | **1,438** | **2,107** | **2,857** |
| Treats / outing packs | 29 / 55 | 29 / 55 | 29 / 55 |
| Outfits / goodies / rooms | 356 / 620 / 0 | 596 / 800 / 0 | 596 / 800 / 820 |
| Patch mending | 30 | 30 | 30 |
| Errand supplies / thermoses | 32 / 168 | 32 / 168 | 32 / 168 |
| **Total spend** | **1,290** | **1,710** | **2,530** |
| **Day 30 balance** | **148** | **397** | **327** |

| Milestone | Light | Medium | Heavy |
|---|---:|---:|---:|
| Balance at end of day 7 / 14 / 21 | 99 / 29 / 145 | 295 / 45 / 113 | 470 / 230 / 1 |
| Bakery box, affordable / bought | 2 / 6 | 1 / 6 | 1 / 6 |
| Forager satchel, affordable / bought | 5 / 17 | 3 / 12 | 2 / 12 |
| Window cushion, affordable / bought | 22 / — | 3 / 19 | 3 / 15 |
| Rainy-season theme, affordable / bought | — / — | — / — | 5 / 21 |
| First patch mend, eligible and bought | 25 | 25 | 25 |
| Pocket finds granted / discarded by cap | 64 / 0 | 133 / 17 | 133 / 124 |

`first_available_day` in the affordability CSV is the first day the wallet can pay a shop item's list price after walk, errand, and patch activity, before that day's shop purchases. Day 0 marks starter possessions. Companion rows give the day they join at zero coin cost. Blank days mean the milestone was not reached during the modeled month. Light can afford the window cushion on day 22 but buys the cheaper cedar perch first.

## Daily caps and limits

| Source | App rule and modeled cadence |
|---|---|
| Walking | 1 coin per 200 accepted steps with carry and no daily coin ceiling. The three profiles earn 15, 35, and 60 step coins each day. |
| Pocket finds | Every 1,400 accepted buddy steps with carry. Base cap 3/day, satchel ownership changes it to 4, and the active towel pack and sachet each add 1 (maximum 6 with all three). The run buys the towel on day 5, then the satchel on day 17 for light or day 12 for medium and heavy. The sachet's +35% progress and +1 cap are outside the thermos itinerary. Errand finds skip the walking award check and count toward the day's ledger total if collected before a walk. |
| Indoor activities and wishes | Tea, origami, and hide-and-seek each pay 1/day. Juniper's origami charms pay up to 3/day. The daily board pays 2 coins per completed wish, up to 6/day. The run collects all these rewards. |
| Street activities | A favorite first greeting pays 2 per pet per day. The modeled route has one street greeting per day and offers a chain instead of a quest every third encounter. Quests pay 3 coins each and allow one active quest at a time. Street gifts pay 1 per qualifying encounter once the pet reaches 6 shared days. |
| Curio gifts and sets | A loved curio gift pays 1 once per entry. A completed weather set pays `10 + 2 × set size` once per set. |
| Thermoses and errands | A 6-coin thermos pays 9 from 1,500 session steps or 2 for a shorter qualifying session. The refund is per eligible stroll. Errands limit concurrency to one active pet errand, and the run collects one return per day. |

Source rules are in [StepCoinLedgerEngine.swift](../PawprintDays/Engine/StepCoinLedgerEngine.swift), [GameCoordinator.swift](../PawprintDays/Engine/GameCoordinator.swift), [GameCoordinator+IndoorAndRaising.swift](../PawprintDays/Engine/GameCoordinator%2BIndoorAndRaising.swift), and [GameCoordinator+Progression.swift](../PawprintDays/Engine/GameCoordinator%2BProgression.swift). [GameplayBalanceTests.swift](../PawprintDaysTests/GameplayBalanceTests.swift) covers indoor caps, thermos payouts, the sachet cap, greetings, curio rewards, and walk quests.

The itinerary assumes eight step samples per day with the starter buddy, repeating weather, one successful favorite greeting before walking, and the five new street invites in catalog order. Actual invitations depend on which pets are encountered. The indoor window route costs zero and takes three daily greetings per visitor. The run buys a thermos when the morning wallet allows it, alternates free bun errands with a flask and umbrella at the end of each week, and gifts same-day finds when a resident loves their weather. It keeps starter furniture in place with one occupied room solve per day, buys one scheduled weekly treat and at most one cheapest unowned item or trial outing per day, and pays for a patch once a starter placement reaches 25 uses. These are scenario assumptions. Fewer activities, different weather or step batches, and saving for a favorite item can change the dates. The run omits mobility credit, other stroll charms, offspring, mentorship, and repeat outing purchases.

## Selected price target

Set the rainy-season theme's `priceCoins` in `ShopCatalog.items` to **300 coins** for the next balance pass. The baseline tables and CSVs use the current 400-coin price. [PetCatalog.swift](../PawprintDays/Models/PetCatalog.swift)

At 300 coins, the medium walker buys the theme on day 29 and ends day 30 with 97 coins. In a rerun with two daily wishes and two origami charm drops claimed per day, the medium walker buys it on day 30 and ends with 7 coins. The rest of the itinerary follows the baseline, including cheapest-first shopping. Use day 30 as a playtest target for the first room theme.

## Other tuning candidates

| Constant and file | Current → proposed | Why |
|---|---|---|
| `ShopCatalog.items` → `outfit.forager_satchel.priceCoins` in [PetCatalog.swift](../PawprintDays/Models/PetCatalog.swift) | 140 → 100 | In a one-change rerun, light buys it on day 10 instead of day 17. Medium and heavy each buy it two days earlier and gain two finds. Light never hits the cap, so its benefit is earlier ownership. |
| `StrollSatchelCharm.priceCoins` → `.gingerThermos` in [GameTypes.swift](../PawprintDays/Models/GameTypes.swift) | 6 → 7 | Keep the full 9-coin refund and trim the net faucet from +3 to +2 per qualifying stroll (28 fewer coins at 28 uses). A qualifying short stroll goes from net −4 to −5. Consider that cost when deciding whether to tune the thermos. |
