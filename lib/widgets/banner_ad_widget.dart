import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';
import '../helpers/constants.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
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
    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox(
        height: 50, // TODO: height of currency bar
        width: MediaQuery.of(context).size.width,
      ); // Placeholder height for the ad
    }

    return Container(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
      decoration: BoxDecoration(color: Constants.barColor),
      width: MediaQuery.of(context).size.width,
      child: SizedBox(
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
