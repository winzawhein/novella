import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Test ads by default. Release builds must explicitly opt in.
class LibraryAd extends StatefulWidget {
  const LibraryAd({super.key});
  @override
  State<LibraryAd> createState() => _LibraryAdState();
}

class _LibraryAdState extends State<LibraryAd> {
  static Future<bool>? _consent;
  BannerAd? _ad;
  bool _loaded = false;
  bool _privacyRequired = false;
  static Future<bool> _prepare() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!done.isCompleted) done.complete();
        });
      },
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    // The form is user-controlled; do not time out while they read it.
    await done.future;
    if (!await ConsentInformation.instance.canRequestAds()) return false;
    await MobileAds.instance.initialize();
    return true;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    if (kReleaseMode && !const bool.fromEnvironment('ENABLE_ADS')) return;
    try {
      final allowed = await (_consent ??= _prepare());
      if (!mounted) return;
      final required = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (!mounted) return;
      setState(
        () => _privacyRequired =
            required == PrivacyOptionsRequirementStatus.required,
      );
      if (!allowed) {
        _consent = null;
        return;
      }
      final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
        MediaQuery.sizeOf(context).width.floor(),
      );
      if (!mounted || size == null) return;
      final configured = Platform.isAndroid
          ? const String.fromEnvironment('ADMOB_ANDROID_BANNER_ID')
          : const String.fromEnvironment('ADMOB_IOS_BANNER_ID');
      final id = configured.isNotEmpty && kReleaseMode
          ? configured
          : Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';
      _ad = BannerAd(
        adUnitId: id,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (mounted && identical(ad, _ad)) setState(() => _loaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (mounted && identical(ad, _ad)) {
              setState(() {
                _ad = null;
                _loaded = false;
              });
            }
          },
        ),
      );
      await _ad!.load();
    } catch (_) {
      _consent = null;
      /* Ads must never block importing or reading. */
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (_loaded && _ad != null) ...[
        const Padding(
          padding: EdgeInsets.only(top: 12, bottom: 4),
          child: Text('Advertisement', style: TextStyle(fontSize: 11)),
        ),
        SizedBox(
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
      ],
      if (_privacyRequired)
        TextButton(
          onPressed: () {
            _ad?.dispose();
            setState(() {
              _ad = null;
              _loaded = false;
            });
            ConsentForm.showPrivacyOptionsForm((_) {
              _consent = null;
              if (mounted) _load();
            });
          },
          child: const Text('Ad privacy choices'),
        ),
    ],
  );
}
