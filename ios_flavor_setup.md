# iOS Flavor Setup — White-Label Gyms

Run `flutter create .` (if iOS folder not yet added) then follow these steps.

## 1. Add xcconfig files per flavor

Create `ios/Flutter/fitviz.xcconfig`:
```
#include "Generated.xcconfig"
FLUTTER_TARGET=lib/flavors/main_fitviz.dart
BUNDLE_ID=in.fitviz.member
APP_NAME=FitViz
```

Create `ios/Flutter/k2fitness.xcconfig`:
```
#include "Generated.xcconfig"
FLUTTER_TARGET=lib/flavors/main_k2fitness.dart
BUNDLE_ID=in.k2fitness.member
APP_NAME=K2 Fitness
```

## 2. Update ios/Runner/Info.plist

Replace the hardcoded bundle ID and display name with variables:

```xml
<key>CFBundleDisplayName</key>
<string>$(APP_NAME)</string>

<key>CFBundleIdentifier</key>
<string>$(BUNDLE_ID)</string>
```

## 3. Add Xcode schemes

In Xcode: Product → Scheme → Manage Schemes → Duplicate "Runner" twice.
- Rename to `fitviz` and `k2fitness`
- For each scheme: Edit Scheme → Build → Pre-actions: set environment variable
  `FLUTTER_TARGET` to the matching xcconfig value

OR use the command-line approach with `--flavor`:

## 4. Build commands

```bash
# Android
flutter build apk --flavor fitviz   -t lib/flavors/main_fitviz.dart
flutter build apk --flavor k2fitness -t lib/flavors/main_k2fitness.dart

# iOS
flutter build ipa --flavor fitviz   -t lib/flavors/main_fitviz.dart
flutter build ipa --flavor k2fitness -t lib/flavors/main_k2fitness.dart
```

## 5. Adding a new gym (e.g. GYM-003)

1. `android/app/build.gradle` — add productFlavor entry (5 min)
2. `lib/flavors/main_gymxxx.dart` — copy k2fitness template, update config (5 min)
3. `android/app/src/gymxxx/res/mipmap-*/` — add gym app icons from client
4. `assets/gymxxx/images/logo.png` — add gym logo from client
5. `ios/Flutter/gymxxx.xcconfig` — copy k2fitness template, update values (5 min)
6. Create Xcode scheme `gymxxx` in Xcode
7. Build and submit to separate Play Store / App Store listing

**Total effort per new gym: ~half a day** (mostly waiting for client assets)
