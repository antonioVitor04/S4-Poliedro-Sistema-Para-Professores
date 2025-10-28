// services/comentario_service.dart
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

  // GET: Buscar comentários de um material
  static Future<ApiResponse<List<Comentario>>> buscarComentariosPorMaterial(
    String materialId, {
    int pagina = 1,
    int limite = 20,
  }) async {
    try {
      print('=== DEBUG ComentarioService: Buscando comentários do material $materialId ===');

      // Verificar se temos comentários locais para este material
      if (_comentariosLocais.containsKey(materialId)) {
        print('=== DEBUG: Retornando comentários locais ===');
        return ApiResponse(
          success: true, 
          data: _comentariosLocais[materialId]!,
          statusCode: 200
        );
      }

      final token = await AuthService.getToken();
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };

      // Adicionar token se disponível
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl$_apiPrefix/material/$materialId?pagina=$pagina&limite=$limite'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['success'] == true && data['data'] is List) {
          final comentarios = (data['data'] as List)
              .map((item) => Comentario.fromJson(item))
              .toList();
          return ApiResponse(success: true, data: comentarios, statusCode: 200);
        } else {
          return ApiResponse(
            success: false, 
            message: data['message'] ?? 'Formato de resposta inválido',
            statusCode: response.statusCode
          );
        }
      } else if (response.statusCode == 404) {
        // API não encontrada - usar sistema local
        print('=== DEBUG: API não encontrada, usando sistema local ===');
        if (!_comentariosLocais.containsKey(materialId)) {
          _comentariosLocais[materialId] = [];
        }
        return ApiResponse(
          success: true, 
          data: _comentariosLocais[materialId]!,
          statusCode: 200,
          message: 'Sistema local ativado'
        );
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false, 
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false, 
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403
        );
      } else {
        // Para outros erros, tentar usar sistema local
        print('=== DEBUG: Erro HTTP ${response.statusCode}, usando sistema local ===');
        if (!_comentariosLocais.containsKey(materialId)) {
          _comentariosLocais[materialId] = [];
        }
        return ApiResponse(
          success: true, 
          data: _comentariosLocais[materialId]!,
          statusCode: 200,
          message: 'Sistema local ativado devido a erro na API'
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.buscarComentariosPorMaterial: $e ===');
      
      // Em caso de erro, usar sistema local
      if (!_comentariosLocais.containsKey(materialId)) {
        _comentariosLocais[materialId] = [];
      }
      return ApiResponse(
        success: true, 
        data: _comentariosLocais[materialId]!,
        statusCode: 200,
        message: 'Sistema local ativado devido a erro de conexão'
      );
    }
  }

  // POST: Criar novo comentário
  static Future<ApiResponse<Comentario>> criarComentario({
    required String materialId,
    required String topicoId,
    required String disciplinaId,
    required String texto,
  }) async {
    try {
      print('=== DEBUG ComentarioService: Criando comentário ===');

      final token = await AuthService.getToken();
      
      final requestBody = {
        'materialId': materialId,
        'topicoId': topicoId,
        'disciplinaId': disciplinaId,
        'texto': texto,
      };

      print('=== DEBUG: Request Body: $requestBody ===');

      // Se não há token, usar sistema local
      if (token == null) {
        return _criarComentarioLocal(
          materialId: materialId,
          topicoId: topicoId,
          disciplinaId: disciplinaId,
          texto: texto,
        );
      }

      final response = await http.post(
        Uri.parse('$_baseUrl$_apiPrefix'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final data = json.decode(utf8.decode(response.bodyBytes));
          
          if (data['success'] == true && data['data'] != null) {
            final comentario = Comentario.fromJson(data['data']);
            return ApiResponse(success: true, data: comentario, statusCode: response.statusCode);
          } else {
            return ApiResponse(
              success: false, 
              message: data['message'] ?? 'Formato de resposta inválido',
              statusCode: response.statusCode
            );
          }
        } catch (e) {
          // Se der erro no parse, criar localmente
          print('=== DEBUG: Erro no parse da resposta, criando localmente ===');
          return _criarComentarioLocal(
            materialId: materialId,
            topicoId: topicoId,
            disciplinaId: disciplinaId,
            texto: texto,
          );
        }
      } else if (response.statusCode == 404) {
        // API não encontrada - criar localmente
        print('=== DEBUG: API não encontrada, criando comentário local ===');
        return _criarComentarioLocal(
          materialId: materialId,
          topicoId: topicoId,
          disciplinaId: disciplinaId,
          texto: texto,
        );
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false, 
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false, 
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403
        );
      } else {
        // Para outros erros, criar localmente
        print('=== DEBUG: Erro HTTP ${response.statusCode}, criando localmente ===');
        return _criarComentarioLocal(
          materialId: materialId,
          topicoId: topicoId,
          disciplinaId: disciplinaId,
          texto: texto,
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.criarComentario: $e ===');
      // Em caso de erro, criar localmente
      return _criarComentarioLocal(
        materialId: materialId,
        topicoId: topicoId,
        disciplinaId: disciplinaId,
        texto: texto,
      );
    }
  }

  // Método auxiliar para criar comentário local
  static ApiResponse<Comentario> _criarComentarioLocal({
    required String materialId,
    required String topicoId,
    required String disciplinaId,
    required String texto,
  }) {
    try {
      final novoComentario = Comentario(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        materialId: materialId,
        topicoId: topicoId,
        disciplinaId: disciplinaId,
        autor: {'nome': 'Você', 'email': 'usuario@local.com'},
        autorModel: 'Usuario',
        texto: texto,
        respostas: [],
        dataCriacao: DateTime.now(),
        editado: false,
      );

      // Adicionar à lista local
      if (!_comentariosLocais.containsKey(materialId)) {
        _comentariosLocais[materialId] = [];
      }
      _comentariosLocais[materialId]!.insert(0, novoComentario);

      return ApiResponse(
        success: true, 
        data: novoComentario,
        statusCode: 200,
        message: 'Comentário salvo localmente'
      );
    } catch (e) {
      return ApiResponse(
        success: false, 
        message: 'Erro ao salvar comentário localmente: $e',
        statusCode: 500
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
          statusCode: 401
        );
      }

      final requestBody = {
        'texto': texto,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl$_apiPrefix/$comentarioId/respostas'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['success'] == true && data['data'] != null) {
          final comentario = Comentario.fromJson(data['data']);
          return ApiResponse(success: true, data: comentario, statusCode: 200);
        } else {
          return ApiResponse(
            success: false, 
            message: data['message'] ?? 'Formato de resposta inválido',
            statusCode: response.statusCode
          );
        }
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false, 
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false, 
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false, 
          message: 'Comentário não encontrado.',
          statusCode: 404
        );
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return ApiResponse(
          success: false, 
          message: errorData['message'] ?? 'Erro HTTP ${response.statusCode}',
          statusCode: response.statusCode
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.adicionarResposta: $e ===');
      return ApiResponse(
        success: false, 
        message: 'Erro de conexão: $e',
        statusCode: 500
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
          statusCode: 401
        );
      }

      final requestBody = {
        'texto': texto,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl$_apiPrefix/$comentarioId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['success'] == true && data['data'] != null) {
          final comentario = Comentario.fromJson(data['data']);
          return ApiResponse(success: true, data: comentario, statusCode: 200);
        } else {
          return ApiResponse(
            success: false, 
            message: data['message'] ?? 'Formato de resposta inválido',
            statusCode: response.statusCode
          );
        }
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false, 
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false, 
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false, 
          message: 'Comentário não encontrado.',
          statusCode: 404
        );
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return ApiResponse(
          success: false, 
          message: errorData['message'] ?? 'Erro HTTP ${response.statusCode}',
          statusCode: response.statusCode
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.editarComentario: $e ===');
      return ApiResponse(
        success: false, 
        message: 'Erro de conexão: $e',
        statusCode: 500
      );
    }
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
          statusCode: 401
        );
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl$_apiPrefix/$comentarioId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      print('=== DEBUG: Status Code: ${response.statusCode} ===');

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        
        if (data['success'] == true) {
          return ApiResponse(success: true, message: data['message'], statusCode: 200);
        } else {
          return ApiResponse(
            success: false, 
            message: data['message'] ?? 'Erro ao excluir comentário',
            statusCode: response.statusCode
          );
        }
      } else if (response.statusCode == 401) {
        return ApiResponse(
          success: false, 
          message: 'Acesso não autorizado. Faça login novamente.',
          statusCode: 401
        );
      } else if (response.statusCode == 403) {
        return ApiResponse(
          success: false, 
          message: 'Acesso negado. Verifique suas permissões.',
          statusCode: 403
        );
      } else if (response.statusCode == 404) {
        return ApiResponse(
          success: false, 
          message: 'Comentário não encontrado.',
          statusCode: 404
        );
      } else {
        final errorData = json.decode(utf8.decode(response.bodyBytes));
        return ApiResponse(
          success: false, 
          message: errorData['message'] ?? 'Erro HTTP ${response.statusCode}',
          statusCode: response.statusCode
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO ComentarioService.excluirComentario: $e ===');
      return ApiResponse(
        success: false, 
        message: 'Erro de conexão: $e',
        statusCode: 500
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
    this.statusCode
  });
}