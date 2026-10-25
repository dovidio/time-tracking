# Shipping to the App Store

A checklist for putting TimeTrackete on the App Store. Nothing here is code —
it is account setup, metadata, screenshots, and review.

## 0. Before you start

- [ ] **Apple Developer Program** membership, $99/year. A free Apple ID cannot
      distribute to the App Store.
- [ ] App Store Connect access with the Admin or App Manager role.
- [ ] Xcode with the **iOS platform installed** (Settings → Components), because
      you need a 6.9-inch simulator or device for screenshots.
- [ ] App Store Connect → **Agreements, Tax, and Banking**: accept the Paid Apps
      agreement (free apps still need the account in good standing).

## 1. The name

The App Store name is **TimeTrackete**. `TimeTracker` was already registered by
ExhibitForce, so the listing uses the unique spelling. The home-screen name
matches (`CFBundleDisplayName`).

The bundle ID, the Xcode project and the repository keep the internal name
`TimeTracker` / `time-tracking`. Those are not user-visible, and changing the
bundle ID would create a new app container and orphan the existing log on the
phone.

## 2. Already done in this repo

- [x] Privacy manifest (`TimeTracker/PrivacyInfo.xcprivacy`): no tracking, no
      collected data, UserDefaults required-reason `CA92.1`.
- [x] Export compliance key in `Info.plist`:
      `ITSAppUsesNonExemptEncryption = false` (no encryption).
- [x] 1024×1024 app icon, light/dark/tinted.
- [x] Privacy policy (`PRIVACY.md`).
- [x] App is iPhone-only, portrait, iOS 17+, no login, no third-party SDKs.
- [x] Engine covered by tests (`cd TimeCore && swift test`, 36 tests).
- [x] Release assets in [`release/`](release/): screenshots, icon, social card,
      and paste-ready metadata (`release/metadata/en-US/`).

## 3. Create the app record

App Store Connect → **My Apps → + → New App**:

| Field | Value |
|---|---|
| Platform | iOS |
| Name | TimeTrackete |
| Primary language | English |
| Bundle ID | `com.umbertodovidio.TimeTracker` (must match the app) |
| SKU | `timetracker-ios` (any private string) |
| User access | Full Access |

## 4. App information

- **Subtitle** (30 chars): `Know when you can leave.`
- **Category**: Productivity (secondary: Utilities)
- **Content rights**: does not contain third-party content
- **Age rating**: 4+
- **Privacy policy URL**:
  `https://dovidio.github.io/time-tracking/privacy.html`
  (a GitHub Pages URL is nicer if you want one later)
- **Support URL**: `https://github.com/dovidio/time-tracking/issues`
- **Copyright**: `2026 Umberto D'Ovidio`

## 5. App privacy

Answer **No data collected**. The app stores everything locally and makes no
network requests. No tracking. No third-party SDKs, so no SDK manifests.

## 6. Screenshots

The upload slot decides the size; App Store Connect currently lists:

| Slot | Size |
|---|---|
| iPhone 6.1-inch | 1179 × 2556 |
| iPhone 6.3-inch | 1206 × 2622 |
| iPhone 6.5-inch (older) | 1284 × 2778 |
| iPhone 6.9-inch | 1320 × 2868 |

Prepared in `release/screenshots/`, four images per slot:

1. `01-today.png` — worked time, progress ring, leave time.
2. `02-history.png` — week and month balances.
3. `03-day-editor.png` — correcting a day.
4. `04-settings.png` — contract, rounding, lunch.

Upload the four from the folder that matches the slot, in numeric order. These
are **interface renders** from `Design/screens/`, not simulator captures. They
follow the app's layout, but Apple wants screenshots of the running app — if you
can capture the four screens on the real device, use those instead.

App Preview videos (886 × 1920 / 1920 × 886) are optional and not included.

## 6b. Product page header (optional)

A new **Asset Library** slot, shown at the top of the product page on
iOS/iPadOS 27 and later. It is optional and does not replace screenshots.

App Store Connect accepts:

| Ratio | Size | Format |
|---|---|---|
| 21:9 | 3840 × 1646 | PNG, JPEG |
| 16:9 | 5244 × 2950 | PNG |

Prepared in `release/header/`:

