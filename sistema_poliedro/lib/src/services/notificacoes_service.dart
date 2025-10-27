import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service.dart';
import '../models/mensagem_model.dart'; // ← NOVA IMPORT

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return dotenv.env['BASE_URL_WEB']!;
    }
    return dotenv.env['BASE_URL_MOBILE']!;
  }

  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static Future<List<dynamic>> fetchDisciplinas() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/notificacoes/disciplinas-aluno'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success']) {
        return json['disciplinas'];
      } else {
        throw Exception(json['message'] ?? 'Erro ao buscar disciplinas');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token expirado ou inválido');
    } else {
      throw Exception('Erro ao buscar disciplinas: ${response.statusCode}');
    }
  }

  static Future<List<Mensagem>> fetchNotificacoes(String? disciplinaId) async {
    final headers = await AuthService.getAuthHeaders();
    final url = disciplinaId != null
        ? '$baseUrl/api/notificacoes/disciplina/$disciplinaId'
        : '$baseUrl/api/notificacoes/todas';

    final response = await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json['success']) {
        return (json['notificacoes'] as List)
            .map((notif) => Mensagem.fromJson(notif))
            .toList();
      } else {
        throw Exception(json['message'] ?? 'Erro ao buscar notificações');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Token expirado ou inválido');
    } else {
      throw Exception('Erro ao buscar notificações: ${response.statusCode}');
    }
  }

  static Future<void> markAsRead(String notificacaoId) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/notificacoes/$notificacaoId/lida'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erro ao marcar como lida');
    }
  }

  static Future<void> toggleFavorita(
    String notificacaoId,
    bool isFavorita,
  ) async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/notificacoes/$notificacaoId/favorita'),
      headers: headers,
      body: jsonEncode({'isFavorita': isFavorita}),
    );

    if (response.statusCode != 200) {
      final json = jsonDecode(response.body);
      throw Exception(json['message'] ?? 'Erro ao atualizar favorita');
    }
  }
}
