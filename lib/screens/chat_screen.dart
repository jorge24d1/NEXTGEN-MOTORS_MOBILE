import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/cache_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _messages = []; // {text, isUser, vehicle?}
  bool _isLoading = false;
  bool _restoredFromCache = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadCachedHistory();
  }

  /// Carga el historial guardado del caché al iniciar
  Future<void> _loadCachedHistory() async {
    final cached = await CacheService.getCachedChatHistory();
    if (cached.isNotEmpty) {
      setState(() {
        _messages.addAll(cached);
        _restoredFromCache = true;
      });
      _scrollToBottom();
    } else {
      // Mensaje de bienvenida inicial solo si no hay historial
      _addMessage(
        "¡Hola! Soy Dante 🤖, tu asesor experto de NextGen Motors. ¿Qué tipo de vehículo estás buscando hoy?",
        false,
      );
    }
  }

  void _addMessage(String text, bool isUser, {Map<String, dynamic>? vehicle}) {
    setState(() {
      _messages.add({"text": text, "isUser": isUser, "vehicle": vehicle});
    });
    // Guardar historial en caché cada vez que se agrega un mensaje
    _saveChatHistory();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    // Scroll al fondo
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Persiste el historial del chat en almacenamiento local
  Future<void> _saveChatHistory() async {
    // Guardamos solo texto y isUser (sin vehicle para simplicidad)
    final toCache = _messages.map((m) {
      return {
        'text': m['text'],
        'isUser': m['isUser'],
        // Guardar vehicle si existe (como Map serializable)
        if (m['vehicle'] != null) 'vehicle': m['vehicle'],
      };
    }).toList();
    await CacheService.cacheChatHistory(toCache);
  }

  /// Limpia el historial y empieza una nueva conversación
  Future<void> _clearHistory() async {
    await CacheService.clearChatHistory();
    setState(() {
      _messages.clear();
      _restoredFromCache = false;
    });
    _addMessage(
      "¡Hola! Soy Dante 🤖, tu asesor experto de NextGen Motors. ¿Qué tipo de vehículo estás buscando hoy?",
      false,
    );
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _addMessage(text, true);

    setState(() => _isLoading = true);

    try {
      // 1. Armamos el historial de conversación para que Dante recuerde el contexto
      final historial = _messages
          .where((m) => m['text'] != null)
          .map((m) => {
                'role': m['isUser'] == true ? 'user' : 'assistant',
                'content': m['text'] as String,
              })
          .toList();

      // 2. Enviamos el mensaje con historial a Dante
      final response = await _apiService.enviarMensajeDante(text, historial: historial);

      if (response['success'] == true) {
        final botReply = response['respuesta'] ??
            response['textoRespuesta'] ??
            "¡Listo! Aquí tienes la información.";
        final vehicles = response['vehiculosRecomendados'] as List<dynamic>?;

        Map<String, dynamic>? vehicleData;
        if (vehicles != null && vehicles.isNotEmpty) {
          vehicleData = vehicles.first as Map<String, dynamic>?;
        }

        _addMessage(botReply, false, vehicle: vehicleData);
      } else {
        _addMessage(
          response['respuesta'] ?? "Dante no pudo procesar tu mensaje en este momento.",
          false,
        );
      }
    } catch (e) {
      _addMessage(
        "Lo siento, hubo un problema al conectar con Dante. Tu historial está guardado localmente.",
        false,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Asistente Dante AI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Botón para limpiar historial
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 22),
            tooltip: 'Nueva conversación',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E2433),
                  title: const Text(
                    '¿Nueva conversación?',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Se borrará el historial del chat guardado.',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _clearHistory();
                      },
                      child: const Text(
                        'Borrar',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner de historial restaurado
          if (_restoredFromCache)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF2196F3).withOpacity(0.15),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Color(0xFF2196F3), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Conversación anterior restaurada',
                      style: TextStyle(
                        color: Color(0xFF2196F3),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _restoredFromCache = false),
                    child: const Icon(Icons.close, color: Colors.white38, size: 16),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] == true;
                final vehicle = msg['vehicle'] as Map<String, dynamic>?;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: isUser
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: isUser
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isUser)
                            const Padding(
                              padding: EdgeInsets.only(right: 8, top: 4),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundColor: Color(0xFF2196F3),
                                child: Icon(
                                  Icons.smart_toy,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isUser
                                    ? colorScheme.primary
                                    : const Color(0xFF1E2433),
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 20),
                                ),
                                boxShadow: [
                                  if (!isUser)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: Colors.white,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (vehicle != null) _buildVehicleCard(vehicle),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF2196F3),
                    ),
                  ),
                ),
              ),
            ),
          _buildInputArea(theme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: const Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E2433),
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Pregúntale a Dante...',
                  hintStyle: TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> v) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8, right: 40),
      child: Card(
        color: const Color(0xFF1E2433),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.directions_car,
                    color: Color(0xFF2196F3),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "${v['marca'] ?? ''} ${v['modelo'] ?? ''}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: Colors.white10),
              _buildVehicleDetail(
                Icons.calendar_today,
                "Año",
                (v['año'] ?? v['anio'] ?? v['year'] ?? '').toString(),
              ),
              _buildVehicleDetail(
                Icons.attach_money,
                "Precio",
                "\$${v['precio'] ?? '0'}",
              ),
              _buildVehicleDetail(
                Icons.local_gas_station,
                "Motor",
                v['combustible'] ?? "Gasolina",
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Funcionalidad disponible en la versión final.",
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3).withOpacity(0.15),
                    foregroundColor: const Color(0xFF2196F3),
                    elevation: 0,
                  ),
                  child: const Text("Ver Ficha Técnica"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white38),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
