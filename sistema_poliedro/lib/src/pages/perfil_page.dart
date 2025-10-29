import 'dart:async'; // <-- para o timer do alerta
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';
import '../models/modelo_usuario.dart'; // Certifique-se que esta importação está correta
import '../styles/fontes.dart';
import '../utils/image_utils.dart';
import '../components/alerta.dart';
import '../dialogs/editar_perfil_dialog.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final UserService _userService = UserService();
  Usuario? _usuario;
  bool _isLoading = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  String _erro = '';
  TipoUsuario _tipoUsuarioAtual = TipoUsuario.aluno;
  Uint8List? _imagemBytes;
  int _imageVersion = 0;

  // --- estado do alerta padronizado (canto superior direito) ---
  String? _alertaMensagem;
  bool _alertaSucesso = false;
  Timer? _alertaTimer;

  @override
  void initState() {
    super.initState();
    _carregarTokenEConfigurar();
  }

  // CORREÇÃO: Método para converter string para TipoUsuario
  TipoUsuario _stringParaTipoUsuario(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'professor':
        return TipoUsuario.professor;
      case 'admin':
        return TipoUsuario.professor; // ou crie um TipoUsuario.admin se necessário
      default:
        return TipoUsuario.aluno;
    }
  }

  // CORREÇÃO: Método para converter TipoUsuario para string
  String _tipoUsuarioParaString(TipoUsuario tipo) {
    switch (tipo) {
      case TipoUsuario.professor:
        return 'professor';
      case TipoUsuario.aluno:
        return 'aluno';
    }
  }

  Future<void> _carregarTokenEConfigurar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        _userService.setToken(token);
        final tipoUsuario = await _determinarTipoUsuario();
        _tipoUsuarioAtual = tipoUsuario;
        _userService.setTipoUsuario(tipoUsuario);
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
    return _stringParaTipoUsuario(tipo ?? 'aluno');
  }

  Future<void> _carregarDadosUsuario() async {
    try {
      final usuario = await _userService.getPerfilUsuario();

      setState(() {
        _usuario = usuario;
        _emailController.text = usuario.email;
        _isLoading = false;
        _erro = '';
      });

      await _carregarImagem();
    } catch (e) {
      if (e.toString().contains('401') && _tipoUsuarioAtual == TipoUsuario.aluno) {
        _tipoUsuarioAtual = TipoUsuario.professor;
        _userService.setTipoUsuario(TipoUsuario.professor);
        await _carregarDadosUsuario();
        return;
      }
      _mostrarErro('Erro ao carregar perfil: $e');
    }
  }

  Future<void> _carregarImagem() async {
    try {
      if (_usuario != null && _usuario!.hasImage) {
        final bytes = await _userService.getImagemUsuarioBytes(
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        if (bytes.isNotEmpty) {
          setState(() {
            _imagemBytes = bytes;
            _imageVersion++;
          });
          return;
        }
      }

      setState(() {
        _imagemBytes = null;
        _imageVersion++;
      });
    } catch (e) {
      setState(() {
        _imagemBytes = null;
        _imageVersion++;
      });
    }
  }

  void _limparImagem() {
    setState(() {
      _imagemBytes = null;
      _imageVersion++;
    });
  }

  void _mostrarErro(String mensagem) {
    setState(() {
      _isLoading = false;
      _erro = mensagem;
    });
    _mostrarAlerta(mensagem, false);
  }

  // --- padronização: usa o AlertaWidget no canto superior direito ---
  void _mostrarAlerta(String mensagem, bool sucesso) {
    // cancelar timer anterior, se houver
    _alertaTimer?.cancel();

    setState(() {
      _alertaMensagem = mensagem;
      _alertaSucesso = sucesso;
    });

    // auto-hide após 2.5s (ajuste se quiser)
    _alertaTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _alertaMensagem = null;
        });
      }
    });
  }

  Future<void> _selecionarImagem() async {
    try {
      final imageFile = await ImageUtils.selecionarImagem();
      if (imageFile != null) {
        _mostrarAlerta('Enviando imagem...', true);

        final bytes = await imageFile.readAsBytes();
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        if (bytes.length > 5 * 1024 * 1024) {
          _mostrarAlerta('Imagem muito grande. Máximo: 5MB', false);
          return;
        }

        final base64Image = base64Encode(bytes);

        await _userService.uploadImagemBase64(
          base64Image,
          'profile_$timestamp.jpg',
        );

        setState(() {
          _imagemBytes = bytes;
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

  Future<void> _removerImagem() async {
    try {
      await _userService.removerImagemUsuario();

      setState(() {
        _imagemBytes = null;
        _imageVersion++;
        if (_usuario != null) {
          _usuario = _usuario!.copyWith(hasImage: false);
        }
      });

      _mostrarAlerta('Imagem removida com sucesso!', true);
    } catch (e) {
      _mostrarAlerta('Erro ao remover imagem: $e', false);
    }
  }

  void _abrirModalEditarPerfil() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => EditarPerfilDialog(
        emailAtual: _usuario?.email ?? '',
        onConfirm: (email, senha) async {
          try {
            await _userService.atualizarPerfilUsuario(
              email: email,
              senha: senha,
            );

            await _carregarDadosUsuario();
            _mostrarAlerta('Perfil atualizado com sucesso!', true);
          } catch (e) {
            _mostrarAlerta('Erro ao atualizar perfil: $e', false);
          }
        },
      ),
    );
  }

  // CORREÇÃO: Método para verificar se é professor
  bool get _isProfessor {
    return _usuario?.tipoUsuario == TipoUsuario.professor;
  }

  String _getMensagemBoasVindas() {
    if (_usuario == null) return "Bem-vindo!";
    return _isProfessor
        ? "Bem-vindo, Professor ${_usuario!.nome}!"
        : "Bem-vindo, ${_usuario!.nome}!";
  }

  String _getIdentificadorLabel() {
    if (_usuario == null) return "";
    return _isProfessor ? "Email Institucional" : "RA";
  }

  String _getIdentificadorValor() {
    if (_usuario == null) return "";
    return _isProfessor ? _usuario!.email : _usuario!.ra ?? '';
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

  // --- overlay do alerta (usa diretamente seu AlertaWidget)
  Widget _buildAlertaOverlay() {
    if (_alertaMensagem == null) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: true, // não bloqueia toques na tela
      child: AlertaWidget(
        mensagem: _alertaMensagem!,
        sucesso: _alertaSucesso,
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

    // --- principal: apenas envolve o body em Stack e coloca o overlay
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          SingleChildScrollView(
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
                              child: _imagemBytes != null && _imagemBytes!.isNotEmpty
                                  ? Image.memory(
                                      _imagemBytes!,
                                      fit: BoxFit.cover,
                                      key: ValueKey('profile_image_$_imageVersion'),
                                      errorBuilder: (context, error, stackTrace) {
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
                          _isProfessor ? "PROFESSOR" : "ALUNO",
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
                              _isProfessor ? Icons.email_outlined : Icons.numbers_outlined,
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
          // overlay do alerta padronizado
          _buildAlertaOverlay(),
        ],
      ),
    );
  }

  Widget _buildIconePadrao() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(
        _isProfessor ? Icons.school : Icons.person,
        size: 40,
        color: Colors.grey.shade400,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    _alertaTimer?.cancel(); // limpa o timer do alerta
    super.dispose();
  }
}
