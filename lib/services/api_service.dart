import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Classe para lidar com as chamadas de API que não são de autenticação.
class ApiService {
  static const String _baseUrl = 'https://ecoenergia-api.onrender.com/api';

  // Função privada para obter o token e montar os headers.
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Busca os dados do usuário.
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      return jsonDecode(userData);
    }
    // Retorna um mapa vazio se não encontrar o usuário.
    return {};
  }

  // Busca o resumo de consumo.
  Future<Map<String, dynamic>> getConsumptionSummary() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/consumption/summary'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao carregar o resumo de consumo');
    }
  }

  // Busca os dados da residência.
  Future<Map<String, dynamic>> getResidenceData() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/residence/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao carregar dados da residência');
    }
  }

  // Busca o histórico de consumo para o gráfico.
  Future<List<dynamic>> getConsumptionHistory({String period = '7d'}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/consumption/history?period=$period'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao carregar o histórico de consumo');
    }
  }

  // Busca uma dica aleatória.
  Future<Map<String, dynamic>> getRandomTip() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/tips'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> tips = jsonDecode(response.body);
      if (tips.isNotEmpty) {
        return tips[Random().nextInt(tips.length)];
      }
    }
    return {}; // Retorna um mapa vazio se não houver dicas.
  }

  // Busca a lista de todos os eletrodomésticos.
  Future<List<dynamic>> getAppliances() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/appliances'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      // A API retorna um mapa de categorias, então juntamos todas as listas.
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data.values.expand((list) => list).toList();
    } else {
      throw Exception('Falha ao carregar a lista de eletrodomésticos');
    }
  }

  // NOVO: Busca a lista de todas as dicas.
  Future<List<dynamic>> getTips() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$_baseUrl/tips'),
      headers: headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao carregar as dicas');
    }
  }
}
