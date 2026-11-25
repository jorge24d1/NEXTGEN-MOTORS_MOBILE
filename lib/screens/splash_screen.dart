import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/sesion_movil.dart';
import 'panel_movil.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _animationController.forward();
    _initializeApp();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/icon/app_icon.png'), context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Garantiza que la animación del logo sea visible durante al menos 2.5 segundos
    final minDisplayTime = Future.delayed(const Duration(milliseconds: 2500));

    SesionMovil? sesion;
    String targetRoute = '/login';
    try {
      sesion = await ApiService().restaurar();
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('userId')) {
        targetRoute = '/welcome';
      }
    } catch (_) {
      targetRoute = '/login';
    }
    await minDisplayTime;
    if (!mounted) return;
    final activa = sesion;
    if (activa != null && activa.vigente) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => PanelMovil(activa)));
    } else {
      Navigator.pushReplacementNamed(context, targetRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/icon/app_icon.png',
                  width: 170,
                  height: 170,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.directions_car,
                      size: 90,
                      color: Colors.blueAccent,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "NextGen Motors",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 10),
            const Text("Cargando...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
