import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import 'package:idlefit/providers/providers.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  late final int _highestTier;

  @override
  void initState() {
    super.initState();
    _highestTier = ref.read(
      generatorProvider.notifier.select((value) => value.highestTier),
    );
    if (_highestTier < 9) return;
    _loadAd();
  }

  Future<void> _loadAd() async {
    final bannerAd = AdService.createBannerAd();
    await bannerAd.load();
    setState(() {
      if (!mounted) return;
      _bannerAd = bannerAd;
      _isAdLoaded = true;
    });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_highestTier < 9) {
      return SizedBox.shrink();
    }
    print("happen");
    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox(
        height: 32,
        // width: MediaQuery.of(context).size.width,
      ); // Placeholder height for the ad
    }

    return Container(
      padding: const EdgeInsets.all(12),
      width: MediaQuery.of(context).size.width,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
