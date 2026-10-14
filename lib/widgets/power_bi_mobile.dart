import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F1219))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F1219),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minWidth: constraints.maxWidth,
                  maxWidth: constraints.maxWidth,
                  minHeight: constraints.maxHeight + widget.alturaBarra,
                  maxHeight: constraints.maxHeight + widget.alturaBarra,
                  child: WebViewWidget(controller: _controller),
                ),
              );
            },
          ),
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
