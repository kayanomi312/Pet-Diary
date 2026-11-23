# Pawprint Days (足印日記) — Improvement Plan & Model Assignments

_Written 2026-11-23. Baseline: 26 commits on `main`, ~24k lines Swift, 42/42 unit tests passing (including uncommitted progression work)._

## 1. Where the game stands

**Core loop:** walk in real life → pedometer earns 步數幣 → meet mystical companions at real street corners (75 m geofence) → greet with gestures → invite them home → care for them in the 2.5D Sunroom → everything lands in the hardcover diary.

**Strengths**
- Coherent, distinctive art direction (Japanese/Taiwanese watercolor stationery, 560 HEIC cel frames, Metal paper-grain shader).
- Broad feature surface: strolls + Live Activity, widgets, App Intents, weather sync, MapKit anchor discovery, haptics (AHAP), procedural audio, PDF/backup diary export, mentorship & cross-species raising.
- Good resilience: crash-safe SwiftData container, Swift 6 concurrency fixes, zero-warning builds.

**Gaps found in the audit**

| Area | Finding | Risk |
|---|---|---|
| Source control | 16 modified + 2 new files uncommitted (progression layer, balance tests) | Work loss |
| Architecture | `GameCoordinator` is 1,626 lines (+3 extensions ≈ 3k), one `@Observable` god-object; views are 700–1,300 lines each | Every model will collide in the same files |
| Data | Only `PawprintSchemaV2`, **no `SchemaMigrationPlan`**; on failure the store is archived & reset. A "clean release reset" wipes data once | Player diaries lost on any future model change |
| Retention | No local notifications, no daily/weekly goals surfaced outside the street hint, no seasonal events | Weak day-2/day-7 return |
| Content | 6 companions, 9 furniture goodies, ~4 outfits | Thin after week 1 |
| Localization | All strings hard-coded zh-Hant, no String Catalog | Locks out EN/JA markets |
| Accessibility | ~45 accessibility modifiers in total; Sunroom/Encounter mostly unlabeled; Dynamic Type untested | App Review / reach |
| Audio | Fully procedural (no recorded assets) | Charm ceiling |
| Testing/CI | Unit tests only; no UI tests, no snapshot tests, no CI | Regressions from parallel agents |
| Monetization / sync | No StoreKit, no CloudKit/iCloud sync | Business + "I lost my diary" risk |
| Ops | No analytics/crash reporting, no TestFlight pipeline | Flying blind post-launch |

## 2. Model roles

Pick each model for what it's best at, and give each its own files so they don't collide.

| Model | Provider | Role | Why |
|---|---|---|---|
| **Claude Opus 5.5** | Claude (this thread) | **Lead / architect / integrator.** Owns design decisions, the refactor's seams, SwiftData migrations, gameplay systems & balance, zh-Hant narrative voice, and the final review + merge of every branch | Most context on the codebase already; strongest at cross-cutting design and long-form writing in the game's voice |
| **Claude Sonnet 5.5** | Claude | Mid-size feature implementation under Opus specs (notifications, events) | Cheap, fast, same conventions |
| **Codex — GPT-6.2 Sol** (high effort) | Codex | **Engineering workhorse.** Mechanical refactors, test expansion, CI, String Catalog extraction, Swift 6 concurrency audit, performance work | Strong at precise, test-driven, multi-file code changes and terminal-heavy verification |
| **Antigravity — Gemini 4 Hydrogen** | Antigravity | **Visual / UX / device QA**, plus the **second-opinion code reviewer** for Claude-authored branches. Simulator walkthroughs with screenshots, UI consistency audit, accessibility audit, App Store screenshots & listing, competitor research | Strongest multimodal reading of screenshots + browser tooling; a different model family catches different bugs (keeps Codex usage for implementation, since the ChatGPT Plus quota is limited) |
| **Antigravity — Gemini 3.8 Flash** | Antigravity | Bulk/cheap tasks: translation first drafts (EN/JA), string QA, asset inventory | Fast and cheap for high-volume text |

