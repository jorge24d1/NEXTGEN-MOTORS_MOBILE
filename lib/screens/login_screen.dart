import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  final _biometricService = BiometricService();
  bool _isLoading = false;
  bool _canCheckBiometrics = false;
  bool _isBiometricEnabled = false;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<Offset> _subtitleSlideAnimation;
  late Animation<double> _subtitleFadeAnimation;
  late Animation<double> _cardFadeAnimation;
  late Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Animación de entrada del Logo (zoom suave y fade)
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _logoScaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // 1. Título "NextGen Motors": entra deslizándose desde la izquierda (~900ms)
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.2, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
      ),
    );
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // 2. Subtítulo "Bienvenido de Vuelta": entra deslizándose desde el lado contrario (derecha) con retraso escalonado de ~215ms
    _subtitleSlideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.18, 0.95, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.18, 0.7, curve: Curves.easeIn),
      ),
    );

    // 3. Panel de inicio de sesión: entrada suave combinada
    _cardFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeIn),
      ),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheck = await _biometricService.isBiometricAvailable();
    bool isEnabled = await _biometricService.isBiometricLoginEnabled();
    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
        _isBiometricEnabled = isEnabled;
      });
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = await _biometricService.authenticate();
    if (authenticated) {
      setState(() => _isLoading = true);
      final credentials = await _biometricService.getCredentials();
      if (!mounted) return;
      if (credentials['email'] != null && credentials['password'] != null) {
        _emailController.text = credentials['email']!;
        _passwordController.text = credentials['password']!;
        _login(fromBiometric: true);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay credenciales guardadas')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login({bool fromBiometric = false}) async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;

      if (response['success'] == true) {
        if (!fromBiometric && _canCheckBiometrics) {
          await _biometricService.enableBiometricLogin(
            _emailController.text.trim(),
            _passwordController.text,
          );
        }
        await NotificationService().initNotifications();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Credenciales inválidas'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error de conexión: Verifica tu servidor'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF0075FF); // Azul vibrante NextGen
    const Color deepNavyBg = Color(0xFF060913); // Fondo oscuro automotriz

    return Scaffold(
      backgroundColor: deepNavyBg,
      body: Stack(
        children: [
          // 1. Líneas diagonales decorativas (estilo racing deportivo)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _DecorativeStripesPainter(color: primaryColor),
              ),
            ),
          ),

          // 2. Silueta automotriz en la zona inferior
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 270,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.55,
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black],
                      stops: [0.0, 0.4],
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

          // 3. Contenido principal con scroll y centrado
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 390),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo animado con zoom y desvanecimiento
                      ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: FadeTransition(
                          opacity: _logoFadeAnimation,
                          child: Image.asset(
                            'assets/icon/app_icon.png',
                            height: 110,
                            width: 110,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // 1. Título "NextGen Motors" deslizándose desde la izquierda
                      SlideTransition(
                        position: _titleSlideAnimation,
                        child: FadeTransition(
                          opacity: _titleFadeAnimation,
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Manrope',
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'NextGen',
                                  style: TextStyle(color: primaryColor),
                                ),
                                TextSpan(
                                  text: 'Motors',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // 2. Subtítulo "Bienvenido de Vuelta" deslizándose desde la derecha (lado contrario)
                      SlideTransition(
                        position: _subtitleSlideAnimation,
                        child: FadeTransition(
                          opacity: _subtitleFadeAnimation,
                          child: const Text(
                            'Bienvenido de Vuelta',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Panel de inicio de sesión con estilo tarjeta azul y encabezado blanco curvo
                      SlideTransition(
                        position: _cardSlideAnimation,
                        child: FadeTransition(
                          opacity: _cardFadeAnimation,
                          child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF0075FF),
                                Color(0xFF004CB8),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.35),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              // Encabezado blanco con transición curva
                              ClipPath(
                                clipper: const _HeaderClipper(),
                                child: Container(
                                  width: double.infinity,
                                  color: Colors.white,
                                  padding: const EdgeInsets.only(
                                    top: 22,
                                    bottom: 24,
                                    left: 16,
                                    right: 16,
                                  ),
                                  child: Column(
                                    children: const [
                                      Text(
                                        'INICIAR SESIÓN',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Accede a tu cuenta',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Formulario dentro del panel azul
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                                child: Column(
                                  children: [
                                    // Campo Correo electrónico
                                    _buildInputField(
                                      controller: _emailController,
                                      icon: Icons.mail_outline_rounded,
                                      hint: 'Correo electrónico',
                                      keyboardType: TextInputType.emailAddress,
                                      primaryColor: primaryColor,
                                    ),
                                    const SizedBox(height: 16),

                                    // Campo Contraseña
                                    _buildInputField(
                                      controller: _passwordController,
                                      icon: Icons.lock_outline_rounded,
                                      hint: 'Contraseña',
                                      isPassword: _obscurePassword,
                                      primaryColor: primaryColor,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 20),

                                    // Botón INGRESAR
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: primaryColor,
                                          disabledBackgroundColor:
                                              Colors.white.withValues(alpha: 0.7),
                                          elevation: 4,
                                          shadowColor:
                                              Colors.black.withValues(alpha: 0.15),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 22,
                                                height: 22,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: primaryColor,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : const Text(
                                                'INGRESAR',
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                      ),
                                    ),

                                    // Huella digital opcional
                                    if (_canCheckBiometrics) ...[
                                      const SizedBox(height: 16),
                                      IconButton(
                                        icon: Icon(
                                          Icons.fingerprint,
                                          size: 44,
                                          color: _isBiometricEnabled
                                              ? Colors.white
                                              : Colors.white60,
                                        ),
                                        onPressed: _isLoading
                                            ? null
                                            : (_isBiometricEnabled
                                                ? _authenticateWithBiometrics
                                                : () {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Inicia sesión con contraseña para activar la huella',
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color primaryColor,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          prefixIcon: Icon(icon, color: primaryColor, size: 22),
          suffixIcon: suffixIcon,
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}

/// Clipper para crear la transición curva en el encabezado blanco
class _HeaderClipper extends CustomClipper<Path> {
  const _HeaderClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    const double r = 26.0;

    // Esquinas superiores redondeadas
    path.moveTo(0, r);
    path.quadraticBezierTo(0, 0, r, 0);
    path.lineTo(size.width - r, 0);
    path.quadraticBezierTo(size.width, 0, size.width, r);

    // Lado derecho hacia el inicio de la curva
    const double dip = 20.0;
    final double sideY = size.height - dip;
    path.lineTo(size.width, sideY);

    // Curva suave hacia la sección central
    path.cubicTo(
      size.width - 24,
      sideY,
      size.width - 45,
      size.height,
      size.width - 70,
      size.height,
    );

    // Borde horizontal inferior en el centro
    path.lineTo(70, size.height);

    // Curva suave de regreso al lado izquierdo
    path.cubicTo(
      45,
      size.height,
      24,
      sideY,
      0,
      sideY,
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Dibuja las líneas diagonales deportivas en las esquinas
class _DecorativeStripesPainter extends CustomPainter {
  final Color color;

  const _DecorativeStripesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    // Rayas diagonales en la esquina superior izquierda
    canvas.save();
    canvas.translate(-30, 20);
    canvas.rotate(0.785398); // 45 grados

    // Línea 1 (segmentada)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 70, 18),
        const Radius.circular(9),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(88, 0, 110, 18),
        const Radius.circular(9),
      ),
      paint,
    );

    // Línea 2 (paralela)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 30, 210, 18),
        const Radius.circular(9),
      ),
      paint,
    );

    canvas.restore();

    // Franja diagonal sutil en la esquina inferior derecha
    canvas.save();
    canvas.translate(size.width - 20, size.height - 20);
    canvas.rotate(0.785398);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-70, 0, 140, 14),
        const Radius.circular(7),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
