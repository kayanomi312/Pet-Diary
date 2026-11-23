# Pawprint Days — GameCoordinator split (Phase 1.1 design)

_Status: design, approved for execution by the lead. Executor: Codex (Phase 1.2), one store per PR.
Baseline: `GameCoordinator.swift` 1,626 lines + `+IndoorAndRaising` 569 + `+Progression` 398 + `+Fixtures` 162 ≈ 2,750 lines, one `@MainActor @Observable` class._

## 1. Goals and non-goals

**Goals**
- Turn `GameCoordinator` into a thin **facade** over six feature stores, so parallel work (notifications, daily rhythm, seasonal events, content) lands in separate files and doesn't collide.
- **No view changes in Phase 1.2.** Every member views use today keeps working on `GameCoordinator` through forwarding shims. Views move to stores later (Phase 1.3+), one screen at a time.
- **No behavior changes.** Every PR is a pure move plus re-wiring. The 42 existing tests and `SchemaMigrationTests` stay green and unedited, except for the mechanical edits listed in §8.

**Non-goals (separate tickets, not part of 1.2)**
- Changing the SwiftData schema or splitting the `indoorStateData` blob (that needs a V3 migration; see `PawprintMigrationPlan`).
- Making `reloadAll()` incremental. It stays as the single "refetch everything" pass, now delegated to stores.
- Fixing the behavior quirks in §9. Write them down and keep them.

## 2. Target shape

```
                         ┌──────────────────────────────────────────┐
  Views / Intents ─────▶ │ GameCoordinator (facade, @Observable)    │  navigation + tutorial UI state,
  DiaryExportService     │  forwarding shims  ·  cross-store flows  │  app lifecycle, reloadAll, flows
                         └───────┬──────────────────────────────────┘
                                 │ owns
   L5  StrollStore ──────────────┤  activeStroll, summary, Live Activity
   L4  StreetStore ──────────────┤  anchors, encounters-commit, discovery, geofence, visitors
   L3  ProgressionStore ─────────┤  unlocks, wishes, quests, favourite gestures, curio sets
   L2  SunroomStore ─────────────┤  residents, home spots, mentorship, indoor play, raising
   L1  DiaryStore · EconomyStore ┤  diary days + encounter logs · ledger, coins, steps, curios
   L0  GameEnvironment ──────────┘  modelContext, clock, weather, whisper, services, events
```

