import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/services/cache_service.dart';
import 'package:mobile_app/screens/chat_screen.dart';
import 'package:mobile_app/screens/appointment_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/l10n/app_localizations.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  List<dynamic> _citas = [];
  bool _isLoading = true;
  bool _isOffline = false; // Indica si los datos vienen del caché
  String _nombreUsuario = "Usuario";
  String? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return 'Por confirmar';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat("d MMM yyyy '•' h:mm a").format(dt);
    } catch (_) {
      return raw;
    }
  }

  String _formatSyncTime(String? isoTime) {
    if (isoTime == null) return '';
    try {
      final dt = DateTime.parse(isoTime);
      return DateFormat("d MMM, h:mm a").format(dt);
    } catch (_) {
      return '';
    }
  }

  Future<void> _cargarCitas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final nombreGuardado = prefs.getString('nombre') ?? "Usuario";

      // Intentar cargar desde API (getCitas() ahora devuelve caché si falla)
      final citas = await _apiService.getCitas();

      // Obtener fecha de la última sincronización
      final timestamp = await CacheService.getCitasCacheTimestamp();

      if (!mounted) return;
      setState(() {
        _nombreUsuario = nombreGuardado;
        _citas = citas;
        _isLoading = false;
        _isOffline = false;
        _lastSyncTime = timestamp;
      });
    } catch (e) {
      // Si falla completamente, cargar desde caché directamente
      final cachedCitas = await CacheService.getCachedCitas();
      final prefs = await SharedPreferences.getInstance();
      final nombreGuardado = prefs.getString('nombre') ?? "Usuario";
      final timestamp = await CacheService.getCitasCacheTimestamp();

      if (!mounted) return;
      setState(() {
        _nombreUsuario = nombreGuardado;
        _citas = cachedCitas;
        _isLoading = false;
        _isOffline = true;
        _lastSyncTime = timestamp;
      });

      if (cachedCitas.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sin conexión y sin datos guardados'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargarCitas,
                child: CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    // Banner offline
                    if (_isOffline)
                      SliverToBoxAdapter(child: _buildOfflineBanner()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWelcomeHeader(),
                            const SizedBox(height: 24),
                            _buildNextAppointmentCard(),
                            const SizedBox(height: 32),
                            Text(
                              AppLocalizations.of(context).yourActivities,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final cita = _citas[index];
                        return _buildCitaItem(cita);
                      }, childCount: _citas.length),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        label: const Text('Asistente Dante'),
        icon: const Icon(Icons.auto_awesome),
        backgroundColor: const Color(0xFF2196F3),
      ),
    );
  }

  /// Banner que se muestra cuando los datos vienen del caché (sin conexión)
  Widget _buildOfflineBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade800.withOpacity(0.9),
            Colors.orange.shade900.withOpacity(0.9),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Modo sin conexión',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                if (_lastSyncTime != null)
                  Text(
                    'Última actualización: ${_formatSyncTime(_lastSyncTime)}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            onPressed: () {
              setState(() => _isLoading = true);
              _cargarCitas();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F1219),
      title: const Text("NEXTGEN MOTORS"),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_rounded, color: Colors.white70),
          onPressed: () => Navigator.pushNamed(context, '/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white70),
          onPressed: _cerrarSesion,
        ),
      ],
    );
  }

  Future<void> _cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    // Limpiar únicamente las credenciales de sesión activa
    await prefs.remove('userId');
    await prefs.remove('nombre');
    await prefs.remove('role');
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildWelcomeHeader() {
    final loc = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.hello,
          style: const TextStyle(color: Colors.white54, fontSize: 16),
        ),
        Text(
          _nombreUsuario,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNextAppointmentCard() {
    if (_citas.isEmpty) return const SizedBox.shrink();

    final proximaCita = _citas.first;
    final estado = proximaCita['estado'] ?? 'Pendiente';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AppointmentDetailsScreen(appointment: proximaCita),
          ),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "PRÓXIMA CITA",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                Row(
                  children: [
                    if (_isOffline)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'CACHÉ',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const Icon(
                      Icons.calendar_month,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              proximaCita['vehiculo'] ?? "Mantenimiento General",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatDate(proximaCita['fechaAsignada']),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                estado.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCitaItem(Map<String, dynamic> cita) {
    final estado = cita['estado'] ?? 'Pendiente';
    Color statusColor = Colors.orange;
    if (estado == 'Aprobada') statusColor = Colors.greenAccent;
    if (estado == 'Rechazada') statusColor = Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppointmentDetailsScreen(appointment: cita),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1219),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.build_circle_outlined,
                  color: Color(0xFF2196F3),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita['vehiculo'] ?? "Vehículo",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(cita['fechaSolicitud']),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