- `header-21x9-3840x1646.png` — preferred
- `header-16x9-5244x2950.png` — also accepted for the 16:9 search result slot

No transparency. Keep the subject inside the central ~80%; the outer 10% may be
cropped on some devices. A 5–30 s looping video is allowed at 21:9 but not
included. One idea, readable at a glance; no prices, rankings or download
buttons in the art.

## 7. Version information

All strings are in `release/metadata/en-US/`; paste each file into the matching
App Store Connect field.

**Description** (draft — keep it factual, no employer or vendor names):

> A private hours ledger for people whose badge terminal records time but never
> shows them a balance.
>
> One tap logs a stamp. The app mirrors the terminal's in/out toggle, so four
> taps become: in, lunch out, back in, out. It then calculates worked time, your
> daily target, the week and month balance, and the time you can leave.
>
> • One-tap recording, from the app or a Back Tap Shortcut
> • Automatic in/out/lunch handling from the order of your stamps
> • Optional standard lunch, with real breaks taking precedence
> • Week and month balances, overtime and shortfall at a glance
> • Manual day corrections, with the original taps kept in the log
> • Everything stored locally in a plain text file you can export
>
> No account, no ads, no analytics, no network.

**Keywords** (≤ 100 chars):
`time tracking,work hours,timesheet,overtime,balance,shortcut,punch clock,badge`

**Promotional text** (≤ 170 chars):
`A local hours ledger that mirrors your badge terminal's toggle and tells you
the one thing it never does: when you can leave.`

**What's New**: `First release.`

## 8. Signing, build and upload

1. **Create an Apple Distribution certificate**: Xcode → Settings → Accounts →
   select your team → **Manage Certificates… → + → Apple Distribution**.
   Without it, archiving for the App Store fails.
2. Bump `CURRENT_PROJECT_VERSION` in `project.yml` (e.g. `"2"`), then
   `xcodegen generate`.
3. Build the IPA with the script:

   ```bash
   TEAM_ID=XXXXXXXXXX Scripts/archive.sh
   ```

   It archives with `-allowProvisioningUpdates` and exports to `build/export/`.
4. Upload with **Xcode → Window → Organizer → Distribute App → App Store
   Connect → Upload**, or with an App Store Connect API key
   (Users and Access → Integrations):

   ```bash
   xcrun altool --upload-app -f build/export/TimeTracker.ipa -t ios \
     --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
   ```

5. Wait for the build to appear in App Store Connect (usually 5–15 minutes).

## 9. TestFlight first

Create an **Internal Testing** group, add yourself, install the build through
TestFlight, and use it for a day. This catches signing and launch problems
before review sees them.

## 10. Submit for review

On the version page: select the build, confirm the metadata, and add **App
Review Notes**:

> No account or login. Tap the large button to record a stamp; tap again to
> toggle out. The pencil button edits a day. Settings configures weekly hours,
> working days and the standard lunch.
>
> The app is an independent personal ledger. It does not connect to any employer
> system or badge hardware. The "Stamp" App Intent can be added to a Shortcut
> for Back Tap.

## 11. Risks worth knowing

- **Guideline 4.2 (minimum functionality).** This is a focused utility, and
  reviewers sometimes push back on simple time trackers. The distinct angle —
  mirroring a badge terminal's toggle, leave-at projection and editable ledger —
  helps. If it is rejected, adding a **Lock Screen / Home Screen widget** is the
  strongest answer, and it is the natural next feature anyway.
- **Name.** The store name is `TimeTrackete`, because `TimeTracker` is taken; the bundle ID and project name stay unchanged.
- **Screenshots.** The prepared set is interface renders. Real captures from a
  6.9-inch device or simulator are preferred; install the iOS runtime from
  Xcode → Settings → Components if you need one.
- **Free app, no IAP.** Nothing to configure under In-App Purchases.

## 12. Final checklist

- [ ] Paid account and agreements accepted
- [ ] Unique app name reserved
- [ ] App record created with the right bundle ID
- [ ] Privacy policy URL reachable
- [ ] App privacy: no data collected
- [ ] 6.9-inch screenshots uploaded
- [ ] Build uploaded and processed
- [ ] TestFlight build tested on a device
- [ ] Review notes added
- [ ] Submitted
