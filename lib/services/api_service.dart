import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/services/cache_service.dart';
import 'package:mobile_app/services/sesion_movil.dart';

typedef CitasMoviles = ({
  List<dynamic> citas,
  bool desdeCache,
  String? actualizado,
});

class FalloLogin implements Exception {
  final String mensaje;
  const FalloLogin(this.mensaje);

  static const respuestaIncompatible = FalloLogin(
    'El servidor respondió sin una sesión móvil válida. Comprueba la versión del servidor.',
  );
}

class ApiService {
  static const String baseUrl = 'https://nextgen-motors-3xcw.onrender.com';
  static const Duration _timeout = Duration(seconds: 60);
  final http.Client? _client;
  final AlmacenSesion almacen;

  ApiService({http.Client? client, AlmacenSesion? almacen})
    : _client = client,
      almacen = almacen ?? AlmacenSesion();

  Future<http.Response> _get(
    String path,
    SesionMovil sesion, {
    Duration timeout = _timeout,
  }) async {
    if (!sesion.vigente) throw const AccesoDenegado();
    final uri = Uri.parse('$baseUrl$path');
    final response =
        await (_client?.get(uri, headers: sesion.headers) ??
                http.get(uri, headers: sesion.headers))
            .timeout(timeout);
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AccesoDenegado();
    }
    return response;
  }

  Future<http.Response> _post(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? body,
  }) {
    final uri = Uri.parse('$baseUrl$path');
    return (_client?.post(uri, headers: headers, body: body) ??
            http.post(uri, headers: headers, body: body))
        .timeout(_timeout);
  }

  Future<SesionMovil> login(String correo, String password) async {
    late final http.Response response;
    try {
      response = await _post(
        '/api/usuario/login',
        headers: {'Accept': 'application/json'},
        body: {'correo': correo.trim(), 'password': password},
      );
    } on TimeoutException {
      throw const FalloLogin('El servidor tardó demasiado en responder. Inténtalo de nuevo.');
    } on http.ClientException {
      throw const FalloLogin('No se pudo conectar con el servidor. Revisa tu conexión.');
    }
    if (response.statusCode == 401) throw const AccesoDenegado();
    if (response.statusCode != 200) {
      throw FalloLogin('El servidor rechazó el inicio de sesión (HTTP ${response.statusCode}).');
    }
    late final SesionMovil sesion;
    try {
      final datos = jsonDecode(utf8.decode(response.bodyBytes));
      if (datos is! Map<String, dynamic>) throw FalloLogin.respuestaIncompatible;
      sesion = SesionMovil.fromJson(datos);
    } on FormatException {
      throw FalloLogin.respuestaIncompatible;
    } on TypeError {
      throw FalloLogin.respuestaIncompatible;
    }
    if (!sesion.vigente) {
      throw const FalloLogin('La sesión recibida ya venció. Comprueba la fecha y la hora del teléfono.');
    }
    try {
      await almacen.guardar(sesion);
    } on Exception {
      throw const FalloLogin('El teléfono no pudo guardar la sesión de forma segura.');
    }
    return sesion;
  }

  Future<SesionMovil?> restaurar() async {
    final local = await almacen.leer();
    if (local == null) return null;
    try {
      final response = await _get(
        '/api/usuario/sesion',
        local,
        timeout: const Duration(seconds: 8),
      );
      if (response.statusCode != 200) {
        throw StateError('Error al verificar sesión');
      }
      final perfil =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (perfil['userId'] != local.userId) throw const AccesoDenegado();
      final actual = SesionMovil.fromJson({
        ...local.toJson(),
        'role': perfil['role'],
        'nombre': perfil['nombre'],
      });
      await almacen.guardar(actual);
      return actual;
    } on AccesoDenegado {
      await almacen.borrar();
      return null;
    } on http.ClientException {
      return local.vigente ? local : null;
    } on TimeoutException {
      return local.vigente ? local : null;
    }
  }

  Future<void> salir(SesionMovil sesion) async {
    await almacen.borrar();
    unawaited(_revocar(sesion));
  }

  Future<void> _revocar(SesionMovil sesion) async {
    try {
      await _post('/api/usuario/salir', headers: sesion.headers);
    } on http.ClientException {
      // Sin red la credencial del servidor termina al vencer.
    } on TimeoutException {
      // La credencial local ya se eliminó.
    }
  }

  Future<CitasMoviles> getCitas(SesionMovil sesion) async {
    final id = sesion.userId;
    late final http.Response response;
    try {
      response = await _get('/api/usuario/$id/citas', sesion);
    } on http.ClientException {
      return _citasGuardadas(id);
    } on TimeoutException {
      return _citasGuardadas(id);
    }
    if (response.statusCode != 200) {
      throw StateError('Error al consultar las citas');
    }
    final citas = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    await CacheService.cacheCitas(citas, userId: id);
    return (
      citas: citas,
      desdeCache: false,
      actualizado: await CacheService.getCitasCacheTimestamp(userId: id),
    );
  }

  Future<CitasMoviles> _citasGuardadas(String id) async => (
    citas: await CacheService.getCachedCitas(userId: id),
    desdeCache: true,
    actualizado: await CacheService.getCitasCacheTimestamp(userId: id),
  );

  Future<void> sendFcmToken(SesionMovil sesion, String token) async {
    if (!sesion.esCliente || !sesion.vigente) return;
    final response = await _post(
      '/api/usuario/${sesion.userId}/fcm-token',
      headers: sesion.headers,
      body: {'token': token},
    );
    if (response.statusCode != 200) {
      throw StateError('Registro de notificaciones no disponible');
    }
  }

  Future<Map<String, dynamic>> enviarMensajeDante(
    String mensaje, {
    List<Map<String, String>> historial = const [],
  }) async {
    final url = Uri.parse('$baseUrl/api/chatbot/mensaje');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'mensaje': mensaje, 'historial': historial}),
          )
          .timeout(_timeout);

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'respuesta': data['respuesta'] ?? '',
          'vehiculosRecomendados': data['vehiculosRecomendados'] ?? [],
        };
      } else {
        return {
          'success': false,
          'respuesta':
              data['respuesta'] ?? 'Dante no pudo procesar tu mensaje.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'respuesta':
            'Sin conexión. Tu historial está guardado localmente y se mantendrá cuando vuelvas a conectarte.',
      };
    }
  }

  // Alias para mantener compatibilidad con pantallas existentes
  Future<Map<String, dynamic>> obtenerRecomendacion(String mensaje) async {
    return enviarMensajeDante(mensaje);
  }

  Future<Map<String, dynamic>> obtenerDatosEmbudo(SesionMovil sesion) async {
    late final http.Response response;
    try {
      response = await _get('/api/prediccion/embudo', sesion);
    } on http.ClientException {
      return _embudoGuardado(sesion.userId);
    } on TimeoutException {
      return _embudoGuardado(sesion.userId);
    }
    if (response.statusCode != 200) {
      return {'success': false, 'message': 'Error al consultar el embudo'};
    }
    final datos =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final result = {...datos, 'success': true};
    await CacheService.cacheEmbudo(result, userId: sesion.userId);
    return result;
  }

  Future<Map<String, dynamic>> _embudoGuardado(String id) async {
    final datos = await CacheService.getCachedEmbudo(userId: id);
    return datos == null
        ? {'success': false, 'message': 'Sin datos guardados'}
        : {...datos, 'fromCache': true};
  }
}
