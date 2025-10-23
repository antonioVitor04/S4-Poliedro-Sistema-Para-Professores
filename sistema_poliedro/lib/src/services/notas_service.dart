import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class NotasService {
  static String get baseUrl {
    if (kIsWeb) {
      // Para web
      return dotenv.get('BASE_URL_WEB', fallback: 'http://localhost:5000');
    } else {
      // Para mobile - detecta se é emulador ou dispositivo físico
      final bool isEmulator =
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS;

      if (isEmulator) {
        return dotenv.get('BASE_URL_MOBILE', fallback: 'http://10.0.2.2:5000');
      } else {
        return dotenv.get('BASE_URL_MOBILE', fallback: 'http://localhost:5000');
      }
    }
  }

  final String token;

  NotasService(this.token);

  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Método auxiliar para tratar URLs
  String _buildUrl(String endpoint) {
    // Remove barras duplicadas
    final normalizedBaseUrl = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final normalizedEndpoint = endpoint.startsWith('/')
        ? endpoint
        : '/$endpoint';

    return '$normalizedBaseUrl$normalizedEndpoint';
  }

  // GET: Buscar notas do aluno
  Future<List<dynamic>> getNotasAluno() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(_buildUrl('/api/notas/aluno/minhas-notas')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Falha ao carregar notas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // GET: Buscar notas por disciplina (para professores)
  Future<List<dynamic>> getNotasPorDisciplina(String disciplinaId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(_buildUrl('/api/notas/$disciplinaId')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Falha ao carregar notas: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // POST: Criar nova nota
  Future<dynamic> criarNota(Map<String, dynamic> notaData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(_buildUrl('/api/notas')),
        headers: headers,
        body: json.encode(notaData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Falha ao criar nota');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // PUT: Atualizar nota
  Future<dynamic> atualizarNota(
    String id,
    Map<String, dynamic> notaData,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(_buildUrl('/api/notas/$id')),
        headers: headers,
        body: json.encode(notaData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Falha ao atualizar nota');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // DELETE: Deletar nota
  Future<void> deletarNota(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(_buildUrl('/api/notas/$id')),
        headers: headers,
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Falha ao deletar nota');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Método para debug - verificar configuração
  static void debugConfig() {
    if (kDebugMode) {
      print('=== NotasService Configuration ===');
      print('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      print('Base URL: $baseUrl');
      print(
        'BASE_URL_WEB: ${dotenv.get('BASE_URL_WEB', fallback: 'Not found')}',
      );
      print(
        'BASE_URL_MOBILE: ${dotenv.get('BASE_URL_MOBILE', fallback: 'Not found')}',
      );
      print('==================================');
    }
  }
}
