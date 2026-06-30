# Media assets

These power the project README:

- `demo.gif` — a cross-faded walkthrough of the four main screens.
- `chat.png`, `models.png`, `documents.png`, `settings.png` — screen captures.

## How they were generated

The screenshots are captured deterministically from the iOS simulator using a
compile-time demo seed (no tapping required, so it's reproducible in CI):

```bash
# Build with the demo seed and a target screen, install, launch, screenshot.
DEV=<simulator-udid>; BID=dev.ayushd70.manthan
for screen in chat models documents settings; do
  flutter build ios --simulator --debug \
    --dart-define=MANTHAN_DEMO=true --dart-define=MANTHAN_SCREEN=$screen
  xcrun simctl install "$DEV" build/ios/iphonesimulator/Runner.app
  xcrun simctl terminate "$DEV" "$BID" 2>/dev/null || true
  xcrun simctl launch "$DEV" "$BID"
  sleep 6
  xcrun simctl io "$DEV" screenshot docs/media/raw/$screen.png
done
```

The demo seed lives in `lib/core/demo/demo_seed.dart` and is gated behind the
`MANTHAN_DEMO` dart-define, so it is inert (dead code) in normal builds.

The GIF is assembled from the captures with `ffmpeg` using `xfade` crossfades
and a generated palette for quality. To shoot a real interactive recording
instead, enable airplane mode, record with `xcrun simctl io <udid> recordVideo`,
and convert to GIF with `ffmpeg`.
