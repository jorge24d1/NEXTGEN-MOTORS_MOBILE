import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mobile_app/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 1. Inicializar Firebase
      await Firebase.initializeApp();

      // 2. Registrar handler (aunque ya se hace en main, aseguramos init)
      // Note: background handler must be top-level, main.dart sets it up generally.

      // 3. Verificar Sesión
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');

      // 4. Init Notificaciones si hay sesión
      if (userId != null) {
        await NotificationService().initNotifications();
      }

      // Pequeño delay artificial para que se vea el logo/loading (opcional, 1.5s)
      await Future.delayed(Duration(milliseconds: 1500));

      // 5. Navegar
      if (userId != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print('Error en Splash: $e');
      // En caso de error crítico, ir a login por seguridad
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // O el color de tu marca
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Aquí podrías poner tu logo: Image.asset('assets/logo.png', width: 150),
            Icon(Icons.directions_car, size: 80, color: Colors.blueAccent),
            SizedBox(height: 20),
            Text(
              "Concesionario App",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 10),
            Text("Cargando...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
