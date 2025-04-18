import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static String get bannerAdUnitId {
    // TODO: replace with your actual ad unit ID
    return 'ca-app-pub-3940256099942544/6300978111'; // Test ad unit ID
  }

  static String get rewardedAdUnitId {
    // TODO: replace with your actual rewarded ad unit ID
    return 'ca-app-pub-3940256099942544/5224354917'; // Test rewarded ad unit ID
  }

  static Future<void> initialize() async {
    await MobileAds.instance.initialize();
    Future.microtask(() => _loadRewardedAd());
  }

  static RewardedAd? _rewardedAd;

  static BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Ad loaded successfully');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Ad failed to load: $error');
          ad.dispose();
        },
      ),
    );
  }

  static Future<bool> _loadRewardedAd() async {
    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
          },
          onAdFailedToLoad: (error) {
            // TODO: retry with exponential backoff
            debugPrint('Failed to load rewarded ad: ${error.message}');
          },
        ),
      );
      return true;
    } catch (e) {
      // TODO: retry with exponential backoff
      debugPrint('Error showing rewarded ad: $e');
      return false;
    }
  }

  static Future<bool> showRewardedAd({
    required Function() onRewarded,
    required Function() onAdDismissed,
    required Function(String) onAdFailedToShow,
  }) async {
    final loadedAd = _rewardedAd;
    _loadRewardedAd();
    if (loadedAd == null) {
      onAdFailedToShow('Rewarded ad not loaded');
      return false;
    }
    try {
      loadedAd.show(
        onUserEarnedReward: (_, __) {
          onRewarded();
        },
      );
      return true;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      onAdFailedToShow(e.toString());
      return false;
    }
  }
}
