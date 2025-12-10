# AdMob Integration - Quick Reference

## Files Added/Modified

### New Files Created
1. **`lib/services/connectivity_service.dart`** - Monitors internet connection
2. **`lib/services/ad_manager_service.dart`** - Manages all ad types
3. **`lib/widgets/ad_banner_widget.dart`** - Reusable banner ad widget
4. **`ADMOB_SETUP.md`** - Complete setup guide

### Modified Files
1. **`pubspec.yaml`** - Added google_mobile_ads and connectivity_plus
2. **`lib/main.dart`** - Initialize ad manager on app startup
3. **`android/app/src/main/AndroidManifest.xml`** - Added AdMob App ID
4. **`lib/screens/home/today_tasks_screen.dart`** - Added banner ad
5. **`lib/screens/home/completed_tasks_screen.dart`** - Added banner ad

## How Ads Work

### 1. Banner Ads (Currently Implemented)
Banner ads automatically show at the bottom of task lists when:
- User has internet connection
- Ad successfully loads

**Locations:**
- Today Tasks Screen (bottom of list)
- Completed Tasks Screen (bottom of list)

### 2. Interstitial Ads (Ready to Use)
Full-screen ads that can be shown at strategic points.

**Example Usage:**
```dart
import 'package:task_manager/services/ad_manager_service.dart';

// In your State class or function
final adManager = AdManagerService();

// Load the ad (do this early)
await adManager.loadInterstitialAd(
  onAdLoaded: () {
    print('Interstitial ad loaded and ready');
  },
  onAdFailedToLoad: (error) {
    print('Failed to load: $error');
  },
);

// Show the ad when appropriate
await adManager.showInterstitialAd();
```

**Good places to show interstitial ads:**
- After user completes 5 tasks
- When user navigates to insights screen
- After exporting tasks to PDF
- Between major app sections

### 3. Rewarded Ads (Ready to Use)
Users watch an ad to earn rewards (premium features, remove ads temporarily, etc.)

**Example Usage:**
```dart
import 'package:task_manager/services/ad_manager_service.dart';

final adManager = AdManagerService();

// Load the ad
await adManager.loadRewardedAd();

// Show and handle reward
await adManager.showRewardedAd(
  onUserEarnedReward: (ad, reward) {
    print('User earned: ${reward.amount} ${reward.type}');
    // Grant reward to user
    // Example: Remove ads for 24 hours, unlock premium feature, etc.
  },
);
```

**Reward Ideas:**
- Remove ads for 24 hours
- Unlock premium themes
- Export unlimited tasks
- Unlock advanced filters
- Get bonus task categories

## Internet Connectivity

The app automatically checks for internet before loading ads:

```dart
// The connectivity service is automatically used by ad_manager_service
// You can also use it manually:

import 'package:task_manager/services/connectivity_service.dart';

final connectivity = ConnectivityService();
await connectivity.initialize();

// Check if online
bool isOnline = await connectivity.checkConnection();

// Listen to connectivity changes
connectivity.connectionStatusController.stream.listen((hasConnection) {
  if (hasConnection) {
    print('Internet connected - can show ads');
  } else {
    print('No internet - hiding ads');
  }
});
```

## Adding Interstitial Ads Example

Here's how to add an interstitial ad after completing 5 tasks:

**In `lib/screens/home/today_tasks_screen.dart`:**

```dart
import '../../services/ad_manager_service.dart';

class _TodayTasksScreenState extends State<TodayTasksScreen> {
  final AdManagerService _adManager = AdManagerService();
  int _tasksCompletedCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadTasks();
    // Preload interstitial ad
    _adManager.loadInterstitialAd();
  }
  
  Future<void> _toggleTaskCompletion(Task task) async {
    // ... existing completion code ...
    
    if (!task.isCompleted) {
      _tasksCompletedCount++;
      
      // Show ad after every 5 task completions
      if (_tasksCompletedCount % 5 == 0) {
        await _adManager.showInterstitialAd();
      }
    }
    
    // ... rest of code ...
  }
}
```

## Adding Banner Ads to Other Screens

To add banner ads to any screen:

```dart
import 'package:task_manager/widgets/ad_banner_widget.dart';

// In your build method, add the widget where you want the ad:
Column(
  children: [
    // Your content here
    Expanded(
      child: ListView(
        // Your list items
      ),
    ),
    // Add banner ad at the bottom
    const AdBannerWidget(),
  ],
)
```

## Testing

### Current Status
✅ App is ready to test with Google's test ads
✅ All ad types are implemented and ready
✅ Internet connectivity check is working
✅ Banner ads showing on Today and Completed screens

### Test the Implementation
1. Run the app: `flutter run`
2. Navigate to Today Tasks or Completed Tasks
3. Scroll to bottom to see banner ad (if internet connected)
4. Try with WiFi/mobile data on and off

### Before Publishing
⚠️ **Must complete before Play Store submission:**
1. Create AdMob account
2. Create AdMob app and ad units
3. Replace test IDs with real IDs in:
   - `android/app/src/main/AndroidManifest.xml`
   - `lib/services/ad_manager_service.dart`
4. Test thoroughly with real ads
5. Follow all instructions in `ADMOB_SETUP.md`

## Revenue Tips

### Maximize Ad Revenue
1. **Don't show too many ads** - Balance user experience
2. **Strategic placement** - Show ads at natural break points
3. **Use multiple ad formats** - Mix banner, interstitial, and rewarded
4. **Optimize ad refresh** - Banner ads refresh automatically
5. **Track performance** - Monitor in AdMob console

### Best Practices
- Never force users to watch ads
- Always provide value in exchange for rewarded ads
- Don't place ads too close to interactive elements
- Test ad placement with real users
- Monitor crash reports related to ads

## Support & Documentation

- **AdMob Console**: https://admob.google.com
- **Flutter Plugin Docs**: https://pub.dev/packages/google_mobile_ads
- **Setup Guide**: See `ADMOB_SETUP.md` in project root
- **Google AdMob Policies**: https://support.google.com/admob/answer/6128543

---
**Ready to go live?** Follow the checklist in `ADMOB_SETUP.md`!
