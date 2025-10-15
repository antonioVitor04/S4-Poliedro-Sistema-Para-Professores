import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static String get baseUrl {
    // MUDANÇA: Tornar público para uso externo
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://192.168.15.123:5000'; // Direto, sem dotenv
  }

  static Future<String?> login(
    String identifier,
    String senha,
    String tipo,
  ) async {
    final rota = tipo == "professor" ? "professores" : "alunos";
    final url = Uri.parse("${baseUrl}/api/$rota/login");
    final body = tipo == "professor"
        ? {"email": identifier, "senha": senha}
        : {"ra": identifier, "senha": senha};

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', token);
        await prefs.setString('tipoUsuario', tipo);

        return token;
      } else {
        throw Exception("Erro no login");
      }
    } catch (e) {
      throw Exception("Erro na requisição: $e");
    }
  }

  static Future<bool> sendVerificationCode(String email) async {
    final url = Uri.parse("${baseUrl}/api/enviarEmail/enviar-codigo");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? "Erro ao enviar código");
      }
    } catch (e) {
      throw Exception("Erro de conexão: $e");
    }
  }

  static Future<bool> verifyCode(String email, String codigo) async {
    final url = Uri.parse("${baseUrl}/api/enviarEmail/verificar-codigo");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'codigo': codigo}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Código inválido');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<bool> updatePassword(
    String email,
    String codigo,
    String novaSenha,
  ) async {
    final url = Uri.parse("${baseUrl}/api/recuperarSenha/atualizar-senha");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'codigo': codigo,
          'novaSenha': novaSenha,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Erro ao atualizar senha');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // ADICIONE ESTE MÉTODO - getUserType
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("tipoUsuario");
  }

  // ADICIONE ESTE MÉTODO - isProfessor
  static Future<bool> isProfessor() async {
    final tipo = await getUserType();
    return tipo == "professor";
  }

  // ADICIONE ESTE MÉTODO - getAuthHeaders
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
