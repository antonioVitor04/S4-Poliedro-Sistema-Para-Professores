import 'package:flutter/material.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';

class LoginPageState extends State<LoginPage> {
  String paginaAtual = "professor"; // agora pode mudar

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
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
                      alignment: Alignment.centerLeft, // esquerda
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
                    //campo de email
                    Text(
                      "Email",
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                        color: AppColors.preto,
                      ),
                    ),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Digite seu email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Campo de Senha
                    Text(
                      "Senha",
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                    ),
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: "Digite sua senha",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botão de login
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // lógica do login
                        },
                        child: Text(
                          "Entrar",
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
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
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}
