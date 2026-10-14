import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class PowerBiPlatformView extends StatefulWidget {
  final String url;
  final double alturaBarra;

  const PowerBiPlatformView({
    super.key,
    required this.url,
    required this.alturaBarra,
  });

  @override
  State<PowerBiPlatformView> createState() => _PowerBiPlatformViewState();
}

class _PowerBiPlatformViewState extends State<PowerBiPlatformView> {
  static final Set<String> _registeredViews = {};
  late final String _viewType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _viewType = 'power-bi-${widget.url.hashCode}-${widget.alturaBarra.toInt()}';
    _registerView();
  }

  void _registerView() {
    if (_registeredViews.contains(_viewType)) return;
    _registeredViews.add(_viewType);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) {
        final container = web.HTMLDivElement()
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.overflow = 'hidden'
          ..style.position = 'relative'
          ..style.backgroundColor = '#0F1219';

        final iframe = web.HTMLIFrameElement()
          ..src = widget.url
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = 'calc(100% + ${widget.alturaBarra}px)'
          ..style.position = 'absolute'
          ..style.top = '0'
          ..style.left = '0';

        iframe.onLoad.listen((_) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        });

        container.appendChild(iframe);
        return container;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F1219),
      child: Stack(
        children: [
          HtmlElementView(viewType: _viewType),
          if (_isLoading)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "Cargando reporte de Power BI...",
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
