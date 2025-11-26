import 'package:flutter_test/flutter_test.dart';
import 'package:movil_surprise/services/auth_service.dart';

void main() {
  group('AuthService – login', () {
    test('debe iniciar sesión con credenciales válidas', () async {
      final auth = AuthService();

      final result = await auth.login(
        'carlos.ramirez@surprise.com',
        'Carlos123!',
      );

      expect(result, true);
    });
  });
}
