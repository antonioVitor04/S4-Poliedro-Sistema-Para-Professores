// services/material_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import '../models/modelo_card_disciplina.dart';
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MaterialService {
  static String get _baseUrl {
    if (kIsWeb) {
      return dotenv.env['BASE_URL_WEB']!;
    }
    return dotenv.env['BASE_URL_MOBILE']!;
  }

  static const String _apiPrefix = '/api/cardsDisciplinas';

  // Helper: Obter MediaType
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
      case 'doc':
      case 'docx':
        return MediaType('application', 'msword');
      case 'xls':
      case 'xlsx':
        return MediaType('application', 'vnd.ms-excel');
      case 'ppt':
      case 'pptx':
        return MediaType('application', 'vnd.ms-powerpoint');
      case 'zip':
        return MediaType('application', 'zip');
      case 'txt':
        return MediaType('text', 'plain');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  // Helper: Sanitizar nome do arquivo
  static String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  // Helper: Converter para horário de Brasília (UTC-3)
  static DateTime _toBrasiliaTime(DateTime dateTime) {
    // Brasília é UTC-3 (horário padrão)
    // Não vamos converter, vamos usar o horário local como se fosse Brasília
    // O backend deve interpretar como horário local
    return dateTime.toLocal();
  }

  // Helper: Converter string do backend para DateTime no fuso de Brasília
  static DateTime _parseBrasiliaTime(String dateString) {
    try {
      // Se a string já tem offset, usar parse
      if (dateString.contains('+') || dateString.endsWith('Z')) {
        final utcTime = DateTime.parse(dateString);
        return utcTime.toLocal();
      } else {
        // Se não tem offset, assumir que é local e converter
        final localTime = DateTime.parse(dateString);
        return localTime;
      }
    } catch (e) {
      print('=== DEBUG: Erro ao parsear data: $e ===');
      return DateTime.now();
    }
  }

  // POST: Adicionar material a um tópico (APENAS PROFESSOR DA DISCIPLINA OU ADMIN)
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
      print('=== DEBUG MaterialService: Iniciando criação de material ===');
      print('=== DEBUG: Slug: $slug, TopicoId: $topicoId, Tipo: $tipo ===');

      // CORREÇÃO: Permitir admin também
      if (!await AuthService.isProfessor() && !await AuthService.isAdmin()) {
        throw Exception(
          'Apenas professores ou administradores podem adicionar materiais',
        );
      }

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_apiPrefix/$slug/topicos/$topicoId/materiais'),
      );

      // Adicionar headers de autenticação
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['tipo'] = tipo;
      request.fields['titulo'] = titulo;
      if (descricao != null) request.fields['descricao'] = descricao;
      if (url != null) request.fields['url'] = url;
      request.fields['peso'] = peso.toString();
      if (prazo != null) {
        // CORREÇÃO: Enviar como horário local (Brasília)
        final prazoBrasilia = _toBrasiliaTime(prazo);
        request.fields['prazo'] = prazoBrasilia.toIso8601String();
        print('=== DEBUG: Prazo original: ${prazo.toLocal()} ===');
        print('=== DEBUG: Prazo enviado (Brasília): ${prazoBrasilia.toIso8601String()} ===');
      }

      // Processar arquivo
      if (arquivo != null) {
        print('=== DEBUG: Processando arquivo: ${arquivo.name} ===');
        if (arquivo.bytes != null && arquivo.bytes!.isNotEmpty) {
          final file = http.MultipartFile.fromBytes(
            'arquivo',
            arquivo.bytes!,
            filename: _sanitizeFileName(arquivo.name),
            contentType: _getMediaType(arquivo.name),
          );
          request.files.add(file);
          print(
            '=== DEBUG: Arquivo adicionado - ${arquivo.name}, ${arquivo.bytes!.length} bytes ===',
          );
        } else {
          print(
            '=== DEBUG AVISO: Arquivo selecionado mas bytes estão vazios ou nulos ===',
          );

          // No Android, tentar usar o path se os bytes estiverem vazios
          if (!kIsWeb && arquivo.path != null) {
            try {
              final file = await http.MultipartFile.fromPath(
                'arquivo',
                arquivo.path!,
                filename: _sanitizeFileName(arquivo.name),
                contentType: _getMediaType(arquivo.name),
              );
              request.files.add(file);
              print(
                '=== DEBUG: Arquivo adicionado via path - ${arquivo.path} ===',
              );
            } catch (e) {
              print('=== DEBUG ERRO ao usar path: $e ===');
              throw Exception(
                'Arquivo corrompido ou inacessível: ${arquivo.name}',
              );
            }
          } else {
            throw Exception(
              'Arquivo está vazio ou corrompido: ${arquivo.name}',
            );
          }
        }
      }

      print('=== DEBUG: Enviando requisição... ===');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = response.body;

      print('=== DEBUG: Status Code: ${response.statusCode} ===');
      print('=== DEBUG: Response Body: $responseBody ===');

      if (response.statusCode == 201) {
        final data = json.decode(responseBody);
        if (data['success'] == true) {
          print('=== DEBUG: Material criado com sucesso ===');
        } else {
          throw Exception(
            data['error'] ?? 'Erro desconhecido ao criar material',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Apenas professores desta disciplina podem adicionar materiais',
        );
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      print('=== DEBUG ERRO MaterialService.criarMaterial: $e ===');
      throw Exception('Erro ao criar material: $e');
    }
  }

  // PUT: Atualizar material (APENAS PROFESSOR DA DISCIPLINA OU ADMIN)
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
      print('=== DEBUG MaterialService: Iniciando atualização de material ===');

      // CORREÇÃO: Permitir admin também
      if (!await AuthService.isProfessor() && !await AuthService.isAdmin()) {
        throw Exception(
          'Apenas professores ou administradores podem editar materiais',
        );
      }

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
          '$_baseUrl$_apiPrefix/$slug/topicos/$topicoId/materiais/$materialId',
        ),
      );

      // Adicionar headers de autenticação
      request.headers['Authorization'] = 'Bearer $token';

      if (tipo != null) request.fields['tipo'] = tipo;
      if (titulo != null) request.fields['titulo'] = titulo;
      if (descricao != null) request.fields['descricao'] = descricao;
      if (url != null) request.fields['url'] = url;
      if (peso != null) request.fields['peso'] = peso.toString();
      if (prazo != null) {
        // CORREÇÃO: Enviar como horário local (Brasília)
        final prazoBrasilia = _toBrasiliaTime(prazo);
        request.fields['prazo'] = prazoBrasilia.toIso8601String();
        print('=== DEBUG: Prazo atualizado (Brasília): ${prazoBrasilia.toIso8601String()} ===');
      }

      // Processar arquivo (opcional)
      if (arquivo != null) {
        if (arquivo.bytes != null && arquivo.bytes!.isNotEmpty) {
          final file = http.MultipartFile.fromBytes(
            'arquivo',
            arquivo.bytes!,
            filename: _sanitizeFileName(arquivo.name),
            contentType: _getMediaType(arquivo.name),
          );
          request.files.add(file);
          print(
            '=== DEBUG: Arquivo atualizado - ${arquivo.name}, ${arquivo.bytes!.length} bytes ===',
          );
        } else {
          print(
            '=== DEBUG AVISO: Arquivo selecionado mas bytes estão vazios ===',
          );

          if (!kIsWeb && arquivo.path != null) {
            try {
              final file = await http.MultipartFile.fromPath(
                'arquivo',
                arquivo.path!,
                filename: _sanitizeFileName(arquivo.name),
                contentType: _getMediaType(arquivo.name),
              );
              request.files.add(file);
              print(
                '=== DEBUG: Arquivo atualizado via path - ${arquivo.path} ===',
              );
            } catch (e) {
              print('=== DEBUG ERRO ao usar path: $e ===');
              throw Exception(
                'Arquivo corrompido ou inacessível: ${arquivo.name}',
              );
            }
          } else {
            throw Exception(
              'Arquivo está vazio ou corrompido: ${arquivo.name}',
            );
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseBody = response.body;

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao atualizar material');
        }
        print('=== DEBUG: Material atualizado com sucesso ===');
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Apenas professores desta disciplina podem editar materiais',
        );
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      print('=== DEBUG ERRO MaterialService.atualizarMaterial: $e ===');
      throw Exception('Erro ao atualizar material: $e');
    }
  }

  // DELETE: Deletar material (APENAS PROFESSOR DA DISCIPLINA OU ADMIN)
  static Future<void> deletarMaterial({
    required String slug,
    required String topicoId,
    required String materialId,
  }) async {
    try {
      print('=== DEBUG MaterialService: Deletando material $materialId ===');

      // CORREÇÃO: Permitir admin também
      if (!await AuthService.isProfessor() && !await AuthService.isAdmin()) {
        throw Exception(
          'Apenas professores ou administradores podem deletar materiais',
        );
      }

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.delete(
        Uri.parse(
          '$_baseUrl$_apiPrefix/$slug/topicos/$topicoId/materiais/$materialId',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao deletar material');
        }
        print('=== DEBUG: Material deletado com sucesso ===');
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Apenas professores desta disciplina podem deletar materiais',
        );
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('=== DEBUG ERRO MaterialService.deletarMaterial: $e ===');
      throw Exception('Erro ao deletar material: $e');
    }
  }

  static Future<Uint8List> getFileBytes({
    required String slug,
    required String topicoId,
    required String materialId,
  }) async {
    try {
      print(
        '=== DEBUG MaterialService: Baixando arquivo do material $materialId ===',
      );

      final token = await AuthService.getToken();
      final headers = <String, String>{};

      // ✅ ADICIONAR TOKEN DE AUTENTICAÇÃO
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(
          '$_baseUrl$_apiPrefix/$slug/topicos/$topicoId/materiais/$materialId/download',
        ),
        headers: headers, // ✅ ENVIAR HEADER DE AUTORIZAÇÃO
      );

      print('=== DEBUG: Status Code: ${response.statusCode} ===');
      print('=== DEBUG: Response Headers: ${response.headers} ===');

      if (response.statusCode == 200) {
        print(
          '=== DEBUG: Arquivo baixado com sucesso - ${response.bodyBytes.length} bytes ===',
        );
        return response.bodyBytes;
      } else if (response.statusCode == 403) {
        throw Exception(
          'Acesso negado. Verifique se você está matriculado nesta disciplina.',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else {
        throw Exception(
          'Erro ao baixar arquivo: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO MaterialService.getFileBytes: $e ===');
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }
}