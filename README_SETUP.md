# FitViz Member App — Setup Guide

## 1. Install Flutter (if not already done)

1. Download: https://flutter.dev/docs/get-started/install/windows
2. Extract to `C:\flutter`, add `C:\flutter\bin` to PATH
3. Run `flutter doctor` and fix all red items
4. Install Android Studio + SDK (API 33)
5. Accept licenses: `flutter doctor --android-licenses`

## 2. Create Firebase Project

1. Go to https://console.firebase.google.com
2. Create project: "FitViz Member"
3. Add Android app with package name: `in.fitviz.member`
4. Download `google-services.json` → place in `android/app/`
5. Enable Cloud Messaging (FCM) in the Firebase console

## 3. Generate Android Keystore (one-time, for release builds)

```bash
keytool -genkey -v -keystore android/app/fitviz.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias fitviz
```

Create `android/key.properties` (NOT committed to git):
```
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=fitviz
storeFile=fitviz.jks
```

Add to `android/app/build.gradle` (already referenced there).

## 4. Install Dependencies

```bash
cd "c:\Uma Shankar\Claude\Projects\fitviz_member"
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

`build_runner` generates the `*.g.dart` and `*.freezed.dart` files needed by the app.

## 5. Run on Emulator

```bash
# List available devices
flutter devices

# Run in debug mode (hot reload enabled)
flutter run

# Run on specific device
flutter run -d emulator-5554
```

## 6. Build for Release

```bash
# Android APK (for direct install testing)
flutter build apk --release

# Android App Bundle (for Google Play)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

## 7. Add Missing Assets

Create these folders and add files:
```
assets/
  images/    ← logo.png, onboarding images
  icons/     ← custom icons
  fonts/     ← Inter-Regular.ttf, Inter-Medium.ttf, Inter-SemiBold.ttf, Inter-Bold.ttf
```

Download Inter font: https://fonts.google.com/specimen/Inter

## 8. Configure Razorpay

In `lib/core/constants/app_constants.dart`, replace:
```dart
static const String razorpayKeyId = 'rzp_live_XXXXXXXXXXXXXXXX';
```
With your actual Razorpay Key ID from the Razorpay Dashboard.

## 9. Backend API

The app connects to: `https://fitviz.in/api`

All member endpoints used:
- `POST /auth/login` — sign in
- `GET /fitness-plans/today` — today's workout + diet
- `GET /attendance/my` — attendance history
- `POST /attendance/checkin` / `checkout` — check in/out
- `GET /classes/member/schedule` — class timetable
- `GET /subscriptions/my` — active subscription
- `GET /announcements/active` + `/offers/active` — dashboard content

## 10. Google Play Store

1. Create account at https://play.google.com/console ($25 one-time fee)
2. Create app: "FitViz Member" | `in.fitviz.member`
3. Upload AAB to Internal Testing
4. Add store listing, screenshots (6.5" phone + tablet)
5. Add privacy policy URL (required for camera + notification permissions)
6. Submit for review → Internal → Closed Testing → Production

---

## Folder Structure

```
lib/
├── main.dart                    # Entry point: Firebase + ProviderScope
├── app.dart                     # MaterialApp.router + theme
├── core/
│   ├── constants/               # API endpoints, app strings
│   ├── network/                 # Dio + auth interceptor (auto token refresh)
│   ├── storage/                 # SecureStorage (Android Keystore / iOS Keychain)
│   ├── router/                  # go_router with auth guard
│   └── utils/                   # Date formatting, validators
├── features/
│   ├── auth/                    # Login, Register, Forgot Password + JWT flow
│   ├── dashboard/               # Home screen: plan, streak, offers
│   ├── workout/                 # Today's workout + diet plan + history
│   ├── attendance/              # Check-in/out + QR code + history
│   ├── classes/                 # Group class booking
│   ├── subscription/            # Plans + Razorpay payment
│   ├── progress/                # Body metrics charts + progress photos
│   └── profile/                 # Edit profile, biometric, referral, logout
└── shared/
    ├── widgets/                 # MainShell (bottom nav)
    └── theme/                   # FitViz dark theme (volt green #C8FF00)
```
