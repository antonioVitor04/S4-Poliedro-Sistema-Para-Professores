import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/pages/Recuperar_Senha.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sistema_poliedro/src/pages/aluno/main_aluno_page.dart';
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
  bool _senhaVisivel = false; // Variável para controlar a visibilidade da senha

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

        // Aguarda que o token seja salvo antes de navegar
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
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO E TÍTULO FORA DO CONTAINER
              Image.asset('assets/images/logo.png', width: 139, height: 200),
              Text(
                "Poliedro",
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Educação",
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppColors.azulClaro,
                ),
              ),
              const SizedBox(height: 40),

              // CONTAINER DO FORMULÁRIO
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                width: 350,
                decoration: BoxDecoration(
                  color: AppColors.branco,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Login",
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.preto,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _tipoUsuarioBotao("Professor"),
                        const SizedBox(width: 20),
                        _tipoUsuarioBotao("Aluno"),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _campoTexto(tipo: paginaAtual),
                    const SizedBox(height: 16),
                    _campoSenha(),
                    const SizedBox(height: 20),
                    // Botão "Esqueci minha senha"
                    Container(
                      alignment: Alignment.centerLeft,
                      margin: const EdgeInsets.only(bottom: 15),
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Recuperar_Senha(),
                            ),
                          );
                        },
                        child: Text(
                          "Esqueci minha senha",
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            color: AppColors.azulClaro,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          side: BorderSide(color: AppColors.preto),
                          backgroundColor: AppColors.azulClaro,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: login,
                        child: Text(
                          "Entrar",
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            color: AppColors.preto,
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
      ),
    );
  }

  Widget _tipoUsuarioBotao(String tipo) {
    final bool selecionado = paginaAtual.toLowerCase() == tipo.toLowerCase();
    return Column(
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              paginaAtual = tipo.toLowerCase();
            });
          },
          child: Text(
            tipo,
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 20,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
              color: selecionado ? AppColors.azulClaro : AppColors.preto,
            ),
          ),
        ),
        Container(
          height: 3,
          width: tipo == "Aluno" ? 50 : 70,
          color: selecionado ? AppColors.azulClaro : Colors.transparent,
        ),
      ],
    );
  }

  Widget _campoTexto({required String tipo}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tipo == "professor" ? "Email" : "RA",
          style: AppTextStyles.fonteUbuntu.copyWith(
            fontSize: 16,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: emailController,
          cursorColor: AppColors.azulClaro,
          decoration: InputDecoration(
            hintText: tipo == "professor"
                ? "Digite seu email"
                : "Digite seu RA",
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.azulClaro),
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
            fontSize: 16,
            color: AppColors.preto,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: senhaController,
          obscureText: !_senhaVisivel, // Invertido para mostrar/ocultar
          cursorColor: AppColors.azulClaro,
          decoration: InputDecoration(
            hintText: "Digite sua senha",
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.azulClaro),
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