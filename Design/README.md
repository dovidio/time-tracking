# App icon

The icon is a clock whose outer ring is the worked-time progress ring from the
Today screen: a translucent track, an emerald arc for the hours accumulated, and
white hands at ten past ten.

Sources are plain SVG so they can be edited and re-rendered:

- `AppIcon.svg` — default appearance
- `AppIcon-dark.svg` — dark appearance
- `AppIcon-tinted.svg` — tinted appearance (grayscale; iOS applies the tint)

Regenerate the PNGs after editing:

```bash
for name in AppIcon AppIcon-dark AppIcon-tinted; do
  rsvg-convert -w 1024 -h 1024 "Design/$name.svg" \
    -o "TimeTracker/Assets.xcassets/AppIcon.appiconset/$name.png"
done
```

Then rebuild in Xcode. iOS masks the square into its own rounded shape, so keep
the artwork inside the central safe area — the ring here stops well short of the
edges for that reason.
