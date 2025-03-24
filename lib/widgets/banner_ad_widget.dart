import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:idlefit/providers/generator_provider.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends ConsumerStatefulWidget {
  const BannerAdWidget({super.key});

  @override
  ConsumerState<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends ConsumerState<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd =
        AdService.createBannerAd()
          ..load().then((value) {
            setState(() {
              _isAdLoaded = true;
            });
          });
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highestTier = ref.read(
      generatorProvider.notifier.select((value) => value.highestTier),
    );
    if (highestTier < 9) {
      return SizedBox.shrink();
    }
    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox(
        height: 32,
        width: MediaQuery.of(context).size.width,
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
