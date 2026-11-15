import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const Duration _autoPlayDuration = Duration(seconds: 5);
  static const Color _blue = Color(0xFF0075FF);
  static const Color _deepNavyBg = Color(0xFF060913);

  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Gestión de citas',
      'subtitle': 'Tu taller en la palma de tu mano',
      'description':
          'Agenda revisiones y mantenimientos en segundos y consulta el historial de tu vehículo.',
      'image': 'assets/images/onboarding_citas.png',
      'icon': Icons.calendar_month_rounded,
      'badge': 'Mantenimiento & Taller',
    },
    {
      'title': 'Chat con Dante',
      'subtitle': 'Tu asesor inteligente 24/7',
      'description':
          'Resuelve dudas al instante con Dante, el asistente con IA de NextGen Motors, o con expertos del taller.',
      'image': 'assets/images/onboarding_chat.png',
      'icon': Icons.support_agent_rounded,
      'badge': 'Dante AI',
    },
    {
      'title': 'Acceso biométrico',
      'subtitle': 'Seguro y en un toque',
      'description':
          'Ingresa con tu huella o rostro y mantén protegidos tus datos y los de tus vehículos.',
      'image': 'assets/images/onboarding_biometria.png',
      'icon': Icons.fingerprint_rounded,
      'badge': 'Seguridad',
    },
    {
      'title': 'Alertas al instante',
      'subtitle': 'Siempre al tanto',
      'description':
          'Te avisamos cuando tu auto esté listo, tu cita cambie o toque una revisión preventiva.',
      'image': 'assets/images/onboarding_alertas.png',
      'icon': Icons.notifications_active_rounded,
      'badge': 'Actualizaciones en vivo',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(_autoPlayDuration, (_) => _goToNext());
  }

  void _stopAutoPlay() => _timer?.cancel();

  void _goToNext() {
    if (!mounted || !_pageController.hasClients) return;
    final current = _pageController.page?.round() ?? _currentPage;
    _pageController.animateToPage(
      current + 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _completeOnboarding() async {
    _stopAutoPlay();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepNavyBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: Listener(
                onPointerDown: (_) => _stopAutoPlay(),
                onPointerUp: (_) => _startAutoPlay(),
                onPointerCancel: (_) => _startAutoPlay(),
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index % _features.length);
                    _startAutoPlay(); // reinicia el conteo de 5 s
                  },
                  itemBuilder: (context, index) =>
                      _buildPage(_features[index % _features.length]),
                ),
              ),
            ),
            _buildBottom(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _blue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _blue.withValues(alpha: 0.4)),
            ),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 26,
              height: 26,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.directions_car,
                color: _blue,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'NEXTGEN MOTORS',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta única: imagen de fondo + texto superpuesto sobre degradado.
  Widget _buildPage(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Imagen
            Image.asset(
              item['image'] as String,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      _blue.withValues(alpha: 0.35),
                      const Color(0xFF131826),
                    ],
                  ),
                ),
                child: Align(
                  alignment: const Alignment(0, -0.35),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 84,
                    color: Colors.white38,
                  ),
                ),
              ),
            ),

            // Degradado que "funde" la imagen con el texto
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _deepNavyBg.withValues(alpha: 0.55),
                    _deepNavyBg.withValues(alpha: 0.95),
                  ],
                  stops: const [0.35, 0.65, 1.0],
                ),
              ),
            ),

            // Badge arriba
            Positioned(top: 16, left: 16, child: _buildBadge(item)),

            // Texto abajo, dentro de la misma tarjeta
            Positioned(
              left: 22,
              right: 22,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['subtitle'] as String,
                    style: const TextStyle(
                      color: Color(0xFF5AA2FF),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['description'] as String,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _deepNavyBg.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _blue.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(item['icon'] as IconData, size: 14, color: _blue),
          const SizedBox(width: 6),
          Text(
            item['badge'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Puntos indicadores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_features.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? _blue : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                elevation: 6,
                shadowColor: _blue.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Iniciar sesión',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}