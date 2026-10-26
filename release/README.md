# Release assets

Everything needed to fill App Store Connect. Regenerate the images with:

```bash
Scripts/render-assets.sh
```

## Screenshots

```
release/screenshots/
  6.1-inch/   01-today.png  02-history.png  03-day-editor.png  04-settings.png
  6.3-inch/   same four
  6.5-inch/   same four (older slot)
  6.9-inch/   same four
```

The upload slot in App Store Connect decides which set to use. The current
dialog lists:

| Slot | Size |
|---|---|
| iPhone 6.1-inch | 1179 × 2556 |
| iPhone 6.3-inch | 1206 × 2622 |
| iPhone 6.5-inch (older) | 1284 × 2778 |
| iPhone 6.9-inch | 1320 × 2868 |

Upload the four files from the folder matching the slot, in numeric order.
Files are flattened PNGs with no alpha channel. App Preview videos
(886 × 1920 / 1920 × 886) are optional and not included.

These are **interface renders** from `Design/screens/*.svg`, not simulator
captures. They follow the app's real layout, but Apple expects screenshots of
the running app — if you can capture the four screens on a 6.9-inch device or
simulator, use those instead. The SVGs are here so the set can be regenerated
or adjusted.

## Icon

`release/icon/AppIcon-1024.png` — the App Store icon is taken from the build's
asset catalog, so this copy is for records and marketing only.

## Product page header (optional)

```
release/header/
  header-21x9-3840x1646.png   21:9  (preferred)
  header-16x9-5244x2950.png   16:9  (also accepted as a 16:9 search result asset)
```

The header is the new **Asset Library** slot at the top of the product page
(iOS/iPadOS 27+). It is optional and does not replace screenshots.

- No transparency; both files are flattened PNGs.
- Apple does not publish crop-safe margins: keep the subject inside the central
  ~80%, because the outer 10% on each side may be cropped on some devices.
- One idea, readable in a second. No prices, rankings, awards or "Download"
  buttons — the store already provides those.
- A 5–30 second looping video is also accepted at 21:9; not included here.

## Social card

`release/social-card.png` — 1280 × 640. Use it as the GitHub repository's
**Settings → Social preview**, and as the site's Open Graph image (already
wired in `docs/index.html`).

## Metadata

`release/metadata/en-US/` contains one file per App Store Connect field:

| File | Field |
|---|---|
| `name.txt` | App name: **TimeTrackete** |
| `name-options.md` | Why the store name is TimeTrackete |
| `subtitle.txt` | Subtitle (30 chars max) |
| `promotional_text.txt` | Promotional text (170 chars max) |
| `description.txt` | Description |
| `keywords.txt` | Keywords (100 chars max) |
| `support_url.txt` | Support URL |
| `marketing_url.txt` | Marketing URL |
| `privacy_url.txt` | Privacy policy URL |
| `release_notes.txt` | What's New |
| `review_notes.txt` | App Review notes |
| `review-reply.md` | Full reply to a Guideline 2.1 information request |
| `screen-recording-script.md` | Shot list for the App Review screen recording |
| `what_to_test.txt` | TestFlight "What to Test" |
| `beta_description.txt` | TestFlight beta app description |
| `feedback_email.txt` | TestFlight feedback email |
| `category.txt` | Primary and secondary category |
| `age_rating.txt` | Age rating |
| `copyright.txt` | Copyright line |

Uploading and signing are covered in [`../APPSTORE.md`](../APPSTORE.md).
