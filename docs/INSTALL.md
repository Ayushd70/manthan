# Installing Manthan

Pre-built binaries are published on [GitHub Releases](https://github.com/Ayushd70/manthan/releases).

## Android (recommended)

1. Open the [latest release](https://github.com/Ayushd70/manthan/releases/latest).
2. Download **`manthan-<version>-arm64-v8a.apk`** (works on nearly all modern phones).
3. Enable installation from your browser or file manager:
   - **Settings → Security → Install unknown apps** (wording varies by OEM).
4. Tap the APK to install.
5. Open Manthan. The **built-in demo engine** works offline immediately.
6. Optional: download a real model from the **Models** tab inside the app.

### Which APK should I pick?

| File suffix | Device |
| --- | --- |
| `arm64-v8a` | Default for phones from ~2017 onward |
| `armeabi-v7a` | Older 32-bit ARM phones |
| `x86_64` | Android emulators, some tablets |

### Verify the download (optional)

```bash
sha256sum -c SHA256SUMS.txt
```

Run this in the folder where you downloaded the APK and `SHA256SUMS.txt` from the release.

## Build from source

See the main [README](../README.md#getting-started) for Flutter setup. Minimum targets:

- **Android:** API 26+
- **iOS:** 16.0+ (requires Xcode and CocoaPods)
- **macOS:** 11.0+
- **Windows / Linux:** supported for development; mobile is the primary experience

## iOS

Apple does not allow unsigned IPA distribution through GitHub. To run on your iPhone:

```bash
git clone https://github.com/Ayushd70/manthan.git
cd manthan
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <your-device-id>
```

You need an Apple Developer account for device provisioning beyond personal debug builds.

## Models are not bundled

The app is small; **LLM weights download inside the app** on first use. You need network access for the initial model download, then everything works offline.
