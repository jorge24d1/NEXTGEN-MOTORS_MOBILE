import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';

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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mensaje de bienvenida inicial
    _addMessage(
      "¡Hola! Soy Dante 🤖, tu asesor experto de NextGen Motors. ¿Qué tipo de vehículo estás buscando hoy?",
      false,
    );
  }

  void _addMessage(String text, bool isUser, {Map<String, dynamic>? vehicle}) {
    setState(() {
      _messages.add({"text": text, "isUser": isUser, "vehicle": vehicle});
    });
    // Scroll al fondo
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    _addMessage(text, true);

    setState(() => _isLoading = true);

    try {
      final response = await _apiService.obtenerRecomendacion(text);
      final botReply = response['textoRespuesta'] ?? "Lo siento, no entendí.";
      final vehicles = response['vehiculosRecomendados'] as List<dynamic>?;

      Map<String, dynamic>? vehicleData;
      if (vehicles != null && vehicles.isNotEmpty) {
        vehicleData = vehicles.first;
      }

      _addMessage(botReply, false, vehicle: vehicleData);
    } catch (e) {
      _addMessage(
        "Lo siento, tuve un problema de conexión. Inténtalo de nuevo.",
        false,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        title: const Text('Asistente Dante AI'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'];
                final vehicle = msg['vehicle'];

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
                        children: [
                          if (!isUser)
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
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
                                    : colorScheme.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20),
                                  topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                                  bottomRight: Radius.circular(isUser ? 4 : 20),
                                ),
                                boxShadow: [
                                  if (!isUser)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Text(
                                msg['text'],
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: isUser ? Colors.white : Colors.white,
                                  fontSize: 15,
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
        color: colorScheme.background,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Pregúntale a Dante...',
                  hintStyle: const TextStyle(color: Colors.white30),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
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
                      "${v['marca']} ${v['modelo']}",
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
                v['año'].toString(),
              ),
              _buildVehicleDetail(
                Icons.attach_money,
                "Precio",
                "\$${v['precio']}",
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
