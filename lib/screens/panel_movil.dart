import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/sesion_movil.dart';
import 'admin_screen.dart';
import 'home_screen.dart';

class PanelMovil extends StatefulWidget {
  final SesionMovil sesion;
  const PanelMovil(this.sesion, {super.key});

  static Widget pantalla(SesionMovil sesion, VoidCallback salir) =>
      sesion.esCliente
      ? HomeScreen(sesion: sesion, salir: salir)
      : AdminScreen(sesion: sesion, salir: salir);

  @override
  State<PanelMovil> createState() => _PanelMovilState();
}

class _PanelMovilState extends State<PanelMovil> {
  late final Timer _vencimiento;
  bool _saliendo = false;

  @override
  void initState() {
    super.initState();
    final sesion = widget.sesion;
    _vencimiento = Timer(sesion.vence.difference(DateTime.now()), _salir);
    if (sesion.esCliente && sesion.vigente) {
      unawaited(NotificationService.activar(sesion));
    }
  }

  Future<void> _salir() async {
    if (!mounted || _saliendo) return;
    _saliendo = true;
    await ApiService().salir(widget.sesion);
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  @override
  void dispose() {
    _vencimiento.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      PanelMovil.pantalla(widget.sesion, _salir);
}
