import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ActualizacionAndroid extends NavigatorObserver {
  static const canal = MethodChannel('nextgen/version');
  bool _consultada = false;

  // La pantalla inicial ya ha restaurado la sesión y completado la navegación.
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_consultada || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _consultada = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_consultar()));
  }

  static bool hayActualizacion(int instalada, Map<String, dynamic> ficha) =>
      ficha['codigo'] is int && (ficha['codigo'] as int) > instalada &&
      ficha['version'] is String && ficha['novedades'] is String;

  Future<void> _consultar() async {
    try {
      final instalada = await canal.invokeMethod<int>('codigoInstalado');
      if (instalada == null) return;
      final respuesta = await http.get(Uri.parse('${ApiService.baseUrl}/api/movil/version'),
          headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 6));
      if (respuesta.statusCode != 200) return;
      final ficha = jsonDecode(utf8.decode(respuesta.bodyBytes));
      if (ficha is! Map<String, dynamic> || !hayActualizacion(instalada, ficha)) return;
      final context = navigator?.overlay?.context;
      if (context == null || !context.mounted) return;
      final abrir = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: Text('Nueva versión ${ficha['version']}'),
        content: SingleChildScrollView(child: Text(ficha['novedades'])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Más tarde')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Actualizar')),
        ],
      ));
      if (abrir == true) await canal.invokeMethod<void>('abrirDescarga');
    } on Exception {
      // El catálogo de versiones puede estar sin conexión durante el inicio.
    }
  }
}
