import 'dart:io';
import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'connectivity_service.dart';

class AdManagerService {
  static final AdManagerService _instance = AdManagerService._internal();
  factory AdManagerService() => _instance;
  AdManagerService._internal();

  final ConnectivityService _connectivityService = ConnectivityService();
  
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isInitialized = false;
  bool _isBannerAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  
  // Timer for periodic interstitial ads
  Timer? _adTimer;
  DateTime? _lastAdShownTime;
  static const Duration _adInterval = Duration(minutes: 1);

  // Test Ad Unit IDs (Replace with your actual AdMob IDs for production)
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // Replace with your actual AdMob Banner ID
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // Replace with your actual AdMob Interstitial ID
      return 'ca-app-pub-3940256099942544/1033173712'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/4411468910'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      // Replace with your actual AdMob Rewarded ID
      return 'ca-app-pub-3940256099942544/5224354917'; // Test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313'; // Test ID
    }
    throw UnsupportedError('Unsupported platform');
  }

  // Initialize Mobile Ads SDK
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await MobileAds.instance.initialize();
    _isInitialized = true;
    
    // Initialize connectivity service
    await _connectivityService.initialize();
    
    // Start the periodic ad timer
    startPeriodicInterstitialAds();
  }
  
  // Start showing interstitial ads every 1 minute
  void startPeriodicInterstitialAds() {
    // Load the first ad
    loadInterstitialAd();
    
    // Set up timer to show ads every 1 minute
    _adTimer?.cancel(); // Cancel any existing timer
    _adTimer = Timer.periodic(_adInterval, (timer) async {
      // Check if enough time has passed since last ad
      if (_lastAdShownTime == null || 
          DateTime.now().difference(_lastAdShownTime!) >= _adInterval) {
        await _showTimedInterstitialAd();
      }
    });
  }
  
  // Stop the periodic ad timer
  void stopPeriodicInterstitialAds() {
    _adTimer?.cancel();
    _adTimer = null;
  }
  
  // Internal method to show timed interstitial ads
  Future<void> _showTimedInterstitialAd() async {
    if (!await canShowAds()) return;
    
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
      _lastAdShownTime = DateTime.now();
    } else {
      // If ad not loaded, try to load it
      await loadInterstitialAd();
    }
  }

  // Check if we can show ads (based on internet connection)
  Future<bool> canShowAds() async {
    return await _connectivityService.checkConnection();
  }

  // ===== BANNER AD =====
  Future<void> loadBannerAd({
    required Function(BannerAd) onAdLoaded,
    Function(Ad, LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!await canShowAds()) {
      print('No internet connection. Cannot load banner ad.');
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _isBannerAdLoaded = true;
          onAdLoaded(ad as BannerAd);
        },
        onAdFailedToLoad: (ad, error) {
          _isBannerAdLoaded = false;
          ad.dispose();
          print('Banner ad failed to load: $error');
          onAdFailedToLoad?.call(ad, error);
        },
      ),
    );

    await _bannerAd!.load();
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  BannerAd? get bannerAd => _isBannerAdLoaded ? _bannerAd : null;

  // ===== INTERSTITIAL AD =====
  Future<void> loadInterstitialAd({
    Function()? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!await canShowAds()) {
      print('No internet connection. Cannot load interstitial ad.');
      return;
    }

    await InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              // Load a new ad for next time
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialAdLoaded = false;
              print('Interstitial ad failed to show: $error');
            },
          );
          
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoaded = false;
          print('Interstitial ad failed to load: $error');
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }

  Future<void> showInterstitialAd() async {
    if (_isInterstitialAdLoaded && _interstitialAd != null) {
      await _interstitialAd!.show();
    } else {
      print('Interstitial ad is not ready yet.');
      // Try to load a new ad
      await loadInterstitialAd();
    }
  }

  // ===== REWARDED AD =====
  Future<void> loadRewardedAd({
    Function()? onAdLoaded,
    Function(LoadAdError)? onAdFailedToLoad,
  }) async {
    if (!await canShowAds()) {
      print('No internet connection. Cannot load rewarded ad.');
      return;
    }

    await RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              // Load a new ad for next time
              loadRewardedAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedAdLoaded = false;
              print('Rewarded ad failed to show: $error');
            },
          );
          
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdLoaded = false;
          print('Rewarded ad failed to load: $error');
          onAdFailedToLoad?.call(error);
        },
      ),
    );
  }

  Future<void> showRewardedAd({
    required Function(AdWithoutView, RewardItem) onUserEarnedReward,
  }) async {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      await _rewardedAd!.show(
        onUserEarnedReward: onUserEarnedReward,
      );
    } else {
      print('Rewarded ad is not ready yet.');
      // Try to load a new ad
      await loadRewardedAd();
    }
  }

  // Dispose all ads
  void dispose() {
    disposeBannerAd();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    stopPeriodicInterstitialAds();
  }
}
