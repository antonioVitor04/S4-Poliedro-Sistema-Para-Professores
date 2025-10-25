import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  static String get baseUrl {
    if (kIsWeb) {
      return dotenv.env['BASE_URL_WEB']!;
    }
    return dotenv.env['BASE_URL_MOBILE']!;
  }

  static Future<String?> login(
    String identifier,
    String senha,
    String tipo,
  ) async {
    final rota = tipo == "professor" ? "professores" : "alunos";
    final url = Uri.parse("$baseUrl/api/$rota/login");
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

        String finalUserType = tipo;
        final userData = data['professor'] ?? data['aluno'] ?? data['user'];
        if (userData != null && userData['tipo'] != null) {
          finalUserType = userData['tipo'].toString();
        } else if (token != null) {
          try {
            final parts = token.split('.');
            if (parts.length == 3) {
              String payload = parts[1];
              while (payload.length % 4 != 0) {
                payload += '=';
              }
              final decoded = utf8.decode(base64.decode(payload));
              final payloadMap = json.decode(decoded);
              final tokenRole = payloadMap['role']?.toString();
              if (tokenRole != null) {
                finalUserType = tokenRole;
              }
            }
          } catch (e) {
            print('Erro ao decodificar token: $e');
          }
        }

        await prefs.setString('tipoUsuario', finalUserType);
        return token;
      } else {
        throw Exception("Erro no login: ${response.body}");
      }
    } catch (e) {
      throw Exception("Erro na requisição: $e");
    }
  }

  static Future<bool> sendVerificationCode(String email) async {
    final url = Uri.parse("$baseUrl/api/enviarEmail/enviar-codigo");
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
    final url = Uri.parse("$baseUrl/api/enviarEmail/verificar-codigo");
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
    final url = Uri.parse("$baseUrl/api/recuperarSenha/atualizar-senha");
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
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("token");
    } catch (e) {
      print('Erro ao obter token: $e');
      return null;
    }
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("tipoUsuario");
  }

  static Future<bool> isProfessor() async {
    final tipo = await getUserType();
    return tipo == "professor";
  }

  static Future<bool> isAdmin() async {
    final tipo = await getUserType();
    return tipo == "admin";
  }

  static Future<bool> isAluno() async {
    final tipo = await getUserType();
    return tipo == "aluno";
  }

  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> getUserId() async {
    final token = await getToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) return null;
        String payload = parts[1];
        while (payload.length % 4 != 0) {
          payload += '=';
        }
        final decoded = utf8.decode(base64.decode(payload));
        final payloadMap = json.decode(decoded);
        return payloadMap['id']?.toString() ?? payloadMap['sub']?.toString();
      } catch (e) {
        print('Erro ao decodificar token: $e');
        return null;
      }
    }
    return null;
  }

  static Future<String?> getUserRole() async {
    final token = await getToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) return null;
        String payload = parts[1];
        while (payload.length % 4 != 0) {
          payload += '=';
        }
        final decoded = utf8.decode(base64.decode(payload));
        final payloadMap = json.decode(decoded);
        return payloadMap['role']?.toString();
      } catch (e) {
        print('Erro ao obter role: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<void> debugToken() async {
    final token = await getToken();
    if (token != null) {
      print('=== DEBUG TOKEN ===');
      print('Token: $token');
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          String payload = parts[1];
          while (payload.length % 4 != 0) {
            payload += '=';
          }
          final decoded = utf8.decode(base64.decode(payload));
          print('Payload: $decoded');
        }
      } catch (e) {
        print('Erro no debug: $e');
      }
    } else {
      print('Token não encontrado');
    }
  }
}
