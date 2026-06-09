# FlowState — iOS Setup Guide

**Author:** Võ Quang Phúc  
**Platform:** iOS 17+ | Swift 5.9 | Xcode 15+  
**Bundle ID:** `com.flowstate.app`

---

## 1. Open in Xcode

```bash
open FlowState.xcodeproj
```

---

## 2. Required First Steps

### A. Set Your Team / Bundle ID
1. Select the **FlowState** target in Xcode
2. Go to **Signing & Capabilities**
3. Set **Team** to your Apple Developer account
4. Change **Bundle Identifier** if needed (e.g., `com.yourname.flowstate`)

### B. Install Custom Fonts
The app uses **DM Serif Display** and **Plus Jakarta Sans**.

Download from Google Fonts:
- https://fonts.google.com/specimen/DM+Serif+Display
- https://fonts.google.com/specimen/Plus+Jakarta+Sans

Then:
1. Drag `.ttf` files into `FlowState/Resources/` in Xcode
2. Check **"Add to target: FlowState"**
3. Verify `Info.plist` has `UIAppFonts` array (already included)

**Fonts needed:**
```
DMSerifDisplay-Regular.ttf
DMSerifDisplay-Italic.ttf
PlusJakartaSans-Regular.ttf
PlusJakartaSans-Medium.ttf
PlusJakartaSans-SemiBold.ttf
PlusJakartaSans-Bold.ttf
```

> **Note:** If fonts are missing, the app falls back to system fonts (SF Pro) and will still build and run correctly.

### C. StoreKit Configuration (Simulator)
1. In Xcode: **File → New → File → StoreKit Configuration File**
2. Name it `FlowState.storekit`
3. Add two subscriptions:
   - Product ID: `com.flowstate.app.premium.monthly` — $3.99/month
   - Product ID: `com.flowstate.app.premium.annual` — $24.99/year
4. In scheme settings: **Run → Options → StoreKit Configuration → FlowState.storekit**

### D. CloudKit (Optional — Premium feature)
- Already configured in entitlements
- Requires enabling **iCloud** capability in Xcode with your team
- For local-only testing: entitlements can be left as-is (CloudKit is only used with Premium subscription)

---

## 3. Build & Run

### Simulator
```
Cmd + R  →  Select any iPhone simulator (iOS 16+)
```

### Device
1. Connect iPhone (iOS 16.0+)
2. Trust device in Xcode
3. `Cmd + R`

---

## 4. App Architecture

```
FlowState/
├── App/                    # Entry point, tab routing
├── Core/
│   ├── Models/             # SwiftData @Model classes
│   ├── ViewModels/         # @Observable view models
│   └── Services/           # Timer, Audio, Notifications, StoreKit, Haptics
├── Features/               # All screens (one file per screen)
│   ├── HomeScreen.swift
│   ├── TimerScreen.swift
│   ├── BreakScreen.swift
│   ├── EnergyCheckinView.swift
│   ├── MicroCommitmentScreen.swift
│   ├── AnalyticsScreen.swift
│   ├── SettingsScreen.swift
│   ├── OnboardingScreen.swift
│   ├── PaywallScreen.swift
│   └── SoundscapePickerView.swift
├── Shared/
│   ├── Components/         # TimerRingView, PrimaryButton, etc.
│   ├── Extensions/         # Date, TimeInterval, LocalizationManager
│   └── Theme/              # AppColors, AppTypography
├── en.lproj/               # English strings
└── vi.lproj/               # Vietnamese strings
```

---

## 5. Localization

The app supports **English** and **Vietnamese**.

To add a new language:
1. Create `[lang].lproj/Localizable.strings`
2. Copy from `en.lproj/Localizable.strings` and translate
3. Add the language code to `AppLanguage` enum in `UserPreferences.swift`
4. Add a case to `LocalizationManager.bundle`

The user can switch language in **Settings → Language**.

---

## 6. Database

The app uses **SwiftData** (local, no network required):

| Model | Description |
|---|---|
| `SessionRecord` | One row per focus session (mode, duration, status, energy) |
| `EnergyLog` | Energy level check-ins |

Data is stored in the app's local container. No migration needed for v1.

---

## 7. DEBUG Features

In debug builds, Settings screen shows:
- **Toggle Premium** — simulate Premium subscription without StoreKit
- **Reset Onboarding** — re-run the onboarding flow

---

## 8. Known Limitations (v1.0)

- **Audio files** not bundled (simulator will show UI state but no actual audio). Add `.mp3` files named `rain`, `cafe`, `white_noise`, etc. to Resources/Sounds.
- **Live Activity** requires iOS 16.2+ device; not available in simulator
- **WidgetKit** target not yet added (placeholder in architecture)
- **WatchKit** target not yet added (placeholder in architecture)
- **CloudKit sync** disabled until Apple Developer account is configured

---

## 9. Next Steps

- [ ] Add WidgetKit target (home screen + lock screen widgets)
- [ ] Add WatchKit target (companion app)
- [ ] Bundle soundscape audio files
- [ ] Add ActivityKit Live Activity for lock screen bar
- [ ] App Store screenshots and metadata
