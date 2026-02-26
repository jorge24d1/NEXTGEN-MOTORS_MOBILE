import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // CONFIGURACIÓN DE CONEXIÓN:
  // 1. Azure (Producción): 'https://nextgen-motors2-bsbudccxcnadgabd.canadacentral-01.azurewebsites.net/api/usuario'
  // 2. Local (Emulador Android): 'http://10.0.2.2:8080/api/usuario'
  // 3. Ngrok (Link público): Pon aquí el link que te da ngrok http 8080

  static const String baseUrl =
      'https://sage-unrefusable-tearingly.ngrok-free.dev/api/usuario'; // URL de Ngrok activa

  Future<Map<String, dynamic>> login(String correo, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      body: {'correo': correo, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        // Guardar userId para uso futuro
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', data['userId']);
        await prefs.setString('nombre', data['nombre']);
      }
      return data;
    } else {
      throw Exception('Error en login: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getCitas() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId == null) throw Exception('Usuario no logueado');

    final response = await http.get(Uri.parse('$baseUrl/$userId/citas'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error al cargar citas');
    }
  }

  Future<void> sendFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      await http.post(
        Uri.parse('$baseUrl/$userId/fcm-token'),
        body: {'token': token},
      );
    }
  }

  // Nuevo método para Chatbot Gemini
  Future<Map<String, dynamic>> obtenerRecomendacion(String mensaje) async {
    final response = await http.post(
      Uri.parse('$baseUrl/recomendacion'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'mensaje': mensaje}),
    );

    if (response.statusCode == 200) {
      // Decodificamos utf8 para caracteres especiales en español
      return json.decode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('Error al conectar con Dante AI');
    }
  }
}
