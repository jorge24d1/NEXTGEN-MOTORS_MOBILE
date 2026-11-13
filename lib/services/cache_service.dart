import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio centralizado de caché local aislado por usuario.
/// Guarda la última respuesta exitosa de cada endpoint del API
/// vinculada al ID del usuario para que la app funcione offline
/// y múltiples usuarios (ej: Cliente y Administrador) no mezclen sus datos.
class CacheService {
  // ── Prefijos de claves de almacenamiento ──
  static const String _citasPrefix = 'cache_citas';
  static const String _embudoPrefix = 'cache_embudo';
  static const String _chatHistoryPrefix = 'cache_chat_history';
  static const String _lastSyncPrefix = 'cache_last_sync';

  /// Resuelve el userId activo si no se pasa uno explícito
  static Future<String> _resolveUserId([String? userId]) async {
    if (userId != null && userId.trim().isNotEmpty) return userId.trim();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') ?? 'global';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  CITAS (AISLADAS POR CLIENTE)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Guarda la lista de citas en caché local vinculada al usuario
  static Future<void> cacheCitas(List<dynamic> citas, {String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_citasPrefix}_$uid', jsonEncode(citas));
    await prefs.setString(
      '${_citasPrefix}_${uid}_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  /// Recupera las citas del caché local del usuario actual o especificado
  static Future<List<dynamic>> getCachedCitas({String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    // Intento con clave por usuario
    String? raw = prefs.getString('${_citasPrefix}_$uid');
    // Fallback hacia clave legacy sin prefijo por compatibilidad
    raw ??= prefs.getString(_citasPrefix);

    if (raw == null) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  /// Devuelve la fecha de la última sincronización de citas
  static Future<String?> getCitasCacheTimestamp({String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_citasPrefix}_${uid}_timestamp') ??
        prefs.getString('${_citasPrefix}_timestamp');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  EMBUDO PREDICTIVO (ADMIN)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Guarda los datos del embudo predictivo en caché local
  static Future<void> cacheEmbudo(Map<String, dynamic> data, {String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_embudoPrefix}_$uid', jsonEncode(data));
    await prefs.setString(
      '${_embudoPrefix}_${uid}_timestamp',
      DateTime.now().toIso8601String(),
    );
  }

  /// Recupera los datos del embudo del caché local
  static Future<Map<String, dynamic>?> getCachedEmbudo({String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString('${_embudoPrefix}_$uid');
    raw ??= prefs.getString(_embudoPrefix);

    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Devuelve la fecha de la última sincronización del embudo
  static Future<String?> getEmbudoCacheTimestamp({String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_embudoPrefix}_${uid}_timestamp') ??
        prefs.getString('${_embudoPrefix}_timestamp');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  HISTORIAL DEL CHAT (DANTE - AISLADO POR USUARIO)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Guarda el historial del chat en caché local del usuario
  static Future<void> cacheChatHistory(
      List<Map<String, dynamic>> messages, {String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_chatHistoryPrefix}_$uid', jsonEncode(messages));
  }

  /// Recupera el historial del chat del usuario
  static Future<List<Map<String, dynamic>>> getCachedChatHistory({String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString('${_chatHistoryPrefix}_$uid');
    raw ??= prefs.getString(_chatHistoryPrefix);

    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Limpia el historial del chat del usuario actual
  static Future<void> clearChatHistory({String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_chatHistoryPrefix}_$uid');
    await prefs.remove(_chatHistoryPrefix);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  SESIÓN
  // ═══════════════════════════════════════════════════════════════════════════

  /// Verifica si hay una sesión activa guardada localmente
  static Future<bool> hasActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userId') != null;
  }

  /// Obtiene los datos de sesión guardados localmente
  static Future<Map<String, String?>> getSessionData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId'),
      'nombre': prefs.getString('nombre'),
      'role': prefs.getString('role'),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  UTILIDADES Y LIMPIEZA
  // ═══════════════════════════════════════════════════════════════════════════

  /// Registra la última sincronización exitosa para el usuario
  static Future<void> updateLastSync({String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_lastSyncPrefix}_$uid', DateTime.now().toIso8601String());
  }

  /// Obtiene la fecha de la última sincronización
  static Future<String?> getLastSync({String? userId}) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('${_lastSyncPrefix}_$uid') ??
        prefs.getString(_lastSyncPrefix);
  }

  /// Limpia la caché específica de un usuario (o del usuario actual)
  static Future<void> clearUserCache([String? userId]) async {
    final uid = await _resolveUserId(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_citasPrefix}_$uid');
    await prefs.remove('${_citasPrefix}_${uid}_timestamp');
    await prefs.remove('${_embudoPrefix}_$uid');
    await prefs.remove('${_embudoPrefix}_${uid}_timestamp');
    await prefs.remove('${_chatHistoryPrefix}_$uid');
    await prefs.remove('${_lastSyncPrefix}_$uid');
  }

  /// Limpia todas las cachés de todos los usuarios registrados
  static Future<void> clearAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('cache_')).toList();
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
