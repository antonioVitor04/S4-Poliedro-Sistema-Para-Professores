import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import 'package:sistema_poliedro/src/styles/fontes.dart';
import 'package:sistema_poliedro/src/components/alerta.dart';
import './codigo_verificacao.dart';
import 'package:sistema_poliedro/src/services/auth_service.dart';

class Recuperar_Senha extends StatefulWidget {
  const Recuperar_Senha({super.key});

  @override
  State<Recuperar_Senha> createState() => _Recuperar_SenhaState();
}

class _Recuperar_SenhaState extends State<Recuperar_Senha> {
  final TextEditingController emailController = TextEditingController();
  bool _carregando = false;

  void mostrarAlerta(String mensagem, bool sucesso) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (context) => AlertaWidget(mensagem: mensagem, sucesso: sucesso),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    });
  }

  // Função que verifica o email digitado e envia
  Future<void> verificaEmailEEnvia() async {
    final String email = emailController.text.trim();

    if (email.isEmpty) {
      mostrarAlerta("Por favor, digite um e-mail", false);
      return;
    }

    try {
      setState(() {
        _carregando = true;
      });

      await AuthService.sendVerificationCode(email);

      mostrarAlerta("Código enviado para $email", true);

      // Redireciona após o alerta fechar
      Future.delayed(const Duration(seconds: 3), () {
        redirecionaParaInserirCodigo(email);
      });
    } on Exception catch (e) {
      final mensagem = e.toString().replaceFirst('Exception: ', '');
      mostrarAlerta(mensagem.isEmpty ? "Erro ao enviar código" : mensagem, false);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // Função para redirecionar para a tela de inserir código
  Future<void> redirecionaParaInserirCodigo(String email) async {
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CodigoVerificacao(email: email)),
    );
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

        // LADO DIREITO - FORMULÁRIO DE RECUPERAÇÃO
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.branco,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: _buildRecuperacaoForm(isDesktop: true),
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
          child: _buildRecuperacaoForm(isDesktop: false),
        ),
      ),
    );
  }

  Widget _buildRecuperacaoForm({bool isDesktop = true}) {
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // LOGO NO MOBILE (dentro do card)
          if (!isDesktop) ...[
            Column(
              children: [
                Image.asset('assets/images/logo.png', width: 70, height: 110),
                const SizedBox(height: 30),
              ],
            ),
          ],

          Text(
            "Recuperar Senha",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Digite seu e-mail para receber um código de verificação",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 16,
              color: AppColors.preto.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // AVISO IMPORTANTE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.redAccent.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.redAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Utilize o e-mail cadastrado em nossa plataforma",
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 14,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // CAMPO DE EMAIL
          SizedBox(width: double.infinity, child: _campoEmail()),

          const SizedBox(height: 30),

          // BOTÃO ENVIAR
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulClaro,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _carregando ? null : verificaEmailEEnvia,
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
                      "Enviar Código",
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

  Widget _campoEmail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Email",
          style: AppTextStyles.fonteUbuntu.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: emailController,
          cursorColor: AppColors.azulClaro,
          style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: "exemplo@poliedro.com",
            hintStyle: TextStyle(color: AppColors.preto.withOpacity(0.4)),
            filled: true,
            fillColor: AppColors.azulClaro.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            prefixIcon: Icon(Icons.email_outlined, color: AppColors.azulClaro),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }
}