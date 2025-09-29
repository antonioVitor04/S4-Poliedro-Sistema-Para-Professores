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
                    // campo de email
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Email",
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.normal,
                            color: AppColors.preto,
                          ),
                        ),
                        const SizedBox(height: 8), // espaço entre label e campo
                        TextField(
                          cursorColor: AppColors.azulClaro,
                          decoration: InputDecoration(
                            hintText: paginaAtual == "professor"
                                ? "exemplo@sistemapoliedro.com"
                                : "Insira seu RA",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.preto,
                              ), // cor quando não está focado
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.azulClaro,
                                width: 2,
                              ), // cor quando focado
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16), // espaço abaixo do campo
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
                              borderSide: BorderSide(
                                // cor quando não está focado
                                color: AppColors.preto,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                // cor quando focado
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
                    //Botão de cadastrar email apenas se for aluno

                    // Botão de login
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
                          // lógica do login
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
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => LoginPageState();
}
