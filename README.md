# Laventra Mobile — Setup Guide

Flutter app for car wash owners. Requires **Flutter 3.41.x** (stable) and
**Dart 3.11+**. A running Laventra API backend is needed for login and data.

---

## General

### 1. Backend URL

Point the app at your backend in `lib/core/constants/api_constants.dart`:

```dart
static const String baseUrl = 'http://YOUR_BACKEND/api/v1';
```

> Phones and emulators can't reach `localhost` — use your machine's LAN IP, or a
> tunnel like ngrok.

### 2. Firebase (push notifications)

These config files are gitignored — download them from the Firebase console:

* iOS → `ios/Runner/GoogleService-Info.plist`
* Android → `android/app/google-services.json`

The app builds without them, but push notifications won't work.

---

## Setup (macOS, Linux & Windows)

```bash
git clone <repo-url>
cd laventra_mobile

flutter pub get
flutter run            # use `flutter devices` to see what's connected
```

> **iOS builds need a Mac.** First time only: `cd ios && pod install && cd ..`,
> then open `ios/Runner.xcworkspace` in Xcode and set your signing team.

---

## Build for Release

```bash
flutter build apk --release          # Android
flutter build appbundle --release    # Android (Play Store)
flutter build ipa                    # iOS (Mac only)
```
</content>