### Collision rules (important)
1. **Every delegate works in its own git worktree** on a branch named `<model>/<task>` (e.g. `codex/ci-pipeline`). Nobody commits to `main` except the lead.
2. **File ownership per phase** (table in each phase below). If a task must touch a file someone else owns, it goes through the lead.
3. **One simulator** (iPhone 18 Pro `F839F388…`, iOS 27.2). Only one agent runs UI/device work at a time — Antigravity owns it during QA windows; Codex/Claude use `xcodebuild test` (unit tests only) in between. Don't create new simulators.
4. **Merge gate:** `xcodebuild test` green + zero new warnings + a review from a *different* model family than the author.

## 3. Phased roadmap

### Phase 0 — Stabilize (day 1) · blocks everything else
| # | Task | Owner | Done when |
|---|---|---|---|
| 0.1 | Review & commit the uncommitted progression layer (`GameCoordinator+Progression.swift`, `GameplayBalanceTests.swift`, 16 modified files) in logical commits | Claude Opus | `git status` clean, 42 tests green |
| 0.2 | Add `SchemaMigrationPlan` (V2 → V3 skeleton) + a migration test that opens a V2 fixture store; remove/guard the one-time "clean release reset" before any public build | Claude Opus | Test opens a V2 store with data intact |
| 0.3 | CI: GitHub Actions (macOS runner) running build + unit tests on every PR; `xcodegen generate` check so `project.yml` and `.pbxproj` never drift | Codex Sol | Green check on a test PR |
| 0.4 | Baseline QA pass: run every screen on the simulator, screenshot each, log visual bugs/janky flows to `docs/qa/baseline.md` | Gemini Hydrogen | Report with screenshots, ranked issues |

### Phase 1 — Architecture so three models can work in parallel (days 2–5)
| # | Task | Owner | Files owned |
|---|---|---|---|
| 1.1 | Design the split: `GameCoordinator` becomes a thin facade over feature stores — `StreetStore` (anchors, encounters, geofence), `StrollStore`, `SunroomStore` (home spots, residents, care), `EconomyStore` (ledger, shop, curios), `DiaryStore`, `ProgressionStore`. Write the interface doc + migration order | Claude Opus | `docs/architecture.md` |
| 1.2 | Execute the split one store per PR, keeping the old API as forwarding shims so views don't break; add unit tests per store | Codex Sol | `Engine/**` |
| 1.3 | Break the 1,000+ line views (`Sunroom25DStage`, `TactileCareView`, `HardcoverSketchbookView`, `StreetOverworldView`) into subviews; no behavior change | Codex Sol (after 1.2) | `Views/**` |
| 1.4 | Snapshot tests for the 6 main screens + onboarding (swift-snapshot-testing), seeded with deterministic fixtures | Codex Sol | `PawprintDaysTests/Snapshots/**` |
| 1.5 | Review each 1.2/1.3 PR | Claude Opus (Gemini Hydrogen reviews any Opus-authored PRs) | — |

### Phase 2 — Retention & core game feel (weeks 2–3)
| # | Task | Owner |
|---|---|---|
| 2.1 | **Daily rhythm:** "today's three little things" (walk X steps, greet a favorite gesture, care for one companion) with a small diary stamp reward; weekly "stamp card" | Opus designs + balance tests → Sonnet implements |
| 2.2 | **Local notifications** (opt-in, gentle): companion waiting at a corner, stroll recap, mentorship ready, evening diary reminder; respect quiet hours | Sonnet |
| 2.3 | **Seasonal & calendar events** using the existing `SeasonalRoomTheme`: Mid-Autumn, Lunar New Year, plum-rain season, Qixi; event visitors via the special-visitor system | Opus (content + narrative) + Sonnet (plumbing) |
| 2.4 | **Content expansion:** +4 companions (2 cat, 2 hound line), +10 goodies, +8 outfits, more curio sets. Opus writes specs/lore; art produced via the existing frame pipeline | Opus specs, Gemini Hydrogen art-direction review of each new frame set |
| 2.5 | **Onboarding funnel:** measure the "first companion met within 10 min" moment; tune doorstep-corner distance, tutorial length; ensure location-denied players still have a full loop (indoor-only path) | Gemini Hydrogen (device walkthrough + UX recs) → Opus decides → Sonnet implements |
| 2.6 | **Economy balance sim:** script that simulates 30 days for light/medium/heavy walkers and plots coin inflow vs sinks | Codex Sol (sim) → Opus (tuning) |
| 2.7 | **Audio upgrade:** keep procedural ambience, add a small recorded set (purrs, footsteps, page turns, kalimba motifs) with a mixer; per-category volume | Codex Sol (engine) + Gemini (sourcing/curation list) |

