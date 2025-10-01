// services/material_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/modelo_card_disciplina.dart';
import 'package:file_picker/file_picker.dart'; 
class MaterialService {
  static const String baseUrl = 'http://localhost:5000/api/cardsDisciplinas';

  // Criar material COM arquivo
  static Future<MaterialDisciplina> criarMaterial({
    required String slug,
    required String topicoId,
    required String tipo,
    required String titulo,
    String? descricao,
    String? url,
    double peso = 0,
    DateTime? prazo,
    PlatformFile? arquivo,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$slug/topicos/$topicoId/materiais'),
      );

      // Adicionar campos de texto
      request.fields['tipo'] = tipo;
      request.fields['titulo'] = titulo;
      if (descricao != null) request.fields['descricao'] = descricao;
      if (url != null) request.fields['url'] = url;
      request.fields['peso'] = peso.toString();
      if (prazo != null) request.fields['prazo'] = prazo.toIso8601String();

      // Adicionar arquivo se existir
      if (arquivo != null && arquivo.bytes != null) {
        final file = http.MultipartFile.fromBytes(
          'arquivo',
          arquivo.bytes!,
          filename: arquivo.name,
          contentType: _getMediaType(arquivo.name),
        );
        request.files.add(file);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          return MaterialDisciplina.fromJson(data['data']);
        }
      }
      
      throw Exception('Erro ao criar material: ${response.statusCode} - $responseBody');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Helper para determinar o tipo MIME
  static MediaType _getMediaType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // Resto dos métodos permanecem iguais...
  static Future<MaterialDisciplina> atualizarMaterial({
    required String slug,
    required String topicoId,
    required String materialId,
    String? tipo,
    String? titulo,
    String? descricao,
    String? url,
    double? peso,
    DateTime? prazo,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (tipo != null) body['tipo'] = tipo;
      if (titulo != null) body['titulo'] = titulo;
      if (descricao != null) body['descricao'] = descricao;
      if (url != null) body['url'] = url;
      if (peso != null) body['peso'] = peso;
      if (prazo != null) body['prazo'] = prazo.toIso8601String();

      final response = await http.put(
        Uri.parse('$baseUrl/$slug/topicos/$topicoId/materiais/$materialId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return MaterialDisciplina.fromJson(data['data']);
        }
      }
      throw Exception('Erro ao atualizar material: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  static Future<void> deletarMaterial({
    required String slug,
    required String topicoId,
    required String materialId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$slug/topicos/$topicoId/materiais/$materialId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao deletar material: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }
}