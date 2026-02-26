import 'package:flutter/material.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/services/notification_service.dart';
import 'package:mobile_app/services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
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
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheck = await _biometricService.isBiometricAvailable();
    bool isEnabled = await _biometricService.isBiometricLoginEnabled();
    print('Biometric Debug: Can Check = $canCheck, Is Enabled = $isEnabled');
    setState(() {
      _canCheckBiometrics = canCheck;
      _isBiometricEnabled = isEnabled;
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    bool authenticated = await _biometricService.authenticate();
    if (authenticated) {
      setState(() => _isLoading = true);
      final credentials = await _biometricService.getCredentials();
      if (credentials['email'] != null && credentials['password'] != null) {
        _emailController.text = credentials['email']!;
        _passwordController.text = credentials['password']!;
        _login(fromBiometric: true);
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No hay credenciales guardadas')),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _login({bool fromBiometric = false}) async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor llena todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if (response['success'] == true) {
        if (!fromBiometric && _canCheckBiometrics) {
          await _biometricService.enableBiometricLogin(
            _emailController.text,
            _passwordController.text,
          );
        }
        await NotificationService().initNotifications();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Credenciales inválidas'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de conexión: Verifica tu servidor'),
        ), // Mensaje user-friendly
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores extraídos del login.html
    final Color primaryColor = Color(0xFF0F66BD);
    final Color darkBlue = Color(0xFF1E40AF);

    return Scaffold(
      backgroundColor: Color(0xFFF6F7F8), // background-light
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_car_filled,
                      size: 80,
                      color: primaryColor,
                    ),
                    SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily:
                              'Manrope', // Fallback to default if not added
                        ),
                        children: [
                          TextSpan(
                            text: 'NextGen',
                            style: TextStyle(color: primaryColor),
                          ),
                          TextSpan(
                            text: 'Motors',
                            style: TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Bienvenido de Vuelta',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),

              // Form Card
              Card(
                elevation: 10,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, darkBlue],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'INICIAR SESIÓN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Accede a tu cuenta',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hint: 'Correo electrónico',
                            primaryColor: primaryColor,
                          ),
                          SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: 'Contraseña',
                            isPassword: true,
                            primaryColor: primaryColor,
                          ),
                          SizedBox(height: 30),

                          _isLoading
                              ? CircularProgressIndicator(color: primaryColor)
                              : SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 5,
                                    ),
                                    child: Text(
                                      'INGRESAR',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),

                          SizedBox(height: 20),

                          SizedBox(height: 20),
                          if (_canCheckBiometrics)
                            IconButton(
                              icon: Icon(
                                Icons.fingerprint,
                                size: 50,
                                color: _isBiometricEnabled
                                    ? primaryColor
                                    : Colors.grey,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : (_isBiometricEnabled
                                        ? _authenticateWithBiometrics
                                        : () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Inicia sesión con contraseña para activar la huella',
                                                ),
                                              ),
                                            );
                                          }),
                            ),
                          SizedBox(height: 20),
                          Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required Color primaryColor,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.7)),
        hintText: hint,
        filled: true,
        fillColor: Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
