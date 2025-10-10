import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/modelo_card_disciplina.dart';

class CardDisciplinaService {
  static String get _baseUrl {
    if (kIsWeb) return 'http://localhost:5000';
    return 'http://192.168.15.123:5000';
  }

  static const String _apiPrefix = '/api/cardsDisciplinas';

  // CORREÇÃO CRÍTICA: Método auxiliar para lidar com arquivos no Android
  static Future<http.MultipartFile> _createMultipartFile(
    PlatformFile platformFile, 
    String fieldName
  ) async {
    print('=== DEBUG: Criando MultipartFile para $fieldName ===');
    print('=== DEBUG: Nome: ${platformFile.name} ===');
    print('=== DEBUG: Tamanho: ${platformFile.size} ===');
    print('=== DEBUG: Bytes: ${platformFile.bytes?.length} ===');
    print('=== DEBUG: Path: ${platformFile.path} ===');
    print('=== DEBUG: kIsWeb: $kIsWeb ===');

    // Se temos bytes diretamente (funciona no Web e às vezes no Android)
    if (platformFile.bytes != null && platformFile.bytes!.isNotEmpty) {
      print('=== DEBUG: Usando bytes diretamente ===');
      return http.MultipartFile.fromBytes(
        fieldName,
        platformFile.bytes!,
        filename: platformFile.name,
      );
    }
    
    // CORREÇÃO PARA ANDROID: Se bytes estão nulos mas temos um path
    if (!kIsWeb && platformFile.path != null) {
      print('=== DEBUG: Tentando usar path no Android: ${platformFile.path} ===');
      try {
        // No Android, usar fromPath que lê o arquivo do sistema de arquivos
        return await http.MultipartFile.fromPath(
          fieldName,
          platformFile.path!,
          filename: platformFile.name,
        );
      } catch (e) {
        print('=== DEBUG ERRO ao usar fromPath: $e ===');
        throw Exception('Não foi possível acessar o arquivo ${platformFile.name} no dispositivo');
      }
    }
    
    // Se chegou aqui, não conseguimos acessar o arquivo
    print('=== DEBUG ERRO: Arquivo inacessível - Bytes: ${platformFile.bytes?.length}, Path: ${platformFile.path} ===');
    throw Exception('Arquivo ${platformFile.name} está corrompido ou inacessível');
  }

  // Criar um novo card - VERSÃO CORRIGIDA
  static Future<void> criarCard(
    String titulo,
    PlatformFile imagemFile,
    PlatformFile iconeFile,
  ) async {
    try {
      print('=== DEBUG CardDisciplinaService.criarCard: Iniciando ===');
      print('=== DEBUG: Título: $titulo ===');
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_apiPrefix'),
      );
      request.fields['titulo'] = titulo;

      // CORREÇÃO: Usar o método auxiliar que lida com Android/Web
      print('=== DEBUG: Processando imagem... ===');
      final imagemMultipart = await _createMultipartFile(imagemFile, 'imagem');
      request.files.add(imagemMultipart);

      print('=== DEBUG: Processando ícone... ===');
      final iconeMultipart = await _createMultipartFile(iconeFile, 'icone');
      request.files.add(iconeMultipart);

      print('=== DEBUG: Enviando requisição... ===');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== DEBUG: Status Code: ${response.statusCode} ===');
      print('=== DEBUG: Response Body: ${response.body} ===');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao criar disciplina');
        }
        print('=== DEBUG: Card criado com sucesso ===');
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('=== DEBUG ERRO CardDisciplinaService.criarCard: $e ===');
      throw Exception('Erro ao criar disciplina: $e');
    }
  }

  // Atualizar um card existente - VERSÃO CORRIGIDA
  static Future<void> atualizarCard(
    String id,
    String titulo,
    PlatformFile? imagemFile,
    PlatformFile? iconeFile,
  ) async {
    try {
      print('=== DEBUG CardDisciplinaService.atualizarCard: Iniciando ===');
      
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl$_apiPrefix/$id'),
      );

      if (titulo.isNotEmpty) {
        request.fields['titulo'] = titulo;
      }

      // CORREÇÃO: Usar o método auxiliar
      if (imagemFile != null) {
        print('=== DEBUG: Processando nova imagem... ===');
        final imagemMultipart = await _createMultipartFile(imagemFile, 'imagem');
        request.files.add(imagemMultipart);
      }

      if (iconeFile != null) {
        print('=== DEBUG: Processando novo ícone... ===');
        final iconeMultipart = await _createMultipartFile(iconeFile, 'icone');
        request.files.add(iconeMultipart);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao atualizar disciplina');
        }
        print('=== DEBUG: Card atualizado com sucesso ===');
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('=== DEBUG ERRO CardDisciplinaService.atualizarCard: $e ===');
      throw Exception('Erro ao atualizar disciplina: $e');
    }
  }

  // Os outros métodos (getCardBySlug, getAllCards, deletarCard) permanecem iguais
  static Future<CardDisciplina> getCardBySlug(String slug) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl$_apiPrefix/disciplina/$slug?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CardDisciplina.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Erro desconhecido');
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar disciplina: $e');
    }
  }

  static Future<List<CardDisciplina>> getAllCards() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl$_apiPrefix'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final cardsJson = data['data'] as List;
          return cardsJson
              .map((json) => CardDisciplina.fromJson(json))
              .toList();
        }
      }
      throw Exception('Erro ao carregar cards: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  static Future<void> deletarCard(String id) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl$_apiPrefix/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao deletar disciplina');
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao deletar disciplina: $e');
    }
  }
}