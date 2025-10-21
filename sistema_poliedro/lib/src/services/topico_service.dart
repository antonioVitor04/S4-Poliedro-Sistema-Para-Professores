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

  static const String _apiPrefix = '/api/cardsDisciplinas';

  // Criar tópico (APENAS PROFESSOR DA DISCIPLINA OU ADMIN)
  // CORREÇÃO: Remover verificação duplicada - deixar o backend decidir
  static Future<TopicoDisciplina> criarTopico(
    String slug,
    String titulo, {
    String? descricao,
  }) async {
    try {
      print('=== DEBUG TopicoService: Iniciando criação de tópico ===');
      print('=== DEBUG: Slug: $slug ===');

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      // CORREÇÃO: Remover verificação de role aqui - deixar o backend decidir
      // O middleware verificarProfessorDisciplina já faz essa verificação

      final response = await http.post(
        Uri.parse('$_baseUrl$_apiPrefix/$slug/topicos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'titulo': titulo, 
          'descricao': descricao
        }),
      );

      print('=== DEBUG: Status Code: ${response.statusCode} ===');
      print('=== DEBUG: Response Body: ${response.body} ===');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TopicoDisciplina.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Erro desconhecido ao criar tópico');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        // CORREÇÃO: Mensagem mais específica
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Acesso negado. Verifique suas permissões.');
      } else if (response.statusCode == 404) {
        throw Exception('Disciplina não encontrada');
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('=== DEBUG ERRO TopicoService.criarTopico: $e ===');
      rethrow;
    }
  }

  // Atualizar tópico (APENAS PROFESSOR DA DISCIPLINA OU ADMIN)
  static Future<TopicoDisciplina> atualizarTopico(
    String slug,
    String topicoId, {
    String? titulo,
    String? descricao,
    int? ordem,
  }) async {
    try {
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
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TopicoDisciplina.fromJson(data['data']);
        }
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        final data = json.decode(response.body);
        throw Exception(data['error'] ?? 'Acesso negado. Verifique suas permissões.');
      }
      throw Exception('Erro ao atualizar tópico: ${response.statusCode}');
    } catch (e) {
      print('=== DEBUG ERRO TopicoService.atualizarTopico: $e ===');
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Deletar tópico (APENAS PROFESSOR DA DISCIPLINA OU ADMIN)
  static Future<void> deletarTopico(String slug, String topicoId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl$_apiPrefix/$slug/topicos/$topicoId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode != 200) {
        throw Exception('Erro ao deletar tópico: ${response.statusCode}');
      }
    } catch (e) {
      print('=== DEBUG ERRO TopicoService.deletarTopico: $e ===');
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Buscar tópicos (com autenticação)
  static Future<List<TopicoDisciplina>> getTopicosBySlug(String slug) async {
    try {
      final token = await AuthService.getToken();
      final headers = <String, String>{};

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl$_apiPrefix/$slug/topicos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final topicosJson = data['data'] as List;
          return topicosJson
              .map((json) => TopicoDisciplina.fromJson(json))
              .toList();
        }
      } else if (response.statusCode == 403) {
        throw Exception('Acesso negado a esta disciplina');
      }
      throw Exception('Erro ao carregar tópicos: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }
}