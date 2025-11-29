import 'package:local_auth/local_auth.dart';
import 'package:bridgecore_flutter_starter/core/utils/logger.dart';

/// Biometric authentication service
class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Check if biometric is available
  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      AppLogger.error('Error checking biometric availability: $e');
      return false;
    }
  }

  /// Check if device supports biometric
  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      AppLogger.error('Error checking device support: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      AppLogger.error('Error getting available biometrics: $e');
      return [];
    }
  }

  /// Authenticate with biometric
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      // Check if biometric is available
      final isAvailable = await this.isAvailable();
      if (!isAvailable) {
        AppLogger.warning('Biometric not available');
        return false;
      }

      // Authenticate
      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );

      if (authenticated) {
        AppLogger.info('Biometric authentication successful');
      } else {
        AppLogger.warning('Biometric authentication failed');
      }

      return authenticated;
    } catch (e) {
      AppLogger.error('Error during biometric authentication: $e');
      return false;
    }
  }

  /// Stop authentication
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
      AppLogger.info('Biometric authentication stopped');
    } catch (e) {
      AppLogger.error('Error stopping authentication: $e');
    }
  }

  /// Check if biometric type is supported
  Future<bool> isBiometricTypeSupported(BiometricType type) async {
    final available = await getAvailableBiometrics();
    return available.contains(type);
  }

  /// Get biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Strong Biometric';
      case BiometricType.weak:
        return 'Weak Biometric';
    }
  }
}
