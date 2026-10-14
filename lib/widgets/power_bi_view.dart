import 'package:flutter/material.dart';

import 'power_bi_mobile.dart'
    if (dart.library.js_interop) 'power_bi_web.dart' as impl;

class PowerBiView extends StatelessWidget {
  final String url;
  final double alturaBarra;

  const PowerBiView({
    super.key,
    required this.url,
    this.alturaBarra = 56,
  });

  @override
  Widget build(BuildContext context) {
    return impl.PowerBiPlatformView(
      url: url,
      alturaBarra: alturaBarra,
    );
  }
}
