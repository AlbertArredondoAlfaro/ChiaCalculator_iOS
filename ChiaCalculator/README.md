# Chia Calculator (iOS)

A SwiftUI-only iOS app that mirrors the core functionality of chiacalculator.com: estimate Chia (XCH) farming rewards based on your number of plots, plot size, and compression level.

## Requirements
- Xcode 15+ (iOS 17+ deployment)
- No external dependencies

## Run
1. Open `ChiaCalculator/ChiaCalculator.xcodeproj` in Xcode.
2. Select a simulator or device.
3. Build and run.

## Features
- Modern SwiftUI state management with `@Observable` and `@Bindable`.
- Live data fetch from SpaceFarmers.io (netspace + XCH price).
- Plot size selector (k=32, k=33, k=34) and compression level selector (C0–C9).
- Earnings + chances based on netspace ratio and block rewards (including halvings).
- iOS 26-style Liquid Glass with fallbacks on iOS 17+.
- Localization: English, Spanish, Catalan, French, German.

## Data Sources
- SpaceFarmers API (public, no auth): `https://spacefarmers.io/api/pool/stats`
  - Used fields: `status`, `data.xch.netspaceTiB`, `data.xch.usdt`, `data.xch.peakHeight`.

## Notes
- Plot sizes follow the official Chia k-size table.
- App icon: placeholder exists in `ChiaCalculator/Assets.xcassets` (replace for release).
- If the API shape changes, update decoding in `ChiaCalculator/Models/PoolStatsResponse.swift`.

## Localization
Localizable strings are stored in top-level `.lproj` folders (e.g., `ChiaCalculator/es.lproj/Localizable.strings`) and follow the device language automatically.
