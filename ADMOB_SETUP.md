# Google AdMob Integration Setup Guide

## Overview
This app integrates Google AdMob ads that only display when the user has an active internet connection.

## Features Implemented
- ✅ Banner ads at the bottom of task lists
- ✅ Interstitial ads (full-screen ads)
- ✅ Rewarded ads
- ✅ Internet connectivity check before showing ads
- ✅ Automatic ad loading and management

## Setup Instructions

### 1. Create an AdMob Account
1. Go to [https://admob.google.com](https://admob.google.com)
2. Sign in with your Google account
3. Click "Get Started" and follow the setup wizard

### 2. Create an AdMob App
1. In AdMob console, click "Apps" → "Add App"
2. Select "Android" platform
3. Choose "Yes" for "Is your app listed on Google Play?"
4. Enter your app name: **Flutter Tasker Pro**
5. Click "Add"

### 3. Create Ad Units
Create the following ad units in your AdMob app:

#### Banner Ad
- Name: `Banner - Task List`
- Ad format: Banner
- Copy the **Ad unit ID**

#### Interstitial Ad
- Name: `Interstitial - Between Tasks`
- Ad format: Interstitial
- Copy the **Ad unit ID**

#### Rewarded Ad (Optional)
- Name: `Rewarded - Premium Features`
- Ad format: Rewarded
- Copy the **Ad unit ID**

### 4. Update Ad Unit IDs

#### Step 1: Update AndroidManifest.xml
Open `android/app/src/main/AndroidManifest.xml` and replace the test App ID:

```xml
<!-- Replace this test ID with your actual AdMob App ID -->
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYYYY"/>
```

Your AdMob App ID can be found in AdMob console → App settings → App ID

#### Step 2: Update Ad Unit IDs in Code
Open `lib/services/ad_manager_service.dart` and replace the test ad unit IDs:

```dart
// Replace these test IDs with your actual AdMob ad unit IDs

static String get bannerAdUnitId {
  if (Platform.isAndroid) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/BBBBBBBBBB'; // Your Banner Ad Unit ID
  } else if (Platform.isIOS) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/CCCCCCCCCC'; // Your iOS Banner Ad Unit ID
  }
  throw UnsupportedError('Unsupported platform');
}

static String get interstitialAdUnitId {
  if (Platform.isAndroid) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/DDDDDDDDDD'; // Your Interstitial Ad Unit ID
  } else if (Platform.isIOS) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/EEEEEEEEEE'; // Your iOS Interstitial Ad Unit ID
  }
  throw UnsupportedError('Unsupported platform');
}

static String get rewardedAdUnitId {
  if (Platform.isAndroid) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/FFFFFFFFFF'; // Your Rewarded Ad Unit ID
  } else if (Platform.isIOS) {
    return 'ca-app-pub-XXXXXXXXXXXXXXXX/GGGGGGGGGG'; // Your iOS Rewarded Ad Unit ID
  }
  throw UnsupportedError('Unsupported platform');
}
```

### 5. Install Dependencies
Run the following command in your terminal:
```bash
flutter pub get
```

### 6. Test Ads

#### Using Test Ads (Current Setup)
The app is currently configured with Google's test ad unit IDs. You can test the implementation without making any changes:
- Test ads will show with a "Test Ad" label
- No revenue is generated from test ads
- Safe to click test ads during development

#### Using Real Ads
⚠️ **Important:** Only switch to real ad unit IDs when you're ready to publish:
1. Replace all test ad unit IDs with your actual IDs (as shown in Step 4)
2. Test thoroughly before publishing
3. Never click your own ads in production

### 7. Where Ads Are Displayed

#### Banner Ads
- **Today Tasks Screen**: At the bottom of the task list
- **Completed Tasks Screen**: At the bottom of the completed tasks list

#### Interstitial Ads (To implement)
You can trigger interstitial ads at strategic points:
```dart
import 'package:task_manager/services/ad_manager_service.dart';

// Load interstitial ad
await AdManagerService().loadInterstitialAd();

// Show when appropriate (e.g., after completing 5 tasks)
await AdManagerService().showInterstitialAd();
```

#### Rewarded Ads (To implement)
Offer users rewards for watching ads:
```dart
await AdManagerService().loadRewardedAd();

await AdManagerService().showRewardedAd(
  onUserEarnedReward: (ad, reward) {
    // Grant the reward to the user
    print('User earned reward: ${reward.amount} ${reward.type}');
  },
);
```

## Internet Connectivity Check
Ads will only be shown when:
- User has an active internet connection (WiFi, Mobile Data, or Ethernet)
- Connection is verified before loading each ad
- If connection is lost, ads are automatically hidden

## Troubleshooting

### Ads Not Showing
1. Check internet connection
2. Verify ad unit IDs are correct
3. Check AdMob console for ad serving status
4. Wait 1-2 hours after creating new ad units
5. Check logcat for error messages

### Test Ads Not Working
Ensure you're using the correct test ad unit IDs provided by Google

### Production Checklist
- [ ] Created AdMob account
- [ ] Created AdMob app
- [ ] Created all required ad units
- [ ] Updated App ID in AndroidManifest.xml
- [ ] Updated all ad unit IDs in ad_manager_service.dart
- [ ] Tested ads thoroughly
- [ ] App is ready for Play Store submission

## Revenue & Policies
1. Read [AdMob Program Policies](https://support.google.com/admob/answer/6128543)
2. Never click your own ads
3. Don't encourage users to click ads
4. Ensure ads don't interfere with app functionality
5. Follow Google Play Store policies

## Support
- AdMob Help Center: [https://support.google.com/admob](https://support.google.com/admob)
- Flutter Google Mobile Ads Plugin: [https://pub.dev/packages/google_mobile_ads](https://pub.dev/packages/google_mobile_ads)

---
**Note:** This implementation uses test ads by default. Remember to replace with your actual ad unit IDs before publishing to the Play Store!
