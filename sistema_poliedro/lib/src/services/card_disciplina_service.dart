// services/card_disciplina_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
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
}