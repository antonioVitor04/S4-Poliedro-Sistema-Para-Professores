import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/modelo_usuario.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  static String get _baseUrl {
    if (kIsWeb) {
      return dotenv.env['BASE_URL_WEB']!;
    }
    return dotenv.env['BASE_URL_MOBILE']!;
  }

  static const String _apiPrefix = '/api';  

  final Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': '',
  };

  TipoUsuario _tipoUsuario = TipoUsuario.aluno;

  void setTipoUsuario(TipoUsuario tipo) {
    _tipoUsuario = tipo;
  }

  void setToken(String token) {
    headers['Authorization'] = 'Bearer $token';
  }

  String get endpointBase {
    final basePath = _tipoUsuario == TipoUsuario.professor ? 'professores' : 'alunos';
    return '$_baseUrl$_apiPrefix/$basePath';  
  }

  Future<Usuario> getPerfilUsuario() async {
    try {


      final response = await http.get(
        Uri.parse('$endpointBase/'), 
        headers: headers,
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final usuarioData = data['professor'] ?? data['aluno'] ?? data;
        return Usuario.fromJson(usuarioData, _tipoUsuario);
      } else {
        throw Exception(
          'Falha ao carregar perfil - Status: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ [DEBUG] Erro no perfil: $e');
      rethrow;
    }
  }

  Future<void> atualizarPerfilUsuario({
    String? nome,
    String? email,
    String? senha,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (nome != null) body['nome'] = nome;
      if (email != null) body['email'] = email;
      if (senha != null) body['senha'] = senha;


      final response = await http.put(
        Uri.parse('$endpointBase/update'),  // Agora com /api/
        headers: headers,
        body: jsonEncode(body),
      );


      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Falha ao atualizar perfil: ${errorData['msg'] ?? response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List> getImagemUsuarioBytes({int? timestamp}) async {
    try {
      print('🔍 [DEBUG] Iniciando download da imagem...');

      final url = timestamp != null
          ? '$endpointBase/image?t=$timestamp'
          : '$endpointBase/image';

      print('🔍 [DEBUG] URL da imagem: $url');  // Agora com /api/
      print(
        '🔍 [DEBUG] Headers: ${headers['Authorization']?.substring(0, 20)}...',
      );

      final response = await http.get(Uri.parse(url), headers: headers);

      print('🔍 [DEBUG] Status Code: ${response.statusCode}');
      print('🔍 [DEBUG] Content-Type: ${response.headers['content-type']}');
      print('🔍 [DEBUG] Tamanho dos bytes: ${response.bodyBytes.length}');

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          print('⚠️ [DEBUG] Resposta vazia - tratando como sem imagem');
          throw Exception('Usuário não tem imagem');
        }

        print(
          '✅ [DEBUG] Imagem baixada com sucesso: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        print('❌ [DEBUG] Imagem não encontrada (404)');
        throw Exception('Usuário não tem imagem');
      } else {
        print('❌ [DEBUG] Erro HTTP: ${response.statusCode} - ${response.body}');
        throw Exception('Falha ao carregar imagem: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [DEBUG] Erro no download: $e');
      rethrow;
    }
  }

  Future<void> removerImagemUsuario() async {
    try {
      print('🗑️ [DEBUG] Iniciando remoção de imagem...');

      final response = await http.delete(
        Uri.parse('$endpointBase/remove-image'),  // Agora com /api/
        headers: headers,
      );

      print('🗑️ [DEBUG] Status da remoção: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Falha ao remover imagem: ${errorData['msg'] ?? response.statusCode}',
        );
      }

      print('✅ [DEBUG] Imagem removida com sucesso');
    } catch (e) {
      print('❌ [DEBUG] Erro na remoção: $e');
      rethrow;
    }
  }

  Future<void> uploadImagemBase64(String base64Image, String filename) async {
    try {
      print('📤 [DEBUG] Iniciando upload da imagem...');
      print('📤 [DEBUG] Tamanho base64: ${base64Image.length} caracteres');
      print('📤 [DEBUG] Nome do arquivo: $filename');

      // ✅ CORREÇÃO: Determina contentType corretamente
      String contentType;
      if (filename.toLowerCase().endsWith('.png')) {
        contentType = 'image/png';
      } else if (filename.toLowerCase().endsWith('.gif')) {
        contentType = 'image/gif';
      } else if (filename.toLowerCase().endsWith('.webp')) {
        contentType = 'image/webp';
      } else {
        contentType = 'image/jpeg'; // padrão para jpg/jpeg
      }

      print('📤 [DEBUG] Content-Type: $contentType');

      // ✅ CORREÇÃO CRÍTICA: Criar data URL completa
      final String dataUrl = 'data:$contentType;base64,$base64Image';

      print('📤 [DEBUG] Data URL criada: ${dataUrl.substring(0, 50)}...');

      final body = jsonEncode({
        'imagem': dataUrl, // ✅ Agora envia data URL completa
        'filename': filename,
        'contentType': contentType,
      });

      print('📤 [DEBUG] Tamanho do body: ${body.length} caracteres');

      final response = await http.put(
        Uri.parse('$endpointBase/update-image-base64'),  // Agora com /api/
        headers: headers,
        body: body,
      );

      print('📤 [DEBUG] Status do upload: ${response.statusCode}');
      print('📤 [DEBUG] Resposta: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ [DEBUG] Upload realizado com sucesso!');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Falha ao fazer upload: ${errorData['msg'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ [DEBUG] Erro no upload: $e');
      rethrow;
    }
  }

  Future<bool> verificarSeTemImagem() async {
    try {
      // Tenta baixar a imagem
      final bytes = await getImagemUsuarioBytes();
      return bytes.isNotEmpty;
    } catch (e) {
      // Se deu erro (404 ou vazio), não tem imagem
      print('⚠️ [DEBUG] Verificação: Não tem imagem ($e)');
      return false;
    }
  }
}