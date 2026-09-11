# 🌊 WavesLive

> **AI-Powered Mobile Platform for Real-Time Ocean Hazard Detection and Reporting**

WavesLive is a cross-platform Flutter application that enables citizens, coastal authorities, and marine researchers to **detect, report, and monitor ocean hazards** in real time. Users can capture sea/coastal photos, which are validated through a pixel-level image analysis engine and then processed through AI-assisted hazard classification.

---

## 📱 Features

| Feature | Description |
|---|---|
| 🌊 **Hazard Monitoring** | Real-time ocean and coastal hazard tracking on an interactive map |
| 📸 **Data Acquisition** | Capture and submit geo-tagged coastal photos for hazard analysis |
| 🤖 **AI Model Processing** | Automated image classification and hazard severity scoring |
| 🚨 **Alert System** | Push notifications and alert management for active hazards |
| 📋 **Report Management** | Full report lifecycle — draft, submit, verify, resolve |
| ✅ **Verification** | Admin/expert verification pipeline for submitted reports |
| 🛡️ **Mitigation Guidance** | Actionable mitigation recommendations per hazard type |
| 👤 **User Management** | Role-based access (citizen, admin, expert) |
| 🖼️ **Image Validation** | On-device pixel-analysis engine that rejects non-sea photos |

---

## 🏗️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev/) (SDK `^3.9.2`)
- **State Management**: [Riverpod](https://riverpod.dev/) (`flutter_riverpod ^2.6.1`)
- **Navigation**: [go_router](https://pub.dev/packages/go_router) (`^14.8.1`)
- **Maps**: [flutter_map](https://pub.dev/packages/flutter_map) + [latlong2](https://pub.dev/packages/latlong2)
- **Location**: [geolocator](https://pub.dev/packages/geolocator) + [geocoding](https://pub.dev/packages/geocoding)
- **Image Picker**: [image_picker](https://pub.dev/packages/image_picker)
- **Fonts**: [google_fonts](https://pub.dev/packages/google_fonts)
- **Storage**: [shared_preferences](https://pub.dev/packages/shared_preferences)
- **Utilities**: `intl`, `uuid`

---

## 🚀 Getting Started — Run on Another Laptop

Follow these steps to clone and run **WavesLive** on a fresh machine.

### Prerequisites

Make sure the following tools are installed:

| Tool | Version | Install Link |
|---|---|---|
| Flutter SDK | `^3.9.2` | [flutter.dev/get-started](https://flutter.dev/get-started) |
| Dart SDK | Bundled with Flutter | (comes with Flutter) |
| Git | Any recent version | [git-scm.com](https://git-scm.com/) |
| Android Studio *(for Android)* | Latest | [developer.android.com/studio](https://developer.android.com/studio) |
| Xcode *(for iOS/macOS — Mac only)* | Latest | Mac App Store |
| Chrome *(for Web)* | Latest | [google.com/chrome](https://www.google.com/chrome/) |

---

### Step 1 — Verify Flutter Installation

Open a terminal and run:

```bash
flutter doctor
```

Fix any issues reported by `flutter doctor` before proceeding. All required checkmarks should be ✅.

---

### Step 2 — Clone the Repository

```bash
git clone https://github.com/ArulMuruganbhaskaran/waveslive.git
cd waveslive
```

---

### Step 3 — Install Dependencies

```bash
flutter pub get
```

---

### Step 4 — Run the App

Pick the platform you want to run on:

#### 📱 Android (physical device or emulator)

```bash
# List connected devices
flutter devices

# Run on a specific device
flutter run -d <device-id>

# Or simply (picks the first available device)
flutter run
```

> **Tip:** Make sure USB Debugging is enabled on your Android device, or start an Android Virtual Device (AVD) via Android Studio.

#### 🍎 iOS (Mac only)

```bash
# Install CocoaPods dependencies first
cd ios && pod install && cd ..

# Run on simulator
flutter run -d iPhone
```

> **Requires:** Xcode installed and a valid Apple Developer account for physical device testing.

#### 🌐 Web (Chrome)

```bash
flutter run -d chrome
```

#### 🖥️ Desktop

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

---

### Step 5 — Build Release (Optional)

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (Mac only)
flutter build ipa

# Web
flutter build web
```

---

## 📁 Project Structure

```
waveslive/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── core/
│   │   ├── constants/               # App-wide constants & theme
│   │   └── routes/                  # go_router configuration
│   ├── features/
│   │   ├── splash/                  # Splash screen
│   │   ├── user/                    # Login, registration, profile
│   │   ├── hazard_monitoring/       # Map & hazard list views
│   │   ├── data_acquisition/        # Photo capture & submission
│   │   ├── model_processing/        # AI analysis results
│   │   ├── alert/                   # Alert notifications & history
│   │   ├── report_management/       # Report CRUD
│   │   ├── verification/            # Expert verification workflow
│   │   ├── mitigation/              # Mitigation recommendations
│   │   └── admin/                   # Admin dashboard
│   ├── models/                      # Data models
│   ├── providers/                   # Riverpod providers
│   ├── services/
│   │   ├── image_validation_service.dart   # Pixel-analysis image validator
│   │   ├── mock_data_store.dart            # In-memory mock data
│   │   ├── mock_services.dart              # Mock service implementations
│   │   └── user_store.dart                 # User session store
│   └── widgets/                     # Shared reusable widgets
├── assets/
│   └── images/                      # App image assets
├── android/                         # Android platform files
├── ios/                             # iOS platform files
├── web/                             # Web platform files
├── windows/                         # Windows platform files
├── macos/                           # macOS platform files
├── linux/                           # Linux platform files
└── pubspec.yaml                     # Dependencies & asset declarations
```

---

## 🖼️ Image Validation Engine

WavesLive includes an on-device **4-layer pixel analysis pipeline** to ensure only sea/coastal photos are submitted:

1. **Format Check** — Validates file extension (JPG, PNG, WEBP, HEIC)
2. **File Size Check** — Rejects files < 8 KB or > 25 MB
3. **Filename Heuristics** — Detects selfies, food, indoor shots by filename keywords
4. **Pixel Colour Analysis** — Decodes image → samples 40×40 grid → classifies pixels into colour buckets (ocean blue, sky blue, skin tone, sand, foam, vegetation) → accepts or rejects based on water coverage ratios

---

## 🔧 Troubleshooting

| Issue | Fix |
|---|---|
| `flutter doctor` shows missing SDK | Install the missing tool listed and re-run `flutter doctor` |
| Android device not detected | Enable **USB Debugging** in Developer Options |
| iOS `pod install` fails | Run `sudo gem install cocoapods` then retry |
| Web build fails | Run `flutter upgrade` to get the latest Flutter version |
| `flutter pub get` fails | Check internet connection; try `flutter pub cache repair` |
| Build errors after pull | Run `flutter clean && flutter pub get` |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m 'Add your feature'`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is for educational and research purposes. All rights reserved © 2026 WavesLive Team.

---

<p align="center">Made with ❤️ using Flutter</p>
