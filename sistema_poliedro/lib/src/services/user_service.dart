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
    final basePath = _tipoUsuario == TipoUsuario.professor
        ? 'professores'
        : 'alunos';
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

        // CORREÇÃO: Remover o segundo argumento _tipoUsuario
        return Usuario.fromJson(usuarioData);
      } else {
        throw Exception(
          'Falha ao carregar perfil - Status: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
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
        Uri.parse('$endpointBase/update'), // Agora com /api/
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Falha ao atualizar perfil: ${errorData['msg'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Uint8List> getImagemUsuarioBytes({int? timestamp}) async {
    try {
      final url = timestamp != null
          ? '$endpointBase/image?t=$timestamp'
          : '$endpointBase/image';

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          throw Exception('Usuário não tem imagem');
        }

        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        throw Exception('Usuário não tem imagem');
      } else {
        throw Exception('Falha ao carregar imagem: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removerImagemUsuario() async {
    try {
      final response = await http.delete(
        Uri.parse('$endpointBase/remove-image'), // Agora com /api/
        headers: headers,
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Falha ao remover imagem: ${errorData['msg'] ?? response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> uploadImagemBase64(String base64Image, String filename) async {
    try {
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

      // ✅ CORREÇÃO CRÍTICA: Criar data URL completa
      final String dataUrl = 'data:$contentType;base64,$base64Image';

      final body = jsonEncode({
        'imagem': dataUrl, // ✅ Agora envia data URL completa
        'filename': filename,
        'contentType': contentType,
      });

      final response = await http.put(
        Uri.parse('$endpointBase/update-image-base64'), // Agora com /api/
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
          'Falha ao fazer upload: ${errorData['msg'] ?? response.statusCode}',
        );
      }
    } catch (e) {
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
      return false;
    }
  }
}
