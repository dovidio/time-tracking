# Release assets

Everything needed to fill App Store Connect. Regenerate the images with:

```bash
Scripts/render-assets.sh
```

## Screenshots

```
release/screenshots/
  6.9-inch/   01-today.png  02-history.png  03-day-editor.png  04-settings.png
  6.5-inch/   same four, optional
```

- **6.9-inch** is 1320 × 2868 and is the set App Store Connect requires.
- **6.5-inch** is 1284 × 2778 and is optional once the 6.9-inch set exists.
- Upload in numeric order. Files are flattened PNGs with no alpha channel.

These are **interface renders** from `Design/screens/*.svg`, not simulator
captures. They follow the app's real layout, but Apple expects screenshots of
the running app — if you can capture the four screens on a 6.9-inch device or
simulator, use those instead. The SVGs are here so the set can be regenerated
or adjusted.

## Icon

`release/icon/AppIcon-1024.png` — the App Store icon is taken from the build's
asset catalog, so this copy is for records and marketing only.

## Social card

`release/social-card.png` — 1280 × 640. Use it as the GitHub repository's
**Settings → Social preview**, and as the site's Open Graph image (already
wired in `docs/index.html`).

## Metadata

`release/metadata/en-US/` contains one file per App Store Connect field:

| File | Field |
|---|---|
| `name.txt` | App name (proposal: **Badge Hours**) |
| `name-options.md` | Alternatives, since `TimeTracker` is taken |
| `subtitle.txt` | Subtitle (30 chars max) |
| `promotional_text.txt` | Promotional text (170 chars max) |
| `description.txt` | Description |
| `keywords.txt` | Keywords (100 chars max) |
| `support_url.txt` | Support URL |
| `marketing_url.txt` | Marketing URL |
| `privacy_url.txt` | Privacy policy URL |
| `release_notes.txt` | What's New |
| `review_notes.txt` | App Review notes |
| `what_to_test.txt` | TestFlight "What to Test" |
| `beta_description.txt` | TestFlight beta app description |
| `feedback_email.txt` | TestFlight feedback email |
| `category.txt` | Primary and secondary category |
| `age_rating.txt` | Age rating |
| `copyright.txt` | Copyright line |

Uploading and signing are covered in [`../APPSTORE.md`](../APPSTORE.md).
