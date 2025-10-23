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

        String finalUserType = tipo; // default para o tipo passado

        // Tentar 1: Verificar se tem tipo na resposta
        final userData = data['professor'] ?? data['aluno'] ?? data['user'];
        if (userData != null && userData['tipo'] != null) {
          finalUserType = userData['tipo'].toString();
          print('=== DEBUG: Tipo da resposta: $finalUserType ===');
        }
        // Tentar 2: Verificar role no token (prioridade máxima)
        else if (token != null) {
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
                print('=== DEBUG: Role do token: $finalUserType ===');
              }
            }
          } catch (e) {
            print('Erro ao decodificar token: $e');
          }
        }

        // Salvar o tipo final
        await prefs.setString('tipoUsuario', finalUserType);
        print('=== DEBUG: Tipo final salvo: $finalUserType ===');

        return token;
      } else {
        throw Exception("Erro no login");
      }
    } catch (e) {
      throw Exception("Erro na requisição: $e");
    }
  }

  // NOVO MÉTODO: Debug completo do usuário
  static Future<void> debugUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final tipo = prefs.getString('tipoUsuario');

    print('=== DEBUG USER INFO ===');
    print('Token: $token');
    print('Tipo salvo: $tipo');

    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length == 3) {
          String payload = parts[1];
          while (payload.length % 4 != 0) {
            payload += '=';
          }
          final decoded = utf8.decode(base64.decode(payload));
          print('Payload do token: $decoded');
        }
      } catch (e) {
        print('Erro no debug do token: $e');
      }
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
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("token");
    } catch (e) {
      print('Erro ao obter token: $e');
      return null;
    }
  }

  // Método adicional para verificar se está autenticado
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
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

  // Adicione estes métodos à classe AuthService existente

  // Verificar se é admin
  static Future<bool> isAdmin() async {
    final tipo = await getUserType();
    return tipo == "admin";
  }

  // Verificar se é aluno
  static Future<bool> isAluno() async {
    final tipo = await getUserType();
    return tipo == "aluno";
  }

  // CORREÇÃO: Método getUserId
  static Future<String?> getUserId() async {
    final token = await getToken();
    if (token != null) {
      try {
        print('=== DEBUG getUserId ===');
        print('Token completo: $token');

        final parts = token.split('.');
        if (parts.length != 3) {
          print('Token não tem 3 partes');
          return null;
        }

        final payload = parts[1];
        // Adicionar padding se necessário
        String normalized = payload;
        while (normalized.length % 4 != 0) {
          normalized += '=';
        }

        final decoded = utf8.decode(base64.decode(normalized));
        final payloadMap = json.decode(decoded);

        print('Payload decodificado: $payloadMap');

        // Tentar diferentes campos possíveis
        final userId =
            payloadMap['id'] ?? payloadMap['userId'] ?? payloadMap['sub'];
        print('User ID encontrado: $userId');

        return userId?.toString();
      } catch (e) {
        print('Erro ao decodificar token: $e');
        return null;
      }
    }
    return null;
  }

  // NOVO MÉTODO: Debug do token
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

  // NOVO MÉTODO: Obter role do token
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
}
