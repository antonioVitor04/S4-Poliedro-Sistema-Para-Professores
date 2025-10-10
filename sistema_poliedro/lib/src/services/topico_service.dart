// services/topico_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/modelo_card_disciplina.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TopicoService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://10.2.3.3:5000'; // Direto, sem dotenv
  }

  // Buscar todos os tópicos de uma disciplina
  static Future<List<TopicoDisciplina>> getTopicosBySlug(String slug) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/$slug/topicos'));

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

  // Criar novo tópico
  static Future<TopicoDisciplina> criarTopico(
    String slug,
    String titulo, {
    String? descricao,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$slug/topicos'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'titulo': titulo, 'descricao': descricao}),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TopicoDisciplina.fromJson(data['data']);
        }
      }
      throw Exception('Erro ao criar tópico: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Atualizar tópico
  static Future<TopicoDisciplina> atualizarTopico(
    String slug,
    String topicoId, {
    String? titulo,
    String? descricao,
    int? ordem,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (titulo != null) body['titulo'] = titulo;
      if (descricao != null) body['descricao'] = descricao;
      if (ordem != null) body['ordem'] = ordem;

      final response = await http.put(
        Uri.parse('$_baseUrl/$slug/topicos/$topicoId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return TopicoDisciplina.fromJson(data['data']);
        }
      }
      throw Exception('Erro ao atualizar tópico: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Deletar tópico
  static Future<void> deletarTopico(String slug, String topicoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$slug/topicos/$topicoId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao deletar tópico: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Reordenar tópicos
  static Future<List<TopicoDisciplina>> reordenarTopicos(
    String slug,
    String topicoId,
    int novaOrdem,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/$slug/topicos/$topicoId/reordenar'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'novaOrdem': novaOrdem}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final topicosJson = data['data'] as List;
          return topicosJson
              .map((json) => TopicoDisciplina.fromJson(json))
              .toList();
        }
      }
      throw Exception('Erro ao reordenar tópicos: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }
}
