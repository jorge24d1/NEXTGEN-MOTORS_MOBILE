import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _features = [
    {
      'title': 'Gestión Integral de Citas',
      'subtitle': 'Tu concesionario en la palma de tu mano',
      'description':
          'Agenda tus revisiones mecánicas y servicios de mantenimiento en segundos. Consulta horarios disponibles, confirma tu cita y revisa el historial detallado de tu vehículo sin esperas.',
      'icon': Icons.calendar_month_rounded,
      'badge': 'Mantenimiento & Taller',
      'accentColor': const Color(0xFF0075FF),
      'bullets': [
        'Reserva de citas técnica inmediata',
        'Seguimiento del estado de tu vehículo',
        'Historial completo de intervenciones',
      ],
    },
    {
      'title': 'Asistencia y Chat en Vivo',
      'subtitle': 'Comunicación directa con expertos',
      'description':
          '¿Tienes dudas sobre el diagnóstico o necesitas orientación mecánica? Conéctate mediante nuestro chat con asesores de taller y el asistente inteligente de NextGen Motors.',
      'icon': Icons.support_agent_rounded,
      'badge': 'Soporte Inteligente',
      'accentColor': const Color(0xFF00C6FF),
      'bullets': [
        'Canal directo con jefes de taller',
        'Respuestas automotrices en tiempo real',
        'Interacción rápida y personalizada',
      ],
    },
    {
      'title': 'Acceso Biométrico Seguro',
      'subtitle': 'Seguridad avanzada y acceso express',
      'description':
          'Ingresa a tu cuenta en un instante utilizando tu huella digital o reconocimiento facial. Máxima protección para tus datos personales y los registros de tus vehículos.',
      'icon': Icons.fingerprint_rounded,
      'badge': 'Seguridad de Última Generación',
      'accentColor': const Color(0xFF00E676),
      'bullets': [
        'Desbloqueo biométrico instantáneo',
        'Cifrado seguro de credenciales',
        'Protección total de tu privacidad',
      ],
    },
    {
      'title': 'Alertas y Notificaciones',
      'subtitle': 'Siempre al tanto de lo que importa',
      'description':
          'Recibe notificaciones automáticas cuando tu auto esté listo para recoger, cuando tu cita sea confirmada o reprogramada, y avisos de revisiones preventivas periódicas.',
      'icon': Icons.notifications_active_rounded,
      'badge': 'Actualizaciones en Vivo',
      'accentColor': const Color(0xFFFF9100),
      'bullets': [
        'Avisos de cambio de estado de tu servicio',
        'Recordatorios de citas agendadas',
        'Promociones exclusivas del concesionario',
      ],
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color deepNavyBg = Color(0xFF060913);
    const Color cardBg = Color(0xFF131826);

    return Scaffold(
      backgroundColor: deepNavyBg,
      body: Stack(
        children: [
          // Fondo decorativo con silueta de automóvil sutil
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 260,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.25,
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.0, 0.5],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: Image.asset(
                    'assets/images/car_silhouette.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Barra superior: Logo + Nombre + Botón Omitir
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0075FF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF0075FF).withValues(alpha: 0.4),
                          ),
                        ),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 26,
                          height: 26,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.directions_car,
                            color: Color(0xFF0075FF),
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
                      const Spacer(),
                      TextButton(
                        onPressed: _completeOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Omitir',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.arrow_forward_ios, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Carrusel de Funcionalidades (PageView)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _features.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final item = _features[index];
                      final Color accentColor = item['accentColor'] as Color;
                      final List<String> bullets =
                          item['bullets'] as List<String>;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 10.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            // Badge decorativo
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    size: 14,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    item['badge'] as String,
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Ícono principal con resplandor
                            Center(
                              child: Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      accentColor.withValues(alpha: 0.25),
                                      Colors.transparent,
                                    ],
                                  ),
                                  border: Border.all(
                                    color: accentColor.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accentColor.withValues(alpha: 0.25),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  item['icon'] as IconData,
                                  size: 54,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Título y Subtítulo
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['subtitle'] as String,
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Descripción
                            Text(
                              item['description'] as String,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 14.5,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Tarjeta con viñetas/beneficios
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Column(
                                children: bullets.map((bullet) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: accentColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            bullet,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Parte inferior: Indicador de puntos + Botón "Accede a nuestras funciones"
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Indicadores de páginas (Dots)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_features.length, (index) {
                          final bool isSelected = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isSelected ? 28 : 8,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0075FF)
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(3),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0075FF)
                                            .withValues(alpha: 0.5),
                                        blurRadius: 8,
                                      )
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),

                      // Botón principal: "Accede a nuestras funciones"
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF0052D4),
                                Color(0xFF0075FF),
                                Color(0xFF00C6FF),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF0075FF).withValues(alpha: 0.4),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _completeOnboarding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Accede a nuestras funciones',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

