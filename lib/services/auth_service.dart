import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Esta classe será responsável por toda a lógica de autenticação.
class AuthService {
  // A URL base da sua API, como no código React.
  static const String _apiUrl = 'https://ecoenergia-api.onrender.com/api/auth';

  // Função que tenta fazer o login. Retorna true para sucesso, false para falha.
  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      // 200 significa que a requisição foi um sucesso.
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // Salva o token e os dados do usuário no armazenamento local.
        await prefs.setString('token', data['token']);
        await prefs.setString('user', jsonEncode(data['user']));

        return true;
      } else {
        // Se a API retornar um erro (ex: 401 Unauthorized), a função falha.
        return false;
      }
    } catch (e) {
      // Captura erros de conexão com a internet, etc.
      print('Erro na chamada de API: $e');
      return false;
    }
  }

  // NOVO: Função para fazer logout.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Limpa os dados do utilizador do armazenamento local.
    await prefs.remove('token');
    await prefs.remove('user');
  }
}
