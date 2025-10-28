// services/comentario_service.dart - VERSÃO CORRIGIDA
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/modelo_comentario.dart';
import 'auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ComentarioService {
  static String get _baseUrl {
    if (kIsWeb) {
      return dotenv.env['BASE_URL_WEB']!;
    }
    return dotenv.env['BASE_URL_MOBILE']!;
  }

  static const String _apiPrefix = '/api/comentarios';

  // Lista local para armazenar comentários quando a API não estiver disponível
  static final Map<String, List<Comentario>> _comentariosLocais = {};

  // GET: Buscar comentários de um material - VERSÃO SIMPLIFICADA
  static Future<ApiResponse<List<Comentario>>> buscarComentariosPorMaterial(
    String materialId, {
    int pagina = 1,
    int limite = 20,
  }) async {
    try {
      print(
        '=== DEBUG ComentarioService: Buscando comentários do material $materialId ===',
      );

      final token = await AuthService.getToken();
      final headers = <String, String>{'Content-Type': 'application/json'};

      // Adicionar token se disponível
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http
          .get(
            Uri.parse(
              '$_baseUrl$_apiPrefix/material/$materialId?pagina=$pagina&limite=$limite',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (data['success'] == true) {
          if (data['data'] is List) {
            final comentarios = (data['data'] as List)
                .map((item) => Comentario.fromJson(item))
                .toList();
            return ApiResponse(
              success: true,
              data: comentarios,
              statusCode: 200,
            );
          } else {
            // Se data não é uma lista, retornar array vazio
            return ApiResponse(success: true, data: [], statusCode: 200);
          }
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Erro ao buscar comentários',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 404) {
        // Comentários não encontrados - retornar array vazio
        return ApiResponse(success: true, data: [], statusCode: 200);
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401,
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403,
        );
      } else {
        // Para outros erros, tentar usar sistema local
        print(
          '=== DEBUG: Erro HTTP ${response.statusCode}, usando sistema local ===',
        );
        if (!_comentariosLocais.containsKey(materialId)) {
          _comentariosLocais[materialId] = [];
        }
        return ApiResponse(
          success: true,
          data: _comentariosLocais[materialId]!,
          statusCode: 200,
          message: 'Sistema local ativado devido a erro na API',
        );
      }
    } catch (e) {
      print(
        '=== DEBUG ERRO ComentarioService.buscarComentariosPorMaterial: $e ===',
      );

      // Em caso de erro, usar sistema local
      if (!_comentariosLocais.containsKey(materialId)) {
        _comentariosLocais[materialId] = [];
      }
      return ApiResponse(
        success: true,
        data: _comentariosLocais[materialId]!,
        statusCode: 200,
        message: 'Sistema local ativado devido a erro de conexão',
      );
    }
  }

  // POST: Criar novo comentário - VERSÃO CORRIGIDA PARA SLUG
  static Future<ApiResponse<Comentario>> criarComentario({
    required String materialId,
    required String topicoId,
    required String slug, // AGORA RECEBE SLUG DIRETAMENTE
    required String texto,
  }) async {
    try {
      print('=== DEBUG ComentarioService: Criando comentário ===');
      print(
        '=== DEBUG: Dados - materialId: $materialId, topicoId: $topicoId, slug: $slug ===',
      );

      final token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          message: 'Usuário não autenticado',
          statusCode: 401,
        );
      }

      // AGORA ENVIAMOS O SLUG DIRETAMENTE - O BACKEND CONVERTE PARA ObjectId
      final requestBody = {
        'materialId': materialId,
        'topicoId': topicoId,
        'disciplinaId': slug, // ENVIA O SLUG - BACKEND CONVERTE
        'texto': texto,
      };

      print('=== DEBUG: Request Body: $requestBody ===');

      final response = await http
          .post(
            Uri.parse('$_baseUrl$_apiPrefix'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');
      print('=== DEBUG: Response Body: ${response.body} ===');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (data['success'] == true && data['data'] != null) {
          final comentario = Comentario.fromJson(data['data']);
          return ApiResponse(
            success: true,
            data: comentario,
            statusCode: response.statusCode,
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Erro ao criar comentário',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401,
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403,
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Disciplina não encontrada.',
          statusCode: 404,
        );
      } else {
        // Para erro 500 ou outros, tentar decodificar a resposta de erro
        try {
          final errorData = json.decode(utf8.decode(response.bodyBytes));
          return ApiResponse(
            success: false,
            message:
                errorData['message'] ??
                errorData['error'] ??
                'Erro interno do servidor',
            statusCode: response.statusCode,
          );
        } catch (e) {
          return ApiResponse(
            success: false,
            message: 'Erro HTTP ${response.statusCode}: ${response.body}',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.criarComentario: $e ===');
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
        statusCode: 500,
      );
    }
  }

  // POST: Adicionar resposta a um comentário
  static Future<ApiResponse<Comentario>> adicionarResposta({
    required String comentarioId,
    required String texto,
  }) async {
    try {
      print('=== DEBUG ComentarioService: Adicionando resposta ===');

      final token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          message: 'Usuário não autenticado',
          statusCode: 401,
        );
      }

      final requestBody = {'texto': texto};

      final response = await http
          .post(
            Uri.parse('$_baseUrl$_apiPrefix/$comentarioId/respostas'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (data['success'] == true && data['data'] != null) {
          final comentario = Comentario.fromJson(data['data']);
          return ApiResponse(success: true, data: comentario, statusCode: 200);
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Erro ao adicionar resposta',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401,
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403,
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Comentário não encontrado.',
          statusCode: 404,
        );
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return ApiResponse(
          success: false,
          message: errorData['message'] ?? 'Erro HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.adicionarResposta: $e ===');
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
        statusCode: 500,
      );
    }
  }

  // PUT: Editar comentário
  static Future<ApiResponse<Comentario>> editarComentario({
    required String comentarioId,
    required String texto,
  }) async {
    try {
      print('=== DEBUG ComentarioService: Editando comentário ===');

      final token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          message: 'Usuário não autenticado',
          statusCode: 401,
        );
      }

      final requestBody = {'texto': texto};

      final response = await http
          .put(
            Uri.parse('$_baseUrl$_apiPrefix/$comentarioId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (data['success'] == true && data['data'] != null) {
          final comentario = Comentario.fromJson(data['data']);
          return ApiResponse(success: true, data: comentario, statusCode: 200);
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Erro ao editar comentário',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401,
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403,
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Comentário não encontrado.',
          statusCode: 404,
        );
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return ApiResponse(
          success: false,
          message: errorData['message'] ?? 'Erro HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.editarComentario: $e ===');
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
        statusCode: 500,
      );
    }
  }

  // Adicione este método no ComentarioService
  static Future<Uint8List?> getUserImageBytes({
    required String userId,
    required String userType,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return null;

      final String endpoint = userType == 'aluno' ? 'alunos' : 'professores';
      final url = Uri.parse('$_baseUrl/api/$endpoint/$userId/foto');

      print('=== DEBUG: Buscando imagem do usuário $userId ===');

      final response = await http
          .get(url, headers: {'Authorization': 'Bearer $token'})
          .timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');
      print('=== DEBUG: Content-Type: ${response.headers['content-type']} ===');

      if (response.statusCode == 200) {
        // Verifica se é realmente uma imagem
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.startsWith('image/')) {
          print(
            '=== DEBUG: Imagem encontrada - ${response.bodyBytes.length} bytes ===',
          );
          return response.bodyBytes;
        } else {
          print('=== DEBUG: Content-Type inválido: $contentType ===');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('=== DEBUG: Imagem não encontrada (404) ===');
        return null;
      } else {
        print('=== DEBUG: Erro HTTP ${response.statusCode} ===');
        return null;
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.getUserImageBytes: $e ===');
      return null;
    }
  }

  // Adicione este método na classe ComentarioService
  static Future<void> debugImageUrl({
    required String userId,
    required String userType,
  }) async {
    try {
      print('=== DEBUG IMAGE URL ===');
      final token = await AuthService.getToken();
      final String endpoint = userType == 'aluno' ? 'alunos' : 'professores';
      final url = '$_baseUrl/api/$endpoint/image/$userId';

      print('User ID: $userId');
      print('User Type: $userType');
      print('Token Available: ${token != null}');
      print('Image URL: $url');

      if (token != null) {
        // Testar a URL
        final response = await http
            .get(Uri.parse(url), headers: {'Authorization': 'Bearer $token'})
            .timeout(const Duration(seconds: 5));

        print('Response Status: ${response.statusCode}');
        print('Response Headers: ${response.headers}');
        print('Response Body Length: ${response.bodyBytes.length}');
      }

      print('=== END DEBUG ===');
    } catch (e) {
      print('=== DEBUG ERROR: $e ===');
    }
  }

  static String getUserImageUrl({
    required String userId,
    required String userType,
  }) {
    final String endpoint = userType == 'aluno' ? 'alunos' : 'professores';
    // Use a rota correta que existe no backend
    final url = '$_baseUrl/api/$endpoint/image/$userId';
    print('=== GENERATED IMAGE URL: $url ===');
    return url;
  }

  // DELETE: Excluir comentário
  static Future<ApiResponse<void>> excluirComentario({
    required String comentarioId,
  }) async {
    try {
      print('=== DEBUG ComentarioService: Excluindo comentário ===');

      final token = await AuthService.getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          message: 'Usuário não autenticado',
          statusCode: 401,
        );
      }

      final response = await http
          .delete(
            Uri.parse('$_baseUrl$_apiPrefix/$comentarioId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        if (data['success'] == true) {
          return ApiResponse(
            success: true,
            message: data['message'],
            statusCode: 200,
          );
        } else {
          return ApiResponse(
            success: false,
            message: data['message'] ?? 'Erro ao excluir comentário',
            statusCode: response.statusCode,
          );
        }
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false,
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401,
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false,
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403,
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false,
          message: 'Comentário não encontrado.',
          statusCode: 404,
        );
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return ApiResponse(
          success: false,
          message: errorData['message'] ?? 'Erro HTTP ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.excluirComentario: $e ===');
      return ApiResponse(
        success: false,
        message: 'Erro de conexão: $e',
        statusCode: 500,
      );
    }
  }

  // Método para limpar comentários locais (útil para testes)
  static void limparComentariosLocais() {
    _comentariosLocais.clear();
  }
}

class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.statusCode,
  });
}
