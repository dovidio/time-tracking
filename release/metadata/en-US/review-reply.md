# Reply to App Review — Guideline 2.1

Paste this into the Resolution Center reply **and** into App Store Connect →
App Review Information → **Notes**. Replace `[PASTE LINK]` with the recording URL.

---

Hello,

Thank you for the review. TimeTrackete is a local, single-user time ledger. It
has **no account creation, login or account deletion**, **no user-generated
content** (and therefore no reporting or blocking mechanisms), **no paid content
or in-app purchases**, and **no network access**.

**1. Screen recording**

[PASTE LINK]

Recorded on a physical iPhone 14 running the latest iOS, starting from the Home
Screen with the app launching. It shows the complete flow: cold launch, stamping
in, lunch out, back in, stamping out, the running balance and the "Leave at"
time, History, correcting a day, Settings, and the optional "Stamp" Shortcut used
for Back Tap. There are no account, UGC or paid-content flows to demonstrate.

**2. Purpose and target audience**

The app is for employees whose workplace records time with a badge terminal but
does not give them a way to see their balance. It is a **personal ledger**, not a
connection to the employer's system or hardware.

- **Problem:** after a week or a month you cannot tell whether you are over or
  under your contracted hours, or when you can leave today.
- **Value:** a running daily, weekly and monthly balance, an exact "leave at"
  time while you are working, correct handling of lunch (a standard deduction or
  the real break), and the ability to correct a forgotten stamp without losing
  the original record.
- **Audience:** individual employees and anyone who wants a private, local record
  of hours and overtime.

**3. Setup and main features**

No login, credentials or sample files are required.

- Open the app. **Today** is the main screen.
- **Settings:** weekly hours, working days, optional standard lunch (for example
  60 minutes), rounding, and holidays.
- **Record a stamp** with the large button. The toggle follows the terminal:
  1 = in, 2 = out for lunch, 3 = back in, 4 = out. The label changes, and the card
  updates worked time, target and "Leave at".
- **Pencil** edits a day: add, remove or retime a stamp, add a note, Save.
  "Revert to recorded stamps" removes the correction.
- **History** shows week and month balances and each day; tap a day for stamps,
  timeline and any anomalies.
- **Optional shortcut:** Shortcuts → new shortcut → TimeTrackete → **Stamp**;
  assign it to Back Tap (Settings → Accessibility → Touch → Back Tap), or use
  Siri: "Stamp with TimeTrackete".
- **Export:** Settings → Export taps.log. The same file is visible in Files → On
  My iPhone → TimeTrackete.

**4. External services, tools or platforms**

None. The app uses only Apple system frameworks — SwiftUI, Foundation, and App
Intents for the optional Siri/Shortcuts action. There is no data provider,
authentication service, payment processor, analytics, advertising, AI service,
or third-party SDK. All data is stored locally in a plain-text file and the app
makes no network requests.

**5. Regional differences**

None. Every feature is available in all regions. The interface is English; dates
and times follow the device's locale and time zone. Holidays are entered by the
user, so there is no region-specific content.

**6. Regulated industry or protected third-party material**

Not applicable. The app is a personal time ledger. It does not provide a
regulated service, does not connect to employer or badge systems, and contains no
third-party content. The icon and interface are original work; the source code is
MIT-licensed.

Please let me know if you need any further information.

---

## Recording instructions

- Record on the **physical iPhone**, latest iOS, from the **Home Screen**.
- Control Center → Screen Recording. Do not start from Xcode or a link.
- Keep it under ~3 minutes and do not edit out the flow.
- Upload it unlisted (Google Drive "anyone with the link", YouTube unlisted, or
  Dropbox) and put that URL in both places above.

Shot list: `screen-recording-script.md`.