### Phase 3 — Reach & polish (week 4)
| # | Task | Owner |
|---|---|---|
| 3.1 | Migrate all strings to a String Catalog (`Localizable.xcstrings`), zh-Hant as source | Codex Sol |
| 3.2 | EN + JA translations (first draft) | Gemini Flash |
| 3.3 | Translation review for tone (cozy, storybook) + pet names/lore consistency | Claude Opus (EN), Gemini Hydrogen (JA) |
| 3.4 | Accessibility: VoiceOver labels/actions for every interactive element (Sunroom pets, stations, encounter gestures), Dynamic Type to XXL, Reduce Motion fallbacks for parallax/roaming, Reduce Transparency | Codex Sol implements, Gemini Hydrogen audits on device with VoiceOver |
| 3.5 | Performance: Instruments pass on Sunroom (60 fps target, memory of HEIC frame cache), battery cost of geofence + pedometer during strolls | Codex Sol |
| 3.6 | iCloud sync of the diary (CloudKit-backed SwiftData) or at minimum automatic iCloud Drive backup | Opus designs (conflict model) → Codex implements |

### Phase 4 — Ship (week 5+)
| # | Task | Owner |
|---|---|---|
| 4.1 | Privacy manifest (`PrivacyInfo.xcprivacy`), App Privacy labels (location, motion — all on-device) | Claude Opus |
| 4.2 | Crash/metrics: MetricKit + an opt-in, privacy-preserving event log (no third-party SDK) | Codex Sol |
| 4.3 | Monetization (decision needed — see §5): e.g. one-time "Supporter" unlock with cosmetic furniture/outfits via StoreKit 2; never gate walking/companions | Opus designs, Codex implements |
| 4.4 | TestFlight pipeline (fastlane or Xcode Cloud), version bump to 1.0 | Codex Sol |
| 4.5 | App Store screenshots (zh-Hant/EN/JA), preview video, listing copy, competitor positioning | Gemini Hydrogen (visual + research), Opus (copy) |
| 4.6 | Final full-device QA run + release checklist | Gemini Hydrogen, signed off by Opus |

## 4. How to run it in T3 Code

- **This thread (Opus) is the hub.** Kick off Phase 0 here; when 0.1–0.2 land, Opus delegates 0.3 to Codex and 0.4 to Antigravity in parallel (each in a worktree).
- Each delegate brief should include: the task row above, owned files, the simulator rule, the merge gate, and "report: branch, head SHA, test result."
- Cross-family review is mandatory: Gemini Hydrogen reviews Claude branches, Claude Opus reviews Codex/Gemini branches. Codex is used for implementation only, to save the Plus quota.
- Keep this file as the living checklist — tick items as branches merge.

## 5. Decisions needed from you

1. **Monetization:** free, paid upfront, or free + one-time cosmetic unlock?
2. **Languages:** is EN + JA the right first expansion, or another market?
3. **Art for new companions:** keep the current frame pipeline (and who makes the art), or pause content expansion until an artist is involved?
4. **iCloud sync** in v1.0, or post-launch?
5. **Data reset:** is any existing player data (TestFlight testers, your own device) worth preserving through the V3 migration?
