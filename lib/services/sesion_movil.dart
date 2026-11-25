import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SesionMovil {
  final String userId, nombre, role, token;
  final DateTime vence;

  const SesionMovil(
    this.userId,
    this.nombre,
    this.role,
    this.token,
    this.vence,
  );

  bool get esCliente => role == 'CLIENTE';
  bool get vigente => vence.isAfter(DateTime.now());
  Map<String, String> get headers => {'Authorization': 'Bearer $token'};

  factory SesionMovil.fromJson(Map<String, dynamic> json) {
    final sesion = SesionMovil(
      json['userId'] as String,
      json['nombre'] as String,
      json['role'] as String,
      json['token'] as String,
      DateTime.parse(json['vence']),
    );
    if (sesion.userId.isEmpty ||
        sesion.token.isEmpty ||
        !{'CLIENTE', 'ADMINISTRADOR', 'TRABAJADOR'}.contains(sesion.role)) {
      throw const FormatException('Sesión inválida');
    }
    return sesion;
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'nombre': nombre,
    'role': role,
    'token': token,
    'vence': vence.toUtc().toIso8601String(),
  };
}

class AlmacenSesion {
  static const _storage = FlutterSecureStorage();
  static const _key = 'sesion_movil';

  Future<SesionMovil?> leer() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      final sesion = SesionMovil.fromJson(jsonDecode(raw));
      if (sesion.vigente) return sesion;
    } on FormatException {
      // Un registro ilegible requiere volver a entrar.
    } on TypeError {
      // Un registro incompleto tampoco acredita una sesión.
    }
    await borrar();
    return null;
  }

  Future<void> guardar(SesionMovil sesion) =>
      _storage.write(key: _key, value: jsonEncode(sesion.toJson()));
  Future<void> borrar() => _storage.delete(key: _key);
}

class AccesoDenegado implements Exception {
  const AccesoDenegado();
}
