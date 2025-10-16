import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/modelo_card_disciplina.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

class TopicoService {
  static String get _baseUrl {
    if (kIsWeb) {
      return dotenv.env['BASE_URL_WEB']!;
    }
    return dotenv.env['BASE_URL_MOBILE']!;
  }

  static const String _apiPrefix = '/api/cardsDisciplinas';  // Prefixo correto para o backend


  // Criar tópico (APENAS PROFESSOR)
  static Future<TopicoDisciplina> criarTopico(
    String slug,
    String titulo, {
    String? descricao,
  }) async {
    try {
      if (!await AuthService.isProfessor()) {
        throw Exception('Apenas professores podem criar tópicos');
      }

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl$_apiPrefix/$slug/topicos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ADICIONAR HEADER
        },
        body: json.encode({'titulo': titulo, 'descricao': descricao}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TopicoDisciplina.fromJson(data['data']);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception('Apenas professores podem criar tópicos');
      }
      throw Exception('Erro ao criar tópico: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Atualizar tópico (APENAS PROFESSOR)
  static Future<TopicoDisciplina> atualizarTopico(
    String slug,
    String topicoId, {
    String? titulo,
    String? descricao,
    int? ordem,
  }) async {
    try {
      if (!await AuthService.isProfessor()) {
        throw Exception('Apenas professores podem editar tópicos');
      }

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final Map<String, dynamic> body = {};
      if (titulo != null) body['titulo'] = titulo;
      if (descricao != null) body['descricao'] = descricao;
      if (ordem != null) body['ordem'] = ordem;

      final response = await http.put(
        Uri.parse('$_baseUrl$_apiPrefix/$slug/topicos/$topicoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // ADICIONAR HEADER
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TopicoDisciplina.fromJson(data['data']);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception('Apenas professores podem editar tópicos');
      }
      throw Exception('Erro ao atualizar tópico: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Deletar tópico (APENAS PROFESSOR)
  static Future<void> deletarTopico(String slug, String topicoId) async {
    try {
      if (!await AuthService.isProfessor()) {
        throw Exception('Apenas professores podem deletar tópicos');
      }

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl$_apiPrefix/$slug/topicos/$topicoId'),
        headers: {'Authorization': 'Bearer $token'}, // ADICIONAR HEADER
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao deletar tópico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Buscar tópicos (pode ser público)
  static Future<List<TopicoDisciplina>> getTopicosBySlug(String slug) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$_apiPrefix/$slug/topicos'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final topicosJson = data['data'] as List;
          return topicosJson
              .map((json) => TopicoDisciplina.fromJson(json))
              .toList();
        }
      }
      throw Exception('Erro ao carregar tópicos: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }
}