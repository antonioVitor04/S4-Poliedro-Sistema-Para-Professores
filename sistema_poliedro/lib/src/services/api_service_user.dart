import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/usuario.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
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
    return _tipoUsuario == TipoUsuario.professor
        ? '$baseUrl/professores'
        : '$baseUrl/alunos';
  }

  Future<Usuario> getPerfilUsuario() async {
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
        'Falha ao carregar perfil - Status: ${response.statusCode}',
      );
    }
  }

  Future<void> atualizarPerfilUsuario({
    String? nome,
    String? email,
    String? senha,
  }) async {
    final Map<String, dynamic> body = {};
    if (nome != null) body['nome'] = nome;
    if (email != null) body['email'] = email;
    if (senha != null) body['senha'] = senha;

    final response = await http.put(
      Uri.parse('$endpointBase/update'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao atualizar perfil');
    }
  }

  // NO ApiService - ADICIONE ESTE MÉTODO DE DEBUG
  Future<Uint8List> getImagemUsuarioBytes({int? timestamp}) async {
    try {
      print('🔍 [DEBUG] Carregando imagem...');

      // URL CORRETA: /api/alunos/image ou /api/professores/image
      final url = timestamp != null
          ? '$endpointBase/image?t=$timestamp'
          : '$endpointBase/image';

      print('🔍 [DEBUG] URL: $url');

      final response = await http.get(Uri.parse(url), headers: headers);

      print('🔍 [DEBUG] Status: ${response.statusCode}');
      print('🔍 [DEBUG] Bytes: ${response.bodyBytes.length}');

      if (response.statusCode == 200) {
        if (response.bodyBytes.isEmpty) {
          throw Exception('Imagem vazia');
        }
        return response.bodyBytes;
      } else if (response.statusCode == 404) {
        // 404 significa que o usuário NÃO TEM imagem
        throw Exception('Usuário não tem imagem');
      } else {
        throw Exception('Falha ao carregar imagem: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [DEBUG] Erro: $e');
      rethrow;
    }
  }

  Future<void> removerImagemUsuario() async {
    final response = await http.delete(
      Uri.parse('$endpointBase/remove-image'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao remover imagem');
    }
  }

  // CORREÇÃO: Usar a rota update-image-base64 para AMBOS
  Future<void> uploadImagemBase64(String base64Image, String filename) async {
    final response = await http.put(
      Uri.parse('$endpointBase/update-image-base64'), // ROTA PADRONIZADA
      headers: headers,
      body: jsonEncode({
        'imagem': base64Image,
        'filename': filename,
        'contentType': 'image/${filename.split('.').last}',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Falha ao fazer upload da imagem');
    }
  }
}
