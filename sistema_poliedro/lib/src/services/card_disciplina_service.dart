// services/card_disciplina_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/modelo_card_disciplina.dart';

class CardDisciplinaService {
  static const String baseUrl = 'http://localhost:5000';

  static Future<List<CardDisciplina>> getCards() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cardsDisciplinas'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true) {
          final List<dynamic> cardsData = data['data'];
          return cardsData.map((json) => CardDisciplina.fromJson(json)).toList();
        } else {
          throw Exception('Erro ao buscar cards: ${data['error']}');
        }
      } else {
        throw Exception('Falha ao carregar cards. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }

  static Future<CardDisciplina> getCardBySlug(String slug) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cardsDisciplinas/disciplina/$slug'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        if (data['success'] == true) {
          return CardDisciplina.fromJson(data['data']);
        } else {
          throw Exception('Erro ao buscar card: ${data['error']}');
        }
      } else {
        throw Exception('Falha ao carregar card. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro de conexão: $e');
    }
  }
}