import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_app/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
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

    String targetRoute = '/login';

    try {
      // 1. Inicializar Firebase si aún no está inicializado
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      // 2. Verificar Sesión
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // 3. Init Notificaciones si hay sesión
      if (userId != null) {
        try {
          await NotificationService().initNotifications();
        } catch (e) {
          print('Aviso en notificaciones: $e');
        }
        targetRoute = '/home';
      }
    } catch (e) {
      print('Aviso en Splash: $e');
      targetRoute = '/login';
    } finally {
      // Esperar siempre el tiempo mínimo para apreciar la animación
      await minDisplayTime;

      if (mounted) {
        Navigator.pushReplacementNamed(context, targetRoute);
      }
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
