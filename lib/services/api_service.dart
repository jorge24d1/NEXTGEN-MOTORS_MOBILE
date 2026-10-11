import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ── URL BASE PRINCIPAL EN RENDER ──
  static const String baseUrl = 'https://nextgen-motors-3xcw.onrender.com';

  // Timeout de 60s por si Render Free tarda en despertar de suspensión
  static const Duration _timeout = Duration(seconds: 60);

  // ===========================================================================
  // 1. AUTENTICACIÓN / LOGIN
  // ===========================================================================
  Future<Map<String, dynamic>> login(String correo, String password) async {
    final url = Uri.parse('$baseUrl/api/usuario/login');

    try {
      final response = await http.post(
        url,
        body: {
          'correo': correo.trim(),
          'password': password,
        },
      ).timeout(_timeout);

      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && data['success'] == true) {
        // Guardar sesión del usuario en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (data['userId'] != null) await prefs.setString('userId', data['userId']);
        if (data['nombre'] != null) await prefs.setString('nombre', data['nombre']);
        if (data['role'] != null) await prefs.setString('role', data['role']);

        return {
          'success': true,
          'userId': data['userId'],
          'nombre': data['nombre'],
          'role': data['role'], // 'CLIENTE', 'ADMINISTRADOR', 'TRABAJADOR'
          'message': data['message'] ?? 'Login exitoso',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Credenciales incorrectas',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión con el servidor: $e',
      };
    }
  }

  // ===========================================================================
  // 2. CITAS DEL USUARIO
  // ===========================================================================
  Future<List<dynamic>> getCitas() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) throw Exception('Usuario no logueado');

    final url = Uri.parse('$baseUrl/api/usuario/$userId/citas');

    try {
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Error al cargar citas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión al cargar citas: $e');
    }
  }

  // ===========================================================================
  // 3. TOKEN FCM (NOTIFICACIONES PUSH)
  // ===========================================================================
  Future<void> sendFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      final url = Uri.parse('$baseUrl/api/usuario/$userId/fcm-token');
      try {
        await http.post(
          url,
          body: {'token': token},
        ).timeout(_timeout);
      } catch (e) {
        print('Error enviando token FCM: $e');
      }
    }
  }

  // ===========================================================================
  // 4. CHATBOT DE DANTE
  // ===========================================================================
  Future<Map<String, dynamic>> enviarMensajeDante(
    String mensaje, {
    List<Map<String, String>> historial = const [],
  }) async {
    final url = Uri.parse('$baseUrl/api/chatbot/mensaje');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'mensaje': mensaje,
          'historial': historial,
        }),
      ).timeout(_timeout);

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
          'respuesta': data['respuesta'] ?? 'Dante no pudo procesar tu mensaje.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'respuesta': 'Error al comunicar con Dante: $e',
      };
    }
  }

  // Alias para mantener compatibilidad con pantallas existentes
  Future<Map<String, dynamic>> obtenerRecomendacion(String mensaje) async {
    return enviarMensajeDante(mensaje);
  }

  // ===========================================================================
  // 5. EMBUDO PREDICTIVO (ADMINISTRADOR)
  // ===========================================================================
  Future<Map<String, dynamic>> obtenerDatosEmbudo() async {
    final url = Uri.parse('$baseUrl/api/prediccion/embudo');

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': true,
          'total': data['total'] ?? 0,
          'conInteres': data['conInteres'] ?? 0,
          'citaAprobada': data['citaAprobada'] ?? 0,
          'clientePotencial': data['clientePotencial'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener métricas del embudo (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
