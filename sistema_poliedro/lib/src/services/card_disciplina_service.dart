import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/modelo_card_disciplina.dart';
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CardDisciplinaService {
  static String get _baseUrl {
    if (kIsWeb) {
      return dotenv.env['BASE_URL_WEB']!;
    }
    return dotenv.env['BASE_URL_MOBILE']!;
  }

  static const String _apiPrefix = '/api/cardsDisciplinas';

  // CORREÇÃO CRÍTICA: Método auxiliar para lidar com arquivos no Android
  static Future<http.MultipartFile> _createMultipartFile(
    PlatformFile platformFile,
    String fieldName,
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
      print(
        '=== DEBUG: Tentando usar path no Android: ${platformFile.path} ===',
      );
      try {
        // No Android, usar fromPath que lê o arquivo do sistema de arquivos
        return await http.MultipartFile.fromPath(
          fieldName,
          platformFile.path!,
          filename: platformFile.name,
        );
      } catch (e) {
        print('=== DEBUG ERRO ao usar fromPath: $e ===');
        throw Exception(
          'Não foi possível acessar o arquivo ${platformFile.name} no dispositivo',
        );
      }
    }

    // Se chegou aqui, não conseguimos acessar o arquivo
    print(
      '=== DEBUG ERRO: Arquivo inacessível - Bytes: ${platformFile.bytes?.length}, Path: ${platformFile.path} ===',
    );
    throw Exception(
      'Arquivo ${platformFile.name} está corrompido ou inacessível',
    );
  }

  static Future<void> criarCard(
    String titulo,
    PlatformFile imagemFile,
    PlatformFile iconeFile, {
    List<String>? professores,
    List<String>? alunos,
  }) async {
    try {
      print('=== DEBUG: Verificando autenticação para criar card ===');

      // Verificar se é professor
      if (await AuthService.isAluno()) {
        throw Exception('Apenas professores ou admins podem criar disciplinas');
      }

      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl$_apiPrefix'),
      );

      // ADICIONAR HEADER DE AUTORIZAÇÃO
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['titulo'] = titulo;

      // Adicionar professores e alunos se fornecidos
      if (professores != null && professores.isNotEmpty) {
        request.fields['professores'] = json.encode(professores);
      }
      if (alunos != null && alunos.isNotEmpty) {
        request.fields['alunos'] = json.encode(alunos);
      }

      // Processar arquivos
      final imagemMultipart = await _createMultipartFile(imagemFile, 'imagem');
      request.files.add(imagemMultipart);

      final iconeMultipart = await _createMultipartFile(iconeFile, 'icone');
      request.files.add(iconeMultipart);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao criar disciplina');
        }
        print('=== DEBUG: Card criado com sucesso ===');
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception('Apenas professores ou alunos podem criar disciplinas');
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('=== DEBUG ERRO CardDisciplinaService.criarCard: $e ===');
      rethrow;
    }
  }

  static Future<void> atualizarCard(
    String id,
    String titulo,
    PlatformFile? imagemFile,
    PlatformFile? iconeFile, {
    List<String>? professores,
    List<String>? alunos,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$_baseUrl$_apiPrefix/$id'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      if (titulo.isNotEmpty) {
        request.fields['titulo'] = titulo;
      }

      // CORREÇÃO: Enviar arrays como campos múltiplos
      if (professores != null) {
        // Enviar cada professor como campo separado
        for (int i = 0; i < professores.length; i++) {
          request.fields['professores[$i]'] = professores[i];
        }
        print('=== DEBUG: Enviando ${professores.length} professores ===');
      }

      if (alunos != null) {
        // Enviar cada aluno como campo separado
        for (int i = 0; i < alunos.length; i++) {
          request.fields['alunos[$i]'] = alunos[i];
        }
        print('=== DEBUG: Enviando ${alunos.length} alunos ===');
      }

      // DEBUG: Verificar campos
      print('=== DEBUG: Campos finais: ${request.fields} ===');

      // Processar arquivos...
      if (imagemFile != null) {
        final imagemMultipart = await _createMultipartFile(
          imagemFile,
          'imagem',
        );
        request.files.add(imagemMultipart);
      }

      if (iconeFile != null) {
        final iconeMultipart = await _createMultipartFile(iconeFile, 'icone');
        request.files.add(iconeMultipart);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== DEBUG: Status Code: ${response.statusCode} ===');
      print('=== DEBUG: Response Body: ${response.body} ===');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao atualizar disciplina');
        }
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('=== DEBUG ERRO CardDisciplinaService.atualizarCard: $e ===');
      rethrow;
    }
  }

  // Deletar card (APENAS PROFESSOR da disciplina ou ADMIN)
  static Future<void> deletarCard(String id) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl$_apiPrefix/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] != true) {
          throw Exception(data['error'] ?? 'Erro ao deletar disciplina');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception('Você não tem permissão para deletar esta disciplina');
      } else {
        throw Exception('Erro HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('=== DEBUG ERRO CardDisciplinaService.deletarCard: $e ===');
      throw Exception('Erro ao deletar disciplina: $e');
    }
  }

  // GET: Buscar todas as disciplinas (com filtro por usuário)
  static Future<List<CardDisciplina>> getAllCards() async {
    try {
      final token = await AuthService.getToken();
      final headers = <String, String>{};

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl$_apiPrefix'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final cardsJson = data['data'] as List;
          return cardsJson
              .map((json) => CardDisciplina.fromJson(json))
              .toList();
        }
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception('Acesso negado a esta disciplina');
      }
      throw Exception('Erro ao carregar cards: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // GET: Buscar disciplinas do usuário logado
  static Future<List<CardDisciplina>> getMinhasDisciplinas() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl$_apiPrefix/minhas-disciplinas'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final cardsJson = data['data'] as List;
          return cardsJson
              .map((json) => CardDisciplina.fromJson(json))
              .toList();
        }
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      }
      throw Exception('Erro ao carregar disciplinas: ${response.statusCode}');
    } catch (e) {
      throw Exception('Erro ao conectar com o servidor: $e');
    }
  }

  // GET: Buscar card por slug (com controle de acesso)
  static Future<CardDisciplina> getCardBySlug(String slug) async {
    try {
      final token = await AuthService.getToken();
      final headers = <String, String>{};

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse(
          '$_baseUrl$_apiPrefix/disciplina/$slug?t=${DateTime.now().millisecondsSinceEpoch}',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return CardDisciplina.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Erro desconhecido');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Acesso não autorizado. Faça login novamente.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Acesso negado. Você não tem permissão para esta disciplina.',
        );
      } else if (response.statusCode == 404) {
        throw Exception('Disciplina não encontrada');
      } else {
        throw Exception('Erro HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao carregar disciplina: $e');
    }
  }

  // NOVO: Buscar alunos por RA
  static Future<List<Map<String, dynamic>>> buscarAlunosPorRA(String ra) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('${_baseUrl}/api/alunos/buscar?ra=$ra'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erro ao buscar alunos: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar alunos: $e');
    }
  }

  // NOVO: Buscar professores por email
  static Future<List<Map<String, dynamic>>> buscarProfessoresPorEmail(
    String email,
  ) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Usuário não autenticado');
      }

      final response = await http.get(
        Uri.parse('${_baseUrl}/api/professores/buscar?email=$email'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erro ao buscar professores: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erro ao buscar professores: $e');
    }
  }
}