### Rules (enforced in review)
1. **Downward-only dependencies.** A store may hold a reference to (and call) stores in **lower layers only**. Stores in the same layer don't reference each other (Diary ↔ Economy).
2. **Cross-feature flows live in the facade.** When one user action fans out to several stores (greeting at a corner, ingesting steps, buying an item, a new day), the facade method runs the steps in the current order. Stores expose the single-feature pieces.
3. **Upward notifications go through `GameEnvironment.emit(_:)`**, never through a back-reference. Today there's exactly one: "a daily wish was completed" (`markDailyWishCompleted`). Diary (`savePersonalNote` → `.writeDiary`) and Sunroom (tea, origami, feather wand, hide-and-seek, errands, window visitor, picnic snapshot, offspring nurture) raise it, and Progression handles it. Street's greeting wish is marked by the facade flow (§7).
4. **One persistence path.** Stores never call `modelContext.save()` + `reloadAll()` themselves. They call `environment.commit()`, which does both (save, then the facade's `reloadAll`). This is the same sequence as today, just in one place.
5. **Stores are `@MainActor @Observable final class`**, created once in `GameCoordinator.init`, and exposed as `let` properties (`coordinator.street`, …). No singletons, no SwiftUI `@Environment` injection in Phase 1.
6. **Stores never write facade UI state** (`currentScreen`, sheets, tutorial flags). A store method that today navigates returns the navigation intent instead, and the facade shim applies it (see `attemptOpenAnchor` in §4).
7. **File layout:** `PawprintDays/Engine/Stores/<Name>Store.swift` (+ `<Name>Store+<Topic>.swift` if a store tops 600 lines). Facade flows go in `Engine/GameCoordinator+Flows.swift`, shims in `Engine/GameCoordinator+Shims.swift`.

## 3. L0 — `GameEnvironment`

The shared kernel. It has no game rules; it's what every store needs.

| Member | Moved from `GameCoordinator` | Notes |
|---|---|---|
| `modelContext`, `ownedModelContainer` | same | container kept alive for tests |
| `locationService`, `pedometerService` | same | injected through `init` exactly as today |
| `currentSimulatedDate`, `isUsingSimulatedClock`, `currentLocalDateISO` | same | the game clock |
| `activeWeather`, `hasManualWeatherOverride`, `lastWeatherSyncUTC`, `setManualWeatherPreview(_:)` | same | weather *state* only |
| `fetchLiveWeatherIfDue(around:) async -> WeatherSnapshot?` | first half of `syncLiveWeatherIfNeeded` | throttle + fetch + set `activeWeather`; writing the diary day moves to the facade flow (§7) |
| `transientWhisper`, `showWhisper(_:)` | same | |
| `commit()` | the repeated `try? modelContext.save(); reloadAll()` pair | calls `onCommit` (the facade's `reloadAll`) |
| `save()` | bare `try? modelContext.save()` sites with no reload | keep the distinction, because some sites deliberately don't reload |
| `emit(_ event: GameEvent)` / `onEvent` | new | `enum GameEvent { case dailyWishProgress(DailyWishKind) }` |
| `onLocationMoved` weather hook | the `syncLiveWeatherIfNeeded` call inside `onRealLocationMoved` | the facade runs the weather flow (§7); Street's `start()` receives it as a closure (see L4) |
| `updateIndoorState(commit:_:)`, `indoorState` | `updateIndoorState` (+Progression) **and** the duplicate private `mutateIndoorState` (+IndoorAndRaising). They differ: `mutateIndoorState` saves and calls `reloadAll()` afterwards, while `updateIndoorState` only mutates. Keep both behaviors with `commit: Bool` (no default, so every call site picks). Every former `mutateIndoorState` site passes `commit: true`, and every former `updateIndoorState` site passes `commit: false` | single read-modify-write path for the shared blob; it needs the ledger, so it's a closure set up by `EconomyStore` (see §6) |

`GameEnvironment` is created first. Its `onCommit` / `onEvent` closures are set by the facade **after** all stores exist (weak `self`).

## 4. Store specifications

Each table lists the **current member → new home**. "Shim" means `GameCoordinator` keeps a forwarding member with the old name and signature.

### L1 — `DiaryStore` (diary days + encounter logs)
| Owns state | `diaryDays`, `encounters` |
|---|---|
| Depends on | Environment |
| Moves in | `todayDiaryRecord()`, `activeWalkCompanionID`, `setWalkCompanion(petID:)`, `savePersonalNote(for:note:)`, `toggleStarredTradition(for:)`, `removeEncounter(uuid:)`, `erasePlaceDataForSingleDay(localDateISO:)`, `saveWalkPhoto(for:jpegData:)`; today-record part of `seedInitialWorldIfNeeded`; `onBackgroundVisitRecorded` body → `recordBackgroundVisitNoteIfEmpty()` (the `ledger.backgroundVisitsOptIn` gate stays in the caller, Street, because Diary can't read Economy); new `applyWeather(_ snapshot:)` (diary half of `syncLiveWeatherIfNeeded`, **keeping its `day.deletionState != .placeErased` guard**); new `insert(_ log: EncounterLog)` used by Street and Sunroom |
| `reload()` | fetch + sort `diaryDays` (desc by date) and `encounters` (desc by `createdAtUTC`), same sort as today |
| Events | `savePersonalNote` emits `.dailyWishProgress(.writeDiary)` where it calls `markDailyWishCompleted` today |
| Shims | all of the above plus `diaryDays`, `encounters` |

### L1 — `EconomyStore` (ledger, coins, steps, pocket finds)
| Owns state | `ledger` (the `WalletAndCurioLedger` singleton, including its creation in `init` and re-creation in reset), `newlyUnpackedCurio` |
|---|---|
| Depends on | Environment |
| Moves in | `isNearPocketFind`, `stepsUntilNextPocketFind`, `todaysPocketFindCount`, `isGingerTeaActive`; `dailyPocketFindCap` becomes `dailyPocketFindCap(extra:)` (the stroll's sachet bonus is passed in); `indoorCoinDailyLimits`, `remainingIndoorCoins(for:)`, `grantIndoorCoinIfAvailable(_:)`; `toggleMobilityRollMode(_:)`, `toggleOptionalBackgroundVisits(_:)`; the pedometer half of `optInAndSyncPedometer` → `syncPedometerBuckets() async -> [StepBucket]`; the three ledger-engine calls in `ingestSteps` / `ingestLiveStrollSteps` / `recordMobilityRollMovement` → `ingestInterval(...)`, `ingestLiveDelta(...)`, `ingestMobilityRoll(...)` (they take `companionPetID`, `weather`, `placeLabel`, `extraDailyCap`, and return `StepIngestionResult` with no side effects); the sachet loop inside `applyStepIngestionSideEffects` → `applySachetBonusForage(acceptedSteps:placeLabel:extraCap:) -> [ForagedCurioEntry]`; the `spendCoins` call in `purchaseItem` → `spend(item:txID:) -> Bool`; new `grant(coins:)` / `charge(coins:) -> Bool` used by other stores instead of `ledger.coinBalance ± n`; `prependForagedCurio(_:)` (for `collectReturnedErrand`, which today inserts into `ledger.foragedCurios`); `spendPatchMend(spotIndex:txID:) -> Bool` (wraps `StepCoinLedgerEngine.spendPatchMendCoins` for `mendGoodiePatch`) |
| `reload()` | none (the ledger is a live model object) |
| Shims | `ledger`, `newlyUnpackedCurio` (get + set), `isNearPocketFind`, `stepsUntilNextPocketFind`, `todaysPocketFindCount`, `isGingerTeaActive`, `dailyPocketFindCap` (facade passes the stroll extra), `toggleMobilityRollMode`, `toggleOptionalBackgroundVisits`, `remainingIndoorCoins`, `grantIndoorCoinIfAvailable` |

### L2 — `SunroomStore` (companions at home, mentorship, indoor play, raising)
| Owns state | `residents`, `homeSpots`, `teachingIntentions` |
|---|---|
| Depends on | Environment, Diary, Economy |
| Moves in (main file) | `resident(for:)`, `displayName(for:)`, `updatePetNickname`, `invitedCompanionCount`; resident and home-spot seeding from `seedInitialWorldIfNeeded`, `ensureHomeSpotsExist`; `placeGoodie`, `solveHomeRoomNow`, `completeTactileCare`, `togglePinFavorite`, `equipOutfit`, `mendGoodiePatch`, `selectRoomTheme`, `sipGingerTea`, `collectOrigamiCharmGift`, `createPicnicPortionSnapshot` (inserts via `diary.insert`), `discoveredFriendships` + `DiscoveredFriendship`; mentorship: `planMentorship`, `completeMentorshipLesson`, `advanceMentorshipSteps(by:)` (make it internal), `resolveMentorshipsOnNewDay`, `completeKindredHabitPractice` |
| Moves in (`+IndoorAndRaising`, everything except daily wishes) | tea (`brewTeaRecipe`), origami (`craftOrigami`), `ringSunroomWindChime`, `pinPostcardToSunroomWall`, `recordFeatherWandPlaySession`, `foundHidingPet`, errands (`sendPetOnErrand`, `collectReturnedErrand`), window visitors (`currentWindowVisitorPetID`, `hasGreetedWindowVisitorToday`, `greetWindowVisitor`), `triggerSunroomSkit`, nesting & offspring (`NestingPairOption`, `eligibleNestingPairs`, `sunroomOffsprings`, `startMysticalNest`, `nurtureOffspring`, `nurtureAllGrowingOffspring`, `renameOffspring`, `toggleOffspringSunroomStay`, `recordFolkloreChapterRead`) |
| Signature change | `graduateOffspringToCorner(id:siteID:)` reads `anchors` (L4). The store version takes `(id:, anchorSiteID:, anchorLabel:)`; the facade shim keeps the old signature and resolves the anchor from `street` |
| Upward calls replaced | every `markDailyWishCompleted(x)` → `environment.emit(.dailyWishProgress(x))` |
| `reload()` | fetch + sort `residents` (by `petID`), `homeSpots` (by `spotIndex`), `teachingIntentions` |
| Shims | every member listed above that views, `DiaryExportService`, `+Fixtures` or tests use: `residents`, `homeSpots`, `teachingIntentions`, `resident(for:)`, `displayName(for:)`, `updatePetNickname`, `invitedCompanionCount`, the care, room, mentorship and indoor-play methods, `resolveMentorshipsOnNewDay`, `eligibleNestingPairs`, `sunroomOffsprings`, `discoveredFriendships`, `graduateOffspringToCorner` (resolver shim) |

### L3 — `ProgressionStore` (pacing, goals, rewards)
| Owns state | `lastGreetingFeedback` (its only writer is `applyGreetingPreferenceOutcome`); no persisted rows of its own, but it owns the progression **sub-fields** of `indoorState` (§6) |
|---|---|
| Depends on | Environment, Diary, Economy, Sunroom |
| Moves in | daily wishes from `+IndoorAndRaising` (`todayWishesBoard`, `unclaimedCompletedWishesCount`, `markDailyWishCompleted`, `claimDailyWishReward`) and it subscribes to `GameEvent.dailyWishProgress`; from `+Progression`: favourite gestures (`isFavoriteGesture`, `hasDiscoveredFavoriteGesture`, `applyGreetingPreferenceOutcome`), curio gifts and sets (`isCurioGifted`, `giftCurio`, `CurioSetProgress`, `curioSetProgress`, `claimCurioSetReward`), walk quests (`activeWalkQuestToday`, `offerWalkQuestIfAppropriate`, `advanceWalkQuest(by:)`), staged unlocks (`GameFeature`, `isFeatureUnlocked`), `nextMilestoneDays(after:)` |
| Stays out | `nextGoalHint` reads Street (anchors, distances, special visitor). It moves to the facade as a cross-feature derived value (`GameCoordinator+Flows.swift`). Doorstep corner and special visitors move to Street |
| Type nesting | `GameCoordinator.GameFeature`, `.CurioSetProgress`, `.NestingPairOption`, `.SpecialVisitorRule`, `.DiscoveredFriendship` are referenced by views. Move each type to its store (`.NextGoalHint` stays on the facade with `nextGoalHint`), and add `typealias GameFeature = ProgressionStore.GameFeature` (etc.) inside `GameCoordinator` so view code compiles unchanged |
| `reload()` | none |
| Shims | `lastGreetingFeedback`, `todayWishesBoard`, `unclaimedCompletedWishesCount`, `claimDailyWishReward`, `isFavoriteGesture`, `hasDiscoveredFavoriteGesture`, `isCurioGifted`, `giftCurio`, `curioSetProgress`, `claimCurioSetReward`, `activeWalkQuestToday`, `isFeatureUnlocked`, `invitedCompanionCount` (if not already forwarded from Sunroom), `nextMilestoneDays(after:)` (static) |

### L4 — `StreetStore` (corners, greetings, discovery, location)
| Owns state | `anchors`, `isDiscoveringAnchors`, `activeQuietRevisit` |
|---|---|
| Depends on | Environment, Diary, Economy, Sunroom, Progression |
| Moves in | `visibleAnchors`, `activeStrollChainTargetID`, `pawState(for:)`, `distanceMeters(to:)`, `attemptOpenAnchor`, `performQuietRevisit`, `mergeAnchor`, `pinFamiliarCornerAhead`, `renameAnchor`, `hideAnchor`, `discoverRealNeighborhoodAnchors`, `applyDiscoveredAnchors`, anchor seeding from `seedInitialWorldIfNeeded`, `awardStreetEncounterBonusGiftIfEligible`; from `+Progression`: `isStreetLocationUnavailable`, `ensureDoorstepCornerIfNeeded`, `hideSampleNeighborhoodCornersIfFar`, `SpecialVisitorRule`, `specialVisitorRule`, `applySpecialVisitorIfEligible`; `wireLocationCallbacks` (it becomes `start(onMobilityMovement:onLocationMoved:)`: the mobility-roll branch and the weather sync inside `onRealLocationMoved` are flows, so they call back into the facade through those two closures; the background-visit branch checks `economy.ledger.backgroundVisitsOptIn` and calls `diary.recordBackgroundVisitNoteIfEmpty()` directly) |
| Navigation | `attemptOpenAnchor` sets `currentScreen = .encounter(…)` today. The store version returns `(check: AnchorProximityCheck, openScreen: AppScreen?)`; the facade shim assigns `currentScreen` and returns `check`. Haptics, sound, save and the special-visitor whisper stay in the store, in the same order |
| Core method | `commitEncounter(siteID:petID:companionStreetPetID:gesture:inviteHome:forceOfferStrollChain:strollContext:) -> EncounterLog?` holds the body of today's `commitStreetEncounter` up to and including `RoomOccupancySolver.solveRoom`. `strollContext: (packedCharm: StrollSatchelCharm, companionPetID: String?)?` replaces the two reads of `activeStroll` (picnic-bread cameo). The stroll bookkeeping and the post-save tail move to the facade flow (§7) |
| `reload()` | fetch + sort `anchors` (by `siteID`), then `locationService.syncRollingGeofences(for: anchors)` |
| Shims | `anchors`, `visibleAnchors`, `isDiscoveringAnchors`, `activeQuietRevisit` (get + set), `activeStrollChainTargetID`, `isStreetLocationUnavailable`, `pawState`, `distanceMeters`, `attemptOpenAnchor` (applies navigation), `performQuietRevisit`, `mergeAnchor`, `pinFamiliarCornerAhead`, `renameAnchor`, `hideAnchor`, `discoverRealNeighborhoodAnchors`, `completeKindredHabitPractice` (Sunroom), `awardStreetEncounterBonusGiftIfEligible`, `specialVisitorRule` |

### L5 — `StrollStore` (the optional "set out on a stroll" ritual)
| Owns state | `activeStroll`, `completedStrollSummary`, `persistedStrollDefaultsKey` |
|---|---|
| Depends on | Environment, Diary, Economy, Sunroom (`displayName(for:)` for the Live Activity), Street |
| Moves in | `startStrollSession`, `endStrollSession`, `gingerThermosFullRefundSteps`, `persistActiveStroll`, `restorePersistedStrollIfNeeded`, `beginLiveStrollStepStream` (its pedometer callback calls a facade closure `onLiveSteps`, because ingesting is a flow), `strollExtraPocketFindCap` → `extraPocketFindCap`; new `cancelActiveStroll()` (the silent teardown at the top of `resetAllGameData`); new `recordEncounter()` (the `sessionEncountersCount += 1` + route block) and `recordIngestion(_ result:, extraCurios:)` (the session-steps/coins/curios + Live Activity update block from `applyStepIngestionSideEffects`) |
| `reload()` | none |
| Shims | `activeStroll`, `completedStrollSummary` (**get + set**, because a view binds `$coordinator.completedStrollSummary`), `startStrollSession`, `endStrollSession`, `strollExtraPocketFindCap` |

### Facade — what stays on `GameCoordinator`
- **UI and navigation state:** `currentScreen`, `showOnboardingPaperSlip`, `showInteractiveTutorial`, `showAccessibleNearbyList`, `showFixtureDrawer`, `isSunroomPhotoMode`, `pendingOpenStartStrollSheet`, `latestFixtureReport`, `completeInteractiveTutorial`, `reopenInteractiveTutorial`, `tutorialCompletedDefaultsKey`, `handleDeepLink`.
- **Lifecycle and flows (§7):** `init`, `reloadAll`, `handleAppBecameActive`, `resetAllGameData`, `commitStreetEncounter`, `ingestSteps`, `ingestLiveStrollSteps`, `recordMobilityRollMovement`, `optInAndSyncPedometer`, `purchaseItem`, `graduateOffspringToCorner` (resolver), `nextGoalHint`, weather sync.
- **Environment shims** (used by views, `DiaryExportService`, `+Fixtures` and tests): `modelContext`, `locationService`, `pedometerService`, `currentSimulatedDate` (get + set), `isUsingSimulatedClock` (get + set), `currentLocalDateISO`, `activeWeather` (get + set), `hasManualWeatherOverride`, `setManualWeatherPreview(_:)`, `transientWhisper`, `showWhisper(_:)`, `indoorState`, `updateIndoorState`.
- **`+Fixtures.swift`** stays a facade extension. It's a test and debug harness that deliberately runs the flows end to end.
- `PetSpec.favoriteGreeting` / `favoriteGreetingHint` (currently at the bottom of `+Progression.swift`) move to `Models/PetCatalog.swift`'s neighbourhood as `Engine/PetSpec+Greeting.swift`. They're catalogue data, not coordinator state.

## 5. Forwarding shims

Shims are plain computed members. Observation still works: SwiftUI tracks the read of `street.anchors` inside the shim's getter, because `StreetStore` is itself `@Observable`.

```swift
// GameCoordinator+Shims.swift — generated per store PR, deleted in Phase 1.3 once no view uses them.
extension GameCoordinator {
    // StreetStore
    var anchors: [AnchorSiteRecord] { street.anchors }
    var visibleAnchors: [AnchorSiteRecord] { street.visibleAnchors }
    func distanceMeters(to anchor: AnchorSiteRecord) -> Double { street.distanceMeters(to: anchor) }
    @discardableResult func pinFamiliarCornerAhead(label: String? = nil) -> AnchorSiteRecord? {
        street.pinFamiliarCornerAhead(label: label)
    }

    // StrollStore: settable because a view binds $coordinator.completedStrollSummary
    var completedStrollSummary: CompletedStrollSummary? {
        get { stroll.completedStrollSummary }
        set { stroll.completedStrollSummary = newValue }
    }
}
```

Shim rules:
- Keep the **exact** name, labels, default arguments, `@discardableResult` and `async` of the original. Re-declare default arguments on the shim; they aren't inherited.
- A stored property that views or tests write (`coordinator.x = …` or `$coordinator.x`) gets a `get`/`set` shim. As of this writing, the ones that move are `activeWeather`, `currentSimulatedDate`, `isUsingSimulatedClock` (Environment), `newlyUnpackedCurio` (Economy), `activeQuietRevisit` (Street) and `completedStrollSummary` (Stroll, also `$`-bound). `ledger` can stay get-only because it's a reference (`coordinator.ledger.coinBalance = …` still works). Re-grep `coordinator\.[A-Za-z]+ = ` in `Views/`, `App/` and `PawprintDaysTests/` in every PR.
- Mark each shim block `// MARK: - Shims → <Store> (remove in 1.3)`.
- Tests may keep calling shims. New tests for a store call the store directly.

## 6. Shared persisted data: who may write what

The `WalletAndCurioLedger` row and its `indoorStateData` JSON blob are written by several features. Until a V3 schema splits them, each field has **one writing store**. Everything else reads.

| Ledger field(s) | Writer |
|---|---|
| `coinBalance`, `stepCarryRemainder`, `pocketFindStepProgress`, `totalAcceptedStepsAllTime`, `processedTxIDs`, `foragedCuriosData`, `stepIntervalsData`, `ownedGoodieIDs`, `ownedOutfitIDs`, `ownedRoomThemeIDs`, `pedometerOptIn`, `backgroundVisitsOptIn`, `mobilityRollModeEnabled`, `mobility*Carry*`, `pilotTap3MagicalDelivered` | Economy. Other stores go through `grant`/`charge`/`spend`. `pilotTap3MagicalDelivered` is written inside `AnchorRotationEngine` on Street's behalf, which is allowed because it's a pure engine call made from Street |
| `activeRoomThemeRaw`, `verandaUnlocked`, `gingerTeaActiveUntil` | Sunroom (`verandaUnlocked` and ginger tea are set as purchase side effects in the facade's `purchaseItem` flow, by calling Sunroom) |
| `activeOutingPackRaw`, `activeStrollChain*`, `lastNeighborhoodLat/Lon` | Street |

| `indoorState` sub-field | Writer |
|---|---|
| `dailyWishes`, `activeWalkQuest`, `completedWalkQuestCount`, `giftedCurioEntryIDs`, `claimedCurioSetWeatherCodes`, `discoveredFavoriteGesturePetIDs` | Progression |
| `hasPlacedDoorstepCorner`, `specialVisitorDates` | Street |
| everything else (errands, tea, origami, chime, postcard pin, window visitors, offspring, skits, coin-pacing counters) | Sunroom, except the coin-pacing counters, which Economy writes via `grantIndoorCoinIfAvailable` |

All blob writes go through the single `environment.updateIndoorState { … }`. Because everything is `@MainActor`, a read-modify-write can't interleave.

## 7. Facade flows (keep this exact order)

Write each flow as a facade method that calls stores in the order below. That order **is** the current behavior. Don't reorder in 1.2.

**`commitStreetEncounter(…)`**
1. `street.commitEncounter(…, strollContext: stroll.activeStroll.map { ($0.packedCharm, $0.companionPetID) })`: dedup, scene, bake, chain offer, encounter insert, bond update, anchor tap, diary day update, neighbourhood-loop stamp, `sunroom.resolveMentorshipsOnNewDay`, room solve. Returns `nil` or the existing log when it short-circuits, and the facade returns it immediately just like today.
2. `stroll.recordEncounter()`
3. `environment.commit()`
4. `progression.markDailyWishCompleted(.streetGreeting)`
5. `sunroom.nurtureAllGrowingOffspring(axis: .brave, bonusSteps: 0)`
6. `progression.applyGreetingPreferenceOutcome(…)` (with `isFirstGreetingWithPetToday` computed in step 1, so return it alongside the log)
7. If no chain was offered, there's no street companion, and the pet is invited home: `progression.offerWalkQuestIfAppropriate(petID:)`

**`ingestSteps` / `ingestLiveStrollSteps`** (shared private `applyStepIngestion(result:day:placeLabel:)`)
1. `let day = diary.todayDiaryRecord()`, then `economy.ingestInterval(…)` or `economy.ingestLiveDelta(…)` with `extraDailyCap: stroll.extraPocketFindCap`
2. `day.acceptedSteps += accepted`
3. if `accepted > 0`: `sunroom.advanceMentorshipSteps`, `progression.advanceWalkQuest`, `sunroom.nurtureAllGrowingOffspring(.brave, bonusSteps: accepted, countAsActivity: false)`
4. if strolling: `economy.applySachetBonusForage(…)` (sachet only, with a companion), then `stroll.recordIngestion(…)`
5. first regular curio → haptics, sound, `newlyUnpackedCurio`, whisper
6. `environment.commit()`

**`recordMobilityRollMovement`**: steps 1–3 of the above, **without** offspring nurture and without stroll bookkeeping (see §9), then commit only if `accepted > 0`.

**`optInAndSyncPedometer(silent:)`**: `economy.syncPedometerBuckets()` → `ingestSteps` per bucket → commit → whisper (unchanged text).

**`purchaseItem(_:txID:)`**: `economy.spend` → on success: veranda → `sunroom.ensureHomeSpotsExist(); sunroom.solveHomeRoomNow()`; picnic → `sunroom.createPicnicPortionSnapshot()`; ginger tea → `sunroom` sets `gingerTeaActiveUntil` and plays the clink → commit → whisper. On failure → whisper.

**`handleAppBecameActive(now:)`**: day rollover (`stroll.endStrollSession(autoArchived:)`, `diary.todayDiaryRecord()`, `sunroom.resolveMentorshipsOnNewDay`, `locationService.clearTrailForDay()`, `reloadAll()`), then weather: `environment.fetchLiveWeatherIfDue` → `diary.applyWeather`. Keep the remaining body as is.

**`resetAllGameData()`**: `stroll.cancelActiveStroll()` (stop live pedometer updates, end the Live Activity, clear `activeStroll`, persist; **not** `endStrollSession`, which would pay the thermos refund, write diary notes and save before everything is deleted) → delete all rows → `economy.resetLedger()` → clear defaults → `locationService.clearTrailForDay()` → re-seed in today's order (Sunroom residents → Street anchors → Sunroom home spots → Diary today) → `reloadAll()` → screen/tutorial/whisper.

**`reloadAll()`**: `street.reload()` (anchors first, then geofences, as today), `sunroom.reload()`, `diary.reload()`, then the widget snapshot sync exactly as today.

**`init`**: environment → economy (fetch or create the ledger) → diary → sunroom → progression → street → stroll → wire `environment.onCommit`/`onEvent`, `street` location closures and `stroll.onLiveSteps` → seed in the same order as `seedInitialWorldIfNeeded` (residents → anchors → home spots → today's diary day) → `reloadAll()` → `street.start()` → `stroll.restorePersistedStrollIfNeeded()` → tutorial flag.

## 8. PR order

Each PR: branch `codex/split-<n>-<store>`, based on the previous one once that has merged. Each must pass the merge gate (all tests green, zero new warnings, `xcodegen generate` committed, review by Claude Opus).

| PR | Scope | Why this order |
|---|---|---|
| **1** | `GameEnvironment` + `GameEvent` + `environment.commit()`. Replace every `try? modelContext.save(); reloadAll()` pair with `environment.commit()`, merge `mutateIndoorState`/`updateIndoorState`, move clock/weather/whisper and leave shims. No stores yet | Everything else depends on it; it's mechanical and touches the most lines, so it goes first |
| **2** | `DiaryStore` | Leaf; small; unlocks `diary.insert` for later PRs |
| **3** | `EconomyStore` (incl. the `ingest*` split into pure ledger calls + facade flows) | Leaf; carries the riskiest flow (`applyStepIngestionSideEffects`), so do it while Street and Stroll are still on the facade |
| **4** | `SunroomStore` (main-file members + `+IndoorAndRaising` minus daily wishes; `emit` for wishes) | Biggest move; depends on 2–3 |
| **5** | `ProgressionStore` (daily wishes + `+Progression` minus street parts; `nextGoalHint` → facade; `PetSpec+Greeting.swift`) | Needs Sunroom |
| **6** | `StreetStore` (incl. `commitStreetEncounter` split, location wiring, doorstep corner, special visitors) | Needs 2–5; second-riskiest flow |
| **7** | `StrollStore` (+ live-step closure; stroll pieces of the encounter and ingestion flows) | Last layer |
| **8** | Cleanup: delete the now-empty `+IndoorAndRaising.swift`/`+Progression.swift`, check that `GameCoordinator.swift` is ≤ ~400 lines (state, init, flows) | — |

Allowed test edits in 1.2: none, except (a) adding new store test files, and (b) none needed for tests that set a moved stored property (`currentSimulatedDate`, `isUsingSimulatedClock`, …), because the shim is settable (§5). **Don't edit existing assertions.**

## 9. Behavior quirks to preserve (fix later, in separate PRs)
- `recordMobilityRollMovement` doesn't nurture offspring and doesn't update an active stroll, unlike `ingestSteps`.
- `todayDiaryRecord()` inserts **and** calls `reloadAll()` when it creates the day, so it can reload in the middle of a flow. Keep it via `environment.commit()`.
- `awardStreetEncounterBonusGiftIfEligible` grants +1 coin on every call for bonded pets (its only caller, `SidewalkEncounterView`, decides when to call it). Keep it un-gated in the store.
- `syncLiveWeatherIfNeeded` sets `lastWeatherSyncUTC` before the fetch, so a failed fetch still throttles for 30 minutes.
- The widget snapshot in `reloadAll` reads `activeWeather` **before** any pending weather sync completes.

## 10. Test expectations

**Every PR**
- `xcodebuild test -scheme PawprintDays -destination 'platform=iOS Simulator,id=F839F388-C746-4C4E-9A82-AEB40A1ECC70'`: all existing tests green and unmodified (currently 48: 42 gameplay + 6 `SchemaMigrationTests`).
- Zero new compiler warnings (Swift 6 strict concurrency is on).
- `git grep -n "modelContext.save" PawprintDays/Engine/Stores` returns only `GameEnvironment.swift`.
- No file in `PawprintDays/Views/` changed. This is the "views don't break" proof.

**New per-store tests** (`PawprintDaysTests/Stores/<Name>StoreTests.swift`, built on an in-memory container helper shared via `PawprintDaysTests/Support/TestGame.swift`)
| Store | Minimum tests |
|---|---|
| Environment | `commit()` saves and invokes `onCommit` once; `emit` reaches `onEvent`; `updateIndoorState` round-trips through the ledger blob |
| Diary | `todayDiaryRecord` is idempotent per date; `erasePlaceDataForSingleDay` clears place data for that day only; `removeEncounter` removes exactly one log |
| Economy | `charge` refuses overdraft; `spend` is idempotent per `txID`; `grantIndoorCoinIfAvailable` respects `indoorCoinDailyLimits`; `ingestInterval` has no side effects outside the ledger |
| Sunroom | seeding creates the 6 residents + starter spots once; `planMentorship` → `advanceMentorshipSteps(2_500)` → `.demonstrated`; nesting/offspring nurture advances growth; an indoor activity emits `.dailyWishProgress` |
| Progression | `.dailyWishProgress` event marks the wish; `isFeatureUnlocked` thresholds (1 encounter / 2 / 3 invited); curio set claim pays once |
| Street | site-day dedup returns the existing log; picnic `strollContext` produces a secondary pet; doorstep corner placed once; a special visitor overrides the offer |
| Stroll | start charges the charm price and persists to `UserDefaults`; restore on another day auto-archives; ginger thermos refund 9 vs 2 at the 1,500-step boundary |
| Facade flows | one golden test per flow in §7 asserting the end state (coins, steps, wish flags, stroll counters) matches what the pre-split coordinator produced. Write these **in PR 1, before anything moves**, so every later PR is checked against them |

## 11. Notes for the executor
- Move code; don't rewrite it. Keep comments, including the zh-Hant ones, and every whisper string byte for byte.
- Don't change access control beyond what the move needs (`private` → `internal` on the store is fine).
- Swift 6: stores are `@MainActor`. Closures stored on the environment are `@MainActor` and capture `[weak self]`.
- If a member doesn't fit the tables above, stop and ask the lead in the PR description rather than inventing a new dependency edge.

## 12. Open questions for the lead
1. **Residents' home.** This design keeps `residents` in `SunroomStore` (per the plan). Street and Progression read them heavily, and that's why Sunroom sits at L2. If a seventh `CompanionStore` (residents + `displayName` only) at L1 is acceptable, Sunroom becomes a cleaner leaf. Recommendation: keep six for 1.2 and revisit after.
2. **V3 schema follow-up.** Splitting `indoorStateData` into per-feature rows (Progression vs Sunroom) would remove §6's shared-blob rule. Worth scheduling right after 1.2 lands, through `PawprintMigrationPlan`.
