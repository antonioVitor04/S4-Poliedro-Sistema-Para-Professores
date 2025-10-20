import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/pages/login/Recuperar_Senha.dart';
import 'package:sistema_poliedro/src/services/auth_service.dart';
import '../../models/modelo_usuario.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import 'package:sistema_poliedro/src/styles/fontes.dart';
import 'package:sistema_poliedro/src/components/alerta.dart';
import 'dart:convert';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();
  String paginaAtual = "aluno";
  bool _senhaVisivel = false;

  void mostrarAlerta(String mensagem, bool sucesso) {
    // Check if the widget is still mounted before showing dialog
    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (context) {
        // Use a timer instead of Future.delayed to avoid context issues
        Timer(const Duration(seconds: 2), () {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        });

        return AlertaWidget(mensagem: mensagem, sucesso: sucesso);
      },
    );
  }

  Future<void> login() async {
    final emailOuRA = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (emailOuRA.isEmpty || senha.isEmpty) {
      mostrarAlerta("Por favor, preencha todos os campos.", false);
      return;
    }

    try {
      await AuthService.login(emailOuRA, senha, paginaAtual);

      // Check if widget is still mounted before navigation
      if (!mounted) return;

      if (paginaAtual == "professor") {
        Navigator.pushReplacementNamed(context, '/professor_protected');
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/aluno_protected',
          arguments: {'initialRoute': '/disciplinas'},
        );
      }
    } on Exception catch (e) {
      // Check if widget is still mounted before showing alert
      if (!mounted) return;

      final mensagem = e.toString().replaceFirst('Exception: ', '');
      if (mensagem.contains('login')) {
        mostrarAlerta("Erro no login. Verifique suas credenciais.", false);
      } else {
        mostrarAlerta("Erro na requisição. Tente novamente mais tarde.", false);
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

        // LADO DIREITO - FORMULÁRIO DE LOGIN
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.branco,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: _buildLoginForm(isDesktop: true),
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
          child: _buildLoginForm(isDesktop: false),
        ),
      ),
    );
  }

  Widget _buildLoginForm({required bool isDesktop}) {
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
            "Bem-vindo!",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Entre com suas credenciais",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 16,
              color: AppColors.preto.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 35),

          // SELETOR DE TIPO DE USUÁRIO
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.azulClaro.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _tipoUsuarioBotaoModerno("Professor")),
                Expanded(child: _tipoUsuarioBotaoModerno("Aluno")),
              ],
            ),
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: _campoTexto(tipo: paginaAtual),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: _campoSenha()),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // Use push instead of pushReplacement to avoid disposing the current view immediately
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Recuperar_Senha()),
                );
              },
              child: Text(
                "Esqueci minha senha",
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.azulClaro,
                ),
              ),
            ),
          ),

          const SizedBox(height: 25),

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
              onPressed: login,
              child: Text(
                "Entrar",
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipoUsuarioBotaoModerno(String tipo) {
    final bool selecionado = paginaAtual.toLowerCase() == tipo.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          paginaAtual = tipo.toLowerCase();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.azulClaro : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            tipo,
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 16,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
              color: selecionado
                  ? Colors.white
                  : AppColors.preto.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoTexto({required String tipo}) {
    return TextFormField(
      controller: emailController,
      cursorColor: AppColors.azulClaro,
      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
      decoration: InputDecoration(
        labelText: tipo == "professor" ? "Email*" : "RA*",
        labelStyle: AppTextStyles.fonteUbuntu.copyWith(color: Colors.black),
        hintStyle: AppTextStyles.fonteUbuntu.copyWith(
          color: AppColors.preto.withOpacity(0.4),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(
          tipo == "professor" ? Icons.email : Icons.badge,
          color: AppColors.azulClaro,
        ),
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
      ),
    );
  }

  Widget _campoSenha() {
    return TextFormField(
      controller: senhaController,
      cursorColor: AppColors.azulClaro,
      obscureText: !_senhaVisivel,
      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
      decoration: InputDecoration(
        labelText: 'Senha*',
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
}
