# Chia Calculator (iOS)

A SwiftUI-only iOS app that mirrors the core functionality of chiacalculator.com: estimate Chia (XCH) farming rewards based on your number of plots.

## Requirements
- Xcode 15+ (iOS 17+ deployment)
- No external dependencies

## Run
1. Open Xcode and create a new iOS App project named `ChiaCalculator`.
2. Replace the generated source files with the contents of this folder (or add them directly).
3. Build and run on a simulator or device.

## Notes
- The app fetches live data from the SpaceFarmers.io public API (no authentication required).
- Endpoint shape (sample provided): `status`, `data.xch.netspaceTiB`, and `data.xch.usdt`.
- App icon: a placeholder AppIcon set exists in `ChiaCalculator/Assets.xcassets`. Replace with your final assets before release.
- Asset placeholders: you can add an App Icon and optional background images in `Assets.xcassets` if desired.

## Localization
Localizable strings are provided in English, Spanish, Catalan, French, and German (stored as top-level `.lproj` folders). The app follows the device language automatically.
