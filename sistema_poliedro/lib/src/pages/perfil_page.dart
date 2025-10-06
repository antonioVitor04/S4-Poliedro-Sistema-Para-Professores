import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service_user.dart';
import '../models/usuario.dart';
import '../styles/fontes.dart';
import '../styles/cores.dart';
import '../utils/image_utils.dart';
import '../components/alerta.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final ApiService _apiService = ApiService();
  Usuario? _usuario;
  bool _isLoading = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  String _erro = '';
  TipoUsuario _tipoUsuarioAtual = TipoUsuario.aluno;
  Uint8List? _imagemBytes;
  int _imageVersion = 0; // CONTADOR PARA FORÇAR ATUALIZAÇÃO

  @override
  void initState() {
    super.initState();
    print('🚀 [INIT] PerfilPage iniciando...');
    _carregarTokenEConfigurar();
  }

  Future<void> _carregarTokenEConfigurar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        _apiService.setToken(token);
        final tipoUsuario = await _determinarTipoUsuario();
        _tipoUsuarioAtual = tipoUsuario;
        _apiService.setTipoUsuario(tipoUsuario);
        await _carregarDadosUsuario();
      } else {
        _mostrarErro('Usuário não autenticado. Faça login novamente.');
      }
    } catch (e) {
      _mostrarErro('Erro de autenticação: $e');
    }
  }

  Future<TipoUsuario> _determinarTipoUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final tipo = prefs.getString('tipoUsuario');
    return tipo == 'professor' ? TipoUsuario.professor : TipoUsuario.aluno;
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      final usuario = await _apiService.getPerfilUsuario();

      setState(() {
        _usuario = usuario;
        _emailController.text = usuario.email ?? '';
        _isLoading = false;
        _erro = '';
      });

      // USA APENAS O MÉTODO DEFINITIVO
      await _carregarImagem();
    } catch (e) {
      if (e.toString().contains('401') &&
          _tipoUsuarioAtual == TipoUsuario.aluno) {
        _tipoUsuarioAtual = TipoUsuario.professor;
        _apiService.setTipoUsuario(TipoUsuario.professor);
        await _carregarDadosUsuario();
        return;
      }
      _mostrarErro('Erro ao carregar perfil: $e');
    }
  }

  // MÉTODO SIMPLIFICADO E EFETIVO PARA CARREGAR IMAGEM
  // MÉTODO DEFINITIVO - ÚNICA VERSÃO QUE VOCÊ PRECISA
  Future<void> _carregarImagem() async {
    try {
      print('🔄 [DEFINITIVE] Iniciando carregamento de imagem...');

      // SEMPRE tenta carregar a imagem primeiro
      final bytes = await _apiService.getImagemUsuarioBytes(
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      // SE CHEGOU AQUI, TEM IMAGEM
      print('✅ [DEFINITIVE] Imagem carregada: ${bytes.length} bytes');
      setState(() {
        _imagemBytes = bytes;
        _imageVersion++;
        if (_usuario != null) {
          _usuario = _usuario!.copyWith(hasImage: true);
        }
      });
    } catch (e) {
      // SE DEU ERRO (404), NÃO TEM IMAGEM
      print('✅ [DEFINITIVE] Usuário não tem imagem: $e');
      setState(() {
        _imagemBytes = null;
        _imageVersion++;
        if (_usuario != null) {
          _usuario = _usuario!.copyWith(hasImage: false);
        }
      });
    }
  }

  // MÉTODO ULTRA-SIMPLES - Use este para testar rapidamente

  void _limparImagem() {
    setState(() {
      _imagemBytes = null;
      _imageVersion++; // INCREMENTA MESMO AO LIMPAR
    });
  }

  void _mostrarErro(String mensagem) {
    setState(() {
      _isLoading = false;
      _erro = mensagem;
    });
    _mostrarAlerta(mensagem, false);
  }

  void _mostrarAlerta(String mensagem, bool sucesso) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (context) => AlertaWidget(mensagem: mensagem, sucesso: sucesso),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  // MÉTODO DEFINITIVO PARA UPLOAD DE IMAGEM
  Future<void> _selecionarImagem() async {
    try {
      final imageFile = await ImageUtils.selecionarImagem();
      if (imageFile != null) {
        _mostrarAlerta('Enviando imagem...', true);

        final bytes = await imageFile.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileNameWithTimestamp = 'profile_$timestamp.jpg';
        final base64Image = base64Encode(bytes);

        // FAZ UPLOAD
        await _apiService.uploadImagemBase64(
          base64Image,
          fileNameWithTimestamp,
        );

        // ATUALIZAÇÃO IMEDIATA
        setState(() {
          _imagemBytes = Uint8List.fromList(bytes);
          _imageVersion++;
          if (_usuario != null) {
            _usuario = _usuario!.copyWith(hasImage: true);
          }
        });

        _mostrarAlerta('Imagem atualizada com sucesso!', true);
      }
    } catch (e) {
      _mostrarAlerta('Erro ao atualizar imagem: $e', false);
    }
  }

  // MÉTODO DEFINITIVO PARA REMOVER IMAGEM
  Future<void> _removerImagem() async {
    try {
      print('🗑️ [REMOVE] Iniciando remoção de imagem...');

      await _apiService.removerImagemUsuario();

      // ATUALIZAÇÃO IMEDIATA E DEFINITIVA
      setState(() {
        _imagemBytes = null;
        _imageVersion++;
        if (_usuario != null) {
          _usuario = _usuario!.copyWith(hasImage: false);
        }
      });

      print('✅ [REMOVE] Imagem removida localmente');
      _mostrarAlerta('Imagem removida com sucesso!', true);
    } catch (e) {
      print('❌ [REMOVE] Erro: $e');
      _mostrarAlerta('Erro ao remover imagem: $e', false);
    }
  }

  // MODAL DE EDIÇÃO (mantido igual)
  void _abrirModalEditarPerfil() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: _buildModalEditarPerfil(),
      ),
    );
  }

  Widget _buildModalEditarPerfil() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 32,
                          color: AppColors.azulClaro,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Editar Perfil',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Atualize suas informações',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Email
                TextFormField(
                  controller: _emailController,
                  cursorColor: AppColors.azulClaro,
                  style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Email*',
                    labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.preto.withOpacity(0.1),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.azulClaro,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: Icon(Icons.email, color: AppColors.azulClaro),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira um email';
                    }
                    if (!value.contains('@')) {
                      return 'Por favor, insira um email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Nova Senha
                TextFormField(
                  controller: _senhaController,
                  cursorColor: AppColors.azulClaro,
                  obscureText: true,
                  style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                  decoration: InputDecoration(
                    labelText: 'Nova Senha (opcional)',
                    labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                      color: Colors.black,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.preto.withOpacity(0.1),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.azulClaro,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    prefixIcon: Icon(Icons.lock, color: AppColors.azulClaro),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Botões
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _senhaController.clear();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _atualizarPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulClaro,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _atualizarPerfil() async {
    try {
      final novoEmail = _emailController.text.isEmpty
          ? null
          : _emailController.text;
      final novaSenha = _senhaController.text.isEmpty
          ? null
          : _senhaController.text;

      await _apiService.atualizarPerfilUsuario(
        email: novoEmail,
        senha: novaSenha,
      );

      _senhaController.clear();
      Navigator.pop(context);
      await _carregarDadosUsuario();
      _mostrarAlerta('Perfil atualizado com sucesso!', true);
    } catch (e) {
      _mostrarAlerta('Erro ao atualizar perfil: $e', false);
    }
  }

  String _getMensagemBoasVindas() {
    if (_usuario == null) return "Bem-vindo!";
    return _usuario!.tipo == TipoUsuario.professor
        ? "Bem-vindo, Professor ${_usuario!.nome}!"
        : "Bem-vindo, ${_usuario!.nome}!";
  }

  String _getIdentificadorLabel() {
    if (_usuario == null) return "";
    return _usuario!.tipo == TipoUsuario.professor
        ? "Email Institucional"
        : "RA";
  }

  String _getIdentificadorValor() {
    if (_usuario == null) return "";
    return _usuario!.tipo == TipoUsuario.professor
        ? _usuario!.email ?? ''
        : _usuario!.ra ?? '';
  }

  void _fazerLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('tipoUsuario');
    Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
              const SizedBox(height: 16),
              Text(
                'Carregando perfil...',
                style: AppTextStyles.fonteUbuntu.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_usuario == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Erro ao carregar perfil',
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _erro,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _carregarTokenEConfigurar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Tentar Novamente',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                top: 60,
                bottom: 30,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child:
                              _imagemBytes != null && _imagemBytes!.isNotEmpty
                              ? Image.memory(
                                  _imagemBytes!,
                                  fit: BoxFit.cover,
                                  key: Key(
                                    'profile_image_${_imageVersion}_${_imagemBytes!.hashCode}',
                                  ), // KEY ÚNICA COMBINADA
                                  errorBuilder: (context, error, stackTrace) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback(
                                          (_) => _limparImagem(),
                                        );
                                    return _buildIconePadrao();
                                  },
                                )
                              : _buildIconePadrao(),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.blue.shade600,
                            ),
                            onPressed: _selecionarImagem,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getMensagemBoasVindas(),
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _usuario!.tipo == TipoUsuario.professor
                          ? "PROFESSOR"
                          : "ALUNO",
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_outline,
                                size: 20,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dados Pessoais',
                                style: AppTextStyles.fonteUbuntu.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoItem(
                          'Nome',
                          _usuario!.nome,
                          Icons.badge_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          _getIdentificadorLabel(),
                          _getIdentificadorValor(),
                          _usuario!.tipo == TipoUsuario.professor
                              ? Icons.email_outlined
                              : Icons.numbers_outlined,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.edit, size: 20),
                            label: const Text('Editar Perfil'),
                            onPressed: _abrirModalEditarPerfil,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_usuario!.hasImage && _imagemBytes != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.purple.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.photo_camera_outlined,
                                  size: 20,
                                  color: Colors.purple.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Imagem de Perfil',
                                style: AppTextStyles.fonteUbuntu.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gerencie sua foto de perfil',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              label: const Text('Remover Imagem'),
                              onPressed: _removerImagem,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade600,
                                side: BorderSide(color: Colors.red.shade300),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.security_outlined,
                                size: 20,
                                color: Colors.orange.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sessão',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Gerencie sua sessão atual',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.logout, size: 20),
                            label: const Text('Sair da Conta'),
                            onPressed: _fazerLogout,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red.shade600,
                              side: BorderSide(color: Colors.red.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconePadrao() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        _usuario!.tipo == TipoUsuario.professor ? Icons.school : Icons.person,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }
}
