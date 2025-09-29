import 'package:flutter/material.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/alerta.dart';
import 'home_aluno.dart';
import 'home_professor.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  //mostrar alerta
  void mostrarAlerta(String mensagem, bool sucesso) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Remove o fundo escuro
      barrierDismissible: true,
      builder: (context) => AlertaWidget(mensagem: mensagem, sucesso: sucesso),
    );

    // Fecha automaticamente depois de 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  String paginaAtual = "professor";
  // serve para pegar o valor digitado no campo de texto
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  //funcao de login
  Future<void> login() async {
    final String emailOuRA = emailController.text;
    final String senha = senhaController.text;

    final String rota = paginaAtual == "professor" ? "professores" : "alunos";
    final url = Uri.parse('${dotenv.env['API_URL']!}/api/$rota/login');

    final body = paginaAtual == "professor"
        ? {"email": emailOuRA.trim(), "senha": senha.trim()}
        : {"ra": emailOuRA.trim(), "senha": senha.trim()};

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${dotenv.env['API_TOKEN']}",
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final usuario =
            data[paginaAtual == "professor" ? 'professor' : 'aluno'];

        // Salva token localmente
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);

        mostrarAlerta("Login feito com sucesso! Usuário: $usuario", true);

        // Navegação condicional entre telas
        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) =>
                paginaAtual == "professor" ? HomeProfessor() : HomeAluno(),
          ),
          (route) => false, // Remove TODAS as rotas anteriores
        );
      } else {
        mostrarAlerta("Erro no login. Verifique suas credenciais.", false);
      }
    } catch (e) {
      mostrarAlerta("Erro na requisição. Tente novamente mais tarde.", false);
    }
  }

  // construtor da tela
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Container(
              margin: const EdgeInsets.only(top: 40),
              padding: EdgeInsets.all(20),
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

                  // Row para os textos lado a lado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Professor
                      Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                paginaAtual = "professor";
                              });
                            },
                            child: Text(
                              "Professor",
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                                color: paginaAtual == "professor"
                                    ? AppColors.azulClaro
                                    : AppColors.preto,
                              ),
                            ),
                          ),
                          Container(
                            height: 3,
                            width: 70,
                            color: paginaAtual == "professor"
                                ? AppColors.azulClaro
                                : Colors.transparent,
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      // Aluno
                      Column(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                paginaAtual = "aluno";
                              });
                            },
                            child: Text(
                              "Aluno",
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.normal,
                                color: paginaAtual == "aluno"
                                    ? AppColors.azulClaro
                                    : AppColors.preto,
                              ),
                            ),
                          ),
                          Container(
                            height: 3,
                            width: 50,
                            color: paginaAtual == "aluno"
                                ? AppColors.azulClaro
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // campo de email
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        paginaAtual == "professor" ? "Email" : "RA",
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: AppColors.preto,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        cursorColor: AppColors.azulClaro,
                        decoration: InputDecoration(
                          hintText: paginaAtual == "professor"
                              ? "exemplo@sistemapoliedro.com"
                              : "Insira seu RA",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.preto),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.azulClaro,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                  // Campo de Senha
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Senha",
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: AppColors.preto,
                        ),
                      ),
                      TextField(
                        controller: senhaController,
                        obscureText: true,
                        cursorColor: AppColors.azulClaro,
                        decoration: InputDecoration(
                          hintText: "Digite sua senha",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.preto),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.azulClaro,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                  // Botão "Esqueci minha senha"
                  Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.only(bottom: 15),
                    child: TextButton(
                      onPressed: () => {},
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
                  //Botão de login
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulClaro,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        login();
                      },
                      child: Text(
                        "Entrar",
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
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
    );
  }
}
