import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/services/auth_service.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import 'package:sistema_poliedro/src/styles/fontes.dart';
import 'package:sistema_poliedro/src/components/alerta.dart';

class NovaSenha extends StatefulWidget {
  final String email;
  final String codigo;
  const NovaSenha({super.key, required this.email, required this.codigo});

  @override
  State<NovaSenha> createState() => _NovaSenhaState();
}

class _NovaSenhaState extends State<NovaSenha> {
  final TextEditingController novaSenhaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();
  bool _carregando = false;
  bool _senhaVisivel = false;
  bool _confirmarSenhaVisivel = false;

  void mostrarAlerta(String mensagem, bool sucesso) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        });

        return AlertaWidget(mensagem: mensagem, sucesso: sucesso);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    // Adiciona listeners para atualizar a UI quando o texto mudar
    novaSenhaController.addListener(_updateUI);
    confirmarSenhaController.addListener(_updateUI);
  }

  void _updateUI() {
    setState(() {}); // Força o rebuild do widget
  }

  @override
  void dispose() {
    // Limpa os controllers quando o widget for destruído
    novaSenhaController.removeListener(_updateUI);
    confirmarSenhaController.removeListener(_updateUI);
    novaSenhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  // Função para verificar se a senha tem pelo menos uma letra maiúscula
  bool get hasUpperCase {
    return novaSenhaController.text.contains(RegExp(r'[A-Z]'));
  }

  // Função para verificar se a senha tem pelo menos um número
  bool get hasNumber {
    return novaSenhaController.text.contains(RegExp(r'[0-9]'));
  }

  //funcao para verificar se as senhas são iguais
  bool get senhasIguais {
    if (novaSenhaController.text.isEmpty ||
        confirmarSenhaController.text.isEmpty) {
      return false;
    }
    return novaSenhaController.text == confirmarSenhaController.text;
  }

  //funcao para verificar se possui um simbolo
  bool get hasSymbol {
    return novaSenhaController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  }

  // Função para verificar se todos os requisitos da senha estão atendidos
  bool get senhaAtendeRequisitos {
    return novaSenhaController.text.length >= 8 &&
        hasUpperCase &&
        hasNumber &&
        hasSymbol &&
        senhasIguais;
  }

  // Função para chamar a API e atualizar a senha
  Future<void> _atualizarSenha() async {
    if (!senhaAtendeRequisitos) {
      mostrarAlerta("A senha não atende aos requisitos", false);
      return;
    }

    try {
      setState(() {
        _carregando = true;
      });

      await AuthService.updatePassword(widget.email, widget.codigo, novaSenhaController.text);

      mostrarAlerta("Senha alterada com sucesso!", true);

      // Aguardar 2 segundos antes de redirecionar
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.pushReplacementNamed(context, "/login");
      }
    } on Exception catch (error) {
      final mensagem = error.toString().replaceFirst('Exception: ', '');
      mostrarAlerta(mensagem.isEmpty ? "Erro ao atualizar senha" : mensagem, false);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Scaffold(
      backgroundColor: AppColors.branco,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // LADO ESQUERDO - LOGO E BRANDING
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.azulClaro,
                  AppColors.azulClaro.withOpacity(0.8),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 180,
                      height: 260,
                      color: Colors.white,
                      colorBlendMode: BlendMode.modulate,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "Poliedro",
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    "Educação",
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 56,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Sistema de Gestão Educacional",
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // LADO DIREITO - FORMULÁRIO DE NOVA SENHA
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.branco,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: _buildNovaSenhaForm(isDesktop: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: _buildNovaSenhaForm(isDesktop: false),
        ),
      ),
    );
  }

  Widget _buildNovaSenhaForm({bool isDesktop = true}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 450),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // LOGO NO MOBILE (dentro do card)
          if (!isDesktop) ...[
            Center(
              child: Column(
                children: [
                  Image.asset('assets/images/logo.png', width: 70, height: 110),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],

          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "Nova Senha",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.preto,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Crie uma senha forte para sua conta",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontSize: 16,
                    color: AppColors.preto.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),

          // CAMPO NOVA SENHA
          SizedBox(
            width: double.infinity,
            child: _campoNovaSenha(),
          ),

          const SizedBox(height: 20),

          // CAMPO CONFIRMAR SENHA
          SizedBox(
            width: double.infinity,
            child: _campoConfirmarSenha(),
          ),

          const SizedBox(height: 30),

          // REQUISITOS DA SENHA
          Text(
            "Sua senha deve conter:",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.preto,
            ),
          ),
          const SizedBox(height: 16),
          _buildRequisitoSenha(
            "Mínimo de 8 caracteres",
            novaSenhaController.text.length >= 8,
          ),
          const SizedBox(height: 10),
          _buildRequisitoSenha("Pelo menos uma letra maiúscula", hasUpperCase),
          const SizedBox(height: 10),
          _buildRequisitoSenha("Pelo menos um número", hasNumber),
          const SizedBox(height: 10),
          _buildRequisitoSenha("Pelo menos um símbolo", hasSymbol),
          const SizedBox(height: 10),
          _buildRequisitoSenha("As senhas devem ser iguais", senhasIguais),

          const SizedBox(height: 30),

          // BOTÃO SALVAR SENHA
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulClaro,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _carregando ? null : _atualizarSenha,
              child: _carregando
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "Salvar Nova Senha",
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // BOTÃO VOLTAR PARA LOGIN
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18, color: AppColors.azulClaro),
                  const SizedBox(width: 8),
                  Text(
                    "Voltar para o login",
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.azulClaro,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoNovaSenha() {
    return TextFormField(
      controller: novaSenhaController,
      cursorColor: AppColors.azulClaro,
      obscureText: !_senhaVisivel,
      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Nova Senha*',
        labelStyle: AppTextStyles.fonteUbuntu.copyWith(color: Colors.black),
        hintStyle: AppTextStyles.fonteUbuntu.copyWith(
          color: AppColors.preto.withOpacity(0.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(Icons.lock, color: AppColors.azulClaro),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.preto.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _senhaVisivel ? Icons.visibility : Icons.visibility_off,
            color: AppColors.azulClaro,
          ),
          onPressed: () {
            setState(() {
              _senhaVisivel = !_senhaVisivel;
            });
          },
        ),
      ),
    );
  }

  Widget _campoConfirmarSenha() {
    return TextFormField(
      controller: confirmarSenhaController,
      cursorColor: AppColors.azulClaro,
      obscureText: !_confirmarSenhaVisivel,
      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Confirmar Senha*',
        labelStyle: AppTextStyles.fonteUbuntu.copyWith(color: Colors.black),
        hintStyle: AppTextStyles.fonteUbuntu.copyWith(
          color: AppColors.preto.withOpacity(0.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(Icons.lock, color: AppColors.azulClaro),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.preto.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _confirmarSenhaVisivel ? Icons.visibility : Icons.visibility_off,
            color: AppColors.azulClaro,
          ),
          onPressed: () {
            setState(() {
              _confirmarSenhaVisivel = !_confirmarSenhaVisivel;
            });
          },
        ),
      ),
    );
  }

  Widget _buildRequisitoSenha(String texto, bool atendido) {
    return Row(
      children: [
        Icon(
          atendido ? Icons.check_circle : Icons.cancel,
          color: atendido ? AppColors.verdeConfirmacao : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            texto,
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 12,
              color: AppColors.preto.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}