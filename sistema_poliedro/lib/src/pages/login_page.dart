import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/pages/Recuperar_Senha.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../components/alerta.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  Future<void> login() async {
    final emailOuRA = emailController.text.trim();
    final senha = senhaController.text.trim();
    final rota = paginaAtual == "professor" ? "professores" : "alunos";
    final url = Uri.parse("http://localhost:5000/api/$rota/login");
    final body = paginaAtual == "professor"
        ? {"email": emailOuRA, "senha": senha}
        : {"ra": emailOuRA, "senha": senha};

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('token', token);
        await prefs.setString('tipoUsuario', paginaAtual);

        Navigator.pushReplacementNamed(
          context,
          '/aluno_protected',
          arguments: {'initialRoute': '/disciplinas'},
        );
      } else {
        mostrarAlerta("Erro no login. Verifique suas credenciais.", false);
      }
    } catch (e) {
      mostrarAlerta("Erro na requisição. Tente novamente mais tarde.", false);
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
                Navigator.pushReplacement(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tipo == "professor" ? "Email" : "RA",
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
          decoration: InputDecoration(
            hintText: tipo == "professor"
                ? "Digite seu email"
                : "Digite seu RA",
            hintStyle: TextStyle(color: AppColors.preto.withOpacity(0.4)),
            filled: true,
            fillColor: AppColors.azulClaro.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
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

  Widget _campoSenha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Senha",
          style: AppTextStyles.fonteUbuntu.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: senhaController,
          obscureText: !_senhaVisivel,
          cursorColor: AppColors.azulClaro,
          style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: "Digite sua senha",
            hintStyle: TextStyle(color: AppColors.preto.withOpacity(0.4)),
            filled: true,
            fillColor: AppColors.azulClaro.withOpacity(0.05),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.transparent),
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
        ),
      ],
    );
  }
}
