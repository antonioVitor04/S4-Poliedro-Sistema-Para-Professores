import 'dart:convert';

import 'package:flutter/material.dart';
import '../components/alerta.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';

import 'package:sistema_poliedro/src/pages/codigo_verificacao.dart';
import 'package:sistema_poliedro/src/pages/login_page.dart'; // Importe a tela de login
import 'package:http/http.dart' as http;

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

      final url = Uri.parse(
        'http://localhost:5000/api/enviarEmail/enviar-codigo',
      );
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        mostrarAlerta("Código enviado para $email", true);

        // Redireciona após o alerta fechar
        Future.delayed(const Duration(seconds: 3), () {
          redirecionaParaInserirCodigo(email);
        });
      } else {
        // Algum erro aconteceu (ex: email não encontrado)
        mostrarAlerta(data['error'] ?? "Erro ao enviar código", false);
      }
    } catch (e) {
      mostrarAlerta("Erro de conexão: $e", false);
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
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: Stack(
        children: [
          // CONTEÚDO PRINCIPAL
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO
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
                            "Recupere sua senha",
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.preto,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Digite seu e-mail para receber um código de 6 dígitos e recuperar sua senha.",
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 14,
                            color: AppColors.preto,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        onPressed: _carregando ? null : verificaEmailEEnvia,
                        child: _carregando
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.preto,
                                  ),
                                ),
                              )
                            : Text(
                                "Enviar",
                                style: AppTextStyles.fonteUbuntu.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                  color: AppColors.preto,
                                ),
                              ),
                      ),

                    ),
                  ),
                ],
              ),
            ),
          ),

          // BOTÃO VOLTAR NO CANTO SUPERIOR ESQUERDO
          Positioned(
            top: 25, // Posição ajustada para subir mais
            left: 20,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.azulClaro,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: const Color.fromARGB(255, 255, 255, 255),
                  size: 24,
                ),
                onPressed: () {
                  // Navega para a tela de login
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}