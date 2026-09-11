import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();

      return canCheck || supported;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    try {
      if (!await isAvailable()) {
        return false;
      }

      return await _auth.authenticate(
        localizedReason:
            'Use your fingerprint, Face ID or phone lock to open the BCA Department App.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
