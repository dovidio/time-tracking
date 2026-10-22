# Shipping to the App Store

A checklist for putting TimeTracker on the App Store. Nothing here is code —
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

**`TimeTracker` is already taken on the App Store** (by ExhibitForce). The name
in App Store Connect must be unique, but the name on the home screen does not:
`CFBundleDisplayName` can stay `TimeTracker`.

Pick a unique store name, for example:

- `Badge Hours`
- `Punch Ledger`
- `Hours Ledger`
- `Badge Hours: Time Ledger`

App Store Connect will tell you immediately if a name is free when you create the
app record; it also reserves the name for 90 days once you do.

## 2. Already done in this repo

- [x] Privacy manifest (`TimeTracker/PrivacyInfo.xcprivacy`): no tracking, no
      collected data, UserDefaults required-reason `CA92.1`.
- [x] Export compliance key in `Info.plist`:
      `ITSAppUsesNonExemptEncryption = false` (no encryption).
- [x] 1024×1024 app icon, light/dark/tinted.
- [x] Privacy policy (`PRIVACY.md`).
- [x] App is iPhone-only, portrait, iOS 17+, no login, no third-party SDKs.
- [x] Engine covered by tests (`cd TimeCore && swift test`, 36 tests).

## 3. Create the app record

App Store Connect → **My Apps → + → New App**:

| Field | Value |
|---|---|
| Platform | iOS |
| Name | your unique name (see above) |
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
  `https://github.com/dovidio/time-tracking/blob/main/PRIVACY.md`
  (a GitHub Pages URL is nicer if you want one later)
- **Support URL**: `https://github.com/dovidio/time-tracking/issues`
- **Copyright**: `2026 Umberto D'Ovidio`

## 5. App privacy

Answer **No data collected**. The app stores everything locally and makes no
network requests. No tracking. No third-party SDKs, so no SDK manifests.

## 6. Screenshots

Apple currently requires the **6.9-inch** set (1320 × 2868). Smaller sizes are
optional once the 6.9-inch set exists; App Store Connect will show the exact
slots.

Take 4 screenshots on an iPhone 16 Pro Max simulator (or a 6.9-inch device):

1. **Today** with a completed day and a visible *Leave at* time.
2. **History** showing a week of balances.
3. **Day editor** showing a correction.
4. **Settings → Lunch / Contract** showing the configuration.

Ideas for captions (add them in the image, not required by Apple):
*"One tap, four stamps, one honest balance."* ·
*"Know the exact minute you can leave."* ·
*"Fix a forgotten tap without lying to yourself."*

## 7. Version information

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

## 8. Build and upload

1. Bump `CURRENT_PROJECT_VERSION` in `project.yml` (e.g. `"2"`), then
   `xcodegen generate`.
2. In Xcode select **Any iOS Device (arm64)** → **Product → Archive**.
3. Organizer → **Distribute App → App Store Connect → Upload**.
4. Wait for the build to appear in App Store Connect (usually 5–15 minutes).

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
- **Name.** `TimeTracker` is taken; use a unique store name.
- **Screenshots.** Without the iOS simulator runtime you cannot produce the
  required 6.9-inch set. Install it from Xcode → Settings → Components.
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
