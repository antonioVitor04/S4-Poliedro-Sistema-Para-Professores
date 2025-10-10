// services/material_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../models/modelo_card_disciplina.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MaterialService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://10.2.3.3:5000'; // Direto, sem dotenv
  }

  // POST: Adicionar material a um tópico
  static Future<void> criarMaterial({
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
        Uri.parse('$_baseUrl/$slug/topicos/$topicoId/materiais'),
      );

      request.fields['tipo'] = tipo;
      request.fields['titulo'] = titulo;
      if (descricao != null) request.fields['descricao'] = descricao;
      if (url != null) request.fields['url'] = url;
      request.fields['peso'] = peso.toString();
      if (prazo != null) request.fields['prazo'] = prazo.toIso8601String();

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

      if (response.statusCode != 201) {
        throw Exception('Erro ao criar material: $responseBody');
      }
    } catch (e) {
      throw Exception('Erro ao criar material: $e');
    }
  }

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

  // PUT: Atualizar material
  static Future<void> atualizarMaterial({
    required String slug,
    required String topicoId,
    required String materialId,
    String? tipo,
    String? titulo,
    String? descricao,
    String? url,
    double? peso,
    DateTime? prazo,
    PlatformFile? arquivo,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl/$slug/topicos/$topicoId/materiais/$materialId'),
      );

      if (tipo != null) request.fields['tipo'] = tipo;
      if (titulo != null) request.fields['titulo'] = titulo;
      if (descricao != null) request.fields['descricao'] = descricao;
      if (url != null) request.fields['url'] = url;
      if (peso != null) request.fields['peso'] = peso.toString();
      if (prazo != null) request.fields['prazo'] = prazo.toIso8601String();

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

      if (response.statusCode != 200) {
        throw Exception('Erro ao atualizar material: $responseBody');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar material: $e');
    }
  }

  // DELETE: Deletar material
  static Future<void> deletarMaterial({
    required String slug,
    required String topicoId,
    required String materialId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$slug/topicos/$topicoId/materiais/$materialId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Erro ao deletar material: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao deletar material: $e');
    }
  }

  // GET: Baixar bytes do arquivo
  static Future<Uint8List> getFileBytes({
    required String slug,
    required String topicoId,
    required String materialId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/$slug/topicos/$topicoId/materiais/$materialId/download',
        ),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw Exception(
          'Erro ao baixar arquivo: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }
}
