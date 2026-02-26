import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  // Keys for secure storage
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _userEmailKey = 'user_email';
  static const String _userPasswordKey = 'user_password';

  /// Check if the device supports biometrics
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } catch (e) {
      print('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Authenticate the user with biometrics
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'Por favor autentícate para acceder',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }

  /// Enable biometric login by saving credentials securely
  Future<void> enableBiometricLogin(String email, String password) async {
    await _storage.write(key: _userEmailKey, value: email);
    await _storage.write(key: _userPasswordKey, value: password);

    // Also store a boolean in SharedPreferences to quickly check if enabled
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
  }

  /// Disable biometric login
  Future<void> disableBiometricLogin() async {
    await _storage.delete(key: _userEmailKey);
    await _storage.delete(key: _userPasswordKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
  }

  /// Check if biometric login is enabled
  Future<bool> isBiometricLoginEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Get stored credentials
  Future<Map<String, String?>> getCredentials() async {
    final email = await _storage.read(key: _userEmailKey);
    final password = await _storage.read(key: _userPasswordKey);
    return {'email': email, 'password': password};
  }
}
