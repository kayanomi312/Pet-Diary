# App Privacy — App Store Connect answers & manifest summary

_Pawprint Days (足印日記) · written 2026-11-23 · matches `PawprintDays/Resources/PrivacyInfo.xcprivacy`_

## One-line position

Precise location, steps, the diary and companions are processed **on the device only**. There is no account, no server, no analytics SDK, no ads and no third-party code. Nothing is used to track people.

**One exception — live weather.** On a real device `WeatherSyncService.fetchLiveWeather` sends latitude/longitude **rounded to 0.01° (~1.1 km)** to `api.open-meteo.com` (at most once per 30 min; the simulator and offline path never call it). That is *Coarse Location* leaving the device to a third-party service, so it **must be declared** as collected. Open-Meteo also sees the request IP address as any web server does; no identifier is sent. Decision (2026-11-23): keep Open-Meteo and declare it; real weather stays always on with no settings toggle. WeatherKit is a possible post-launch upgrade, not needed for 1.0.

## Answers for App Store Connect → App Privacy

| Question | Answer |
|---|---|
| Do you or your third-party partners collect data from this app? | **Yes** — Coarse Location only, because of the Open-Meteo weather request. (Precise Location and Fitness are processed on device only, which Apple does not count as "collected"; we still list them in the manifest for transparency.) |
| Do you use data for tracking? | **No** |

Rows to enter in App Store Connect (consistent with the manifest):

| Data type | Collected | Linked to user | Used for tracking | Purpose |
|---|---|---|---|---|
| Location → **Coarse Location** | Yes (sent to Open-Meteo) | No | No | App Functionality |
| Location → **Precise Location** | On device only — optional to declare | No | No | App Functionality |
| Health & Fitness → **Fitness** (pedometer step counts / motion) | On device only — optional to declare | No | No | App Functionality |

No other data types (contact info, identifiers, usage data, diagnostics, purchases, etc.) are collected.

## Privacy manifest (`PrivacyInfo.xcprivacy`)

Two manifests, both with `NSPrivacyTracking = false` and no tracking domains:

| File | Collected data types | Required-reason APIs |
|---|---|---|
| `PawprintDays/Resources/PrivacyInfo.xcprivacy` (app) | CoarseLocation, PreciseLocation, Fitness — not linked, not tracking, purpose AppFunctionality | UserDefaults: `CA92.1` (app's own settings/state), `1C8F.1` (App Group `group.com.pawprintdays.shared` shared with the widget) |
| `PawprintDaysWidgets/PrivacyInfo.xcprivacy` (widget extension) | none | UserDefaults: `1C8F.1` (reads the shared App Group) |

### Required-reason API audit (grep of the source, 2026-11-23)

| API category | Used? | Where |
|---|---|---|
| UserDefaults | **Yes** | tutorial flag, active stroll session, sunroom spots, sound/music/haptics toggles, shared widget state |
| File timestamp (`creationDate`, `modificationDate`, `stat`…) | No | — (only `fileExists`, `removeItem`, `moveItem`, temp-directory writes) |
| System boot time (`systemUptime`, `mach_absolute_time`) | No | — |
| Disk space (`volumeAvailableCapacity…`, `statfs`) | No | — |
| Active keyboard list | No | — |

Re-run the audit (`grep -rnE "UserDefaults|creationDate|modificationDate|systemUptime|mach_absolute_time|volumeAvailable|statfs"`) when adding SDKs or new storage code. Local notifications (`UNUserNotificationCenter`) are not a required-reason API and need no manifest entry.

## Permission strings (Info.plist, already present)

- `NSLocationWhenInUseUsageDescription` — precise position for 75 m street-corner encounters and watercolor stroll trail; stays on device. The string also discloses that a ~1 km blurred location is sent for live weather (real weather is always on by design — no in-app toggle; offline/failed requests fall back to local time-of-day lighting).
- `NSLocationAlwaysAndWhenInUseUsageDescription` — only if the player opts into remembering long stops.
- `NSMotionUsageDescription` — pedometer → step coins; no health data uploaded.
- Local notifications (opt-in, added by task 2.2) need no usage-description string; the system permission prompt is requested at runtime.

## Privacy policy

Draft policy text (zh-Hant + EN, including the Open-Meteo disclosure) is in `docs/privacy-policy.md`; it is published by `.github/workflows/privacy-pages.yml` to `https://kayanomi312.github.io/Pet-Diary/privacy/` (see "Enabling hosting" in that workflow's header notes in `docs/privacy-policy.md`). The build refuses to publish if a support-email placeholder ever reappears.

### Notes

Apple requires a privacy policy URL. Suggested content: the app stores everything locally (SwiftData + UserDefaults), exports (PDF/backup) are created only when the player taps export and are shared through the system share sheet, nothing is sent to us. Live weather sends location rounded to ~1.1 km to Open-Meteo (open-meteo.com) and nothing else; MapKit lookups go to Apple under Apple's privacy terms. Disclose Open-Meteo as a third-party service in the policy.

### Enabling hosting (one-time)

1. ~~Replace the support-email placeholder~~ — done (`pawprintdays@proton.me`).
2. Merge to `main` and push (the remote has no branches yet).
3. Repo → Settings → Pages → Source: **GitHub Actions** (or `gh api -X POST repos/kayanomi312/Pet-Diary/pages -f build_type=workflow`).
4. Run the "Publish privacy policy" workflow (or push a change to the policy). Enter `https://kayanomi312.github.io/Pet-Diary/privacy/` as the Privacy Policy URL in App Store Connect.

The workflow only publishes the rendered policy page — not the rest of `docs/`.
