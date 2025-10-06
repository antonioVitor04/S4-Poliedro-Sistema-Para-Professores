// services/card_disciplina_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/modelo_card_disciplina.dart';

class CardDisciplinaService {
  static const String baseUrl = 'http://localhost:5000/api/cardsDisciplinas';

  // Buscar card por slug - ADICIONE UM TIMESTAMP PARA EVITAR CACHE
  static Future<CardDisciplina> getCardBySlug(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/disciplina/$slug?t=${DateTime.now().millisecondsSinceEpoch}'),
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

  // Método para buscar TODOS os cards
  static Future<List<CardDisciplina>> getAllCards() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final cardsJson = data['data'] as List;
          return cardsJson.map((json) => CardDisciplina.fromJson(json)).toList();
        }
      }
      throw Exception('Erro ao carregar cards: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // Criar um novo card
  static Future<void> criarCard(String titulo, PlatformFile imagemFile, PlatformFile iconeFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      request.fields['titulo'] = titulo;

      // Adicionar imagem
      request.files.add(
        http.MultipartFile.fromBytes(
          'imagem',
          imagemFile.bytes!,
          filename: imagemFile.name,
        ),
      );

      // Adicionar ícone
      request.files.add(
        http.MultipartFile.fromBytes(
          'icone',
          iconeFile.bytes!,
          filename: iconeFile.name,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao criar disciplina');
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao criar disciplina: $e');
    }
  }

  // Atualizar um card existente
  static Future<void> atualizarCard(String id, String titulo, PlatformFile? imagemFile, PlatformFile? iconeFile) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/$id'));

      if (titulo.isNotEmpty) {
        request.fields['titulo'] = titulo;
      }

      if (imagemFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'imagem',
            imagemFile.bytes!,
            filename: imagemFile.name,
          ),
        );
      }

      if (iconeFile != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'icone',
            iconeFile.bytes!,
            filename: iconeFile.name,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao atualizar disciplina');
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro ao atualizar disciplina: $e');
    }
  }

  // Deletar um card
  static Future<void> deletarCard(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

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