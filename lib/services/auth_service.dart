import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  Future<bool> login(String email, String password) async {
    final url = Uri.parse("http://localhost:4000/api/mobile/auth/login");

    final response = await http.post(url, body: {
      "email": email,
      "password": password,
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data.containsKey('token');
    } else {
      return false;
    }
  }
}
