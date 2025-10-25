// services/mensagens_professor_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MensagensProfessorService {
  static String get baseUrl => AuthService.baseUrl;

  static Future<List<Map<String, dynamic>>> fetchDisciplinasProfessor() async {
    final token = await AuthService.getToken();
    if (token == null) throw Exception('Token não disponível');

    // DEBUG: Verificar tipo do usuário
    final userType = await AuthService.getUserType();
    final isAdmin = await AuthService.isAdmin();
    final isProfessor = await AuthService.isProfessor();

    print('🔐 Debug User Type:');
    print('  - userType: $userType');
    print('  - isAdmin: $isAdmin');
    print('  - isProfessor: $isProfessor');

    String url = '$baseUrl/api/notificacoes/disciplinas';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    print('📡 Status: ${response.statusCode}');
    print('📦 Response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['disciplinas']);
    } else {
      throw Exception(
        'Falha ao carregar disciplinas: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // services/mensagens_prof_service.dart
  static Future<void> enviarMensagem({
    required String mensagem,
    required List<String> disciplinasIds,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token não disponível');

      final userId = await AuthService.getUserId();
      final userType = await AuthService.getUserType();

      print('=== 📤 ENVIANDO PARA API ===');
      print('🔗 URL: $baseUrl/api/notificacoes/professor');
      print('👤 User ID: $userId');
      print('👤 User Type: $userType');
      print('📝 Mensagem: $mensagem');
      print('🎯 Disciplinas: $disciplinasIds');

      final body = {'mensagem': mensagem, 'disciplinas': disciplinasIds};

      print('📦 Body: $body');

      final response = await http.post(
        Uri.parse('$baseUrl/api/notificacoes/professor'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      print('📡 Status: ${response.statusCode}');
      print('📦 Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Mensagem enviada com sucesso!');
        return;
      } else {
        // Tenta parsear o erro da API
        try {
          final errorData = json.decode(response.body);
          throw Exception(
            'Erro ${response.statusCode}: ${errorData['message'] ?? errorData['error'] ?? response.body}',
          );
        } catch (e) {
          throw Exception('Erro ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      print('❌ Erro no serviço de envio: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchMensagensEnviadas() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) throw Exception('Token não disponível');

      final isAdmin = await AuthService.isAdmin();
      String url = '$baseUrl/api/notificacoes/professor';

      if (!isAdmin) {
        final userId = await AuthService.getUserId();
        url = '$baseUrl/api/notificacoes/professor?professorId=$userId';
      }

      print('🔍 Buscando mensagens em: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('📡 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📦 Response completa: $data');

        // DEBUG: Verificar estrutura exata
        print('🔍 Estrutura da resposta:');
        print('  - Tipo: ${data.runtimeType}');
        if (data is Map) {
          print('  - Keys: ${data.keys.toList()}');
          if (data['mensagens'] != null) {
            print('  - Tipo de mensagens: ${data['mensagens'].runtimeType}');
            print(
              '  - Quantidade de mensagens: ${data['mensagens'] is List ? data['mensagens'].length : 'não é lista'}',
            );
          }
        }

        // CORREÇÃO: Verificar se realmente há mensagens
        if (data is Map && data['success'] == true) {
          if (data['mensagens'] is List) {
            final mensagens = List<Map<String, dynamic>>.from(
              data['mensagens'],
            );
            print('✅ Mensagens encontradas: ${mensagens.length}');
            return mensagens;
          } else {
            print('⚠️ Campo "mensagens" não é uma lista ou não existe');
            return []; // Retorna array vazio se não há mensagens
          }
        } else if (data is List) {
          // Se a resposta já é uma lista diretamente
          final mensagens = List<Map<String, dynamic>>.from(data);
          print('✅ Mensagens encontradas (lista direta): ${mensagens.length}');
          return mensagens;
        } else {
          print('⚠️ Estrutura não reconhecida, retornando array vazio');
          return [];
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erro em fetchMensagensEnviadas: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getProfessorInfo() async {
    final token = await AuthService.getToken();
    if (token == null) return null;

    final userId = await AuthService.getUserId();
    if (userId == null) return null;

    final response = await http.get(
      Uri.parse('$baseUrl/api/professores/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null;
  }
}
