import 'package:flutter/material.dart';
import '../components/alerta.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';
import 'codigo_verificacao.dart';

class Recuperar_Senha extends StatefulWidget {
  const Recuperar_Senha({super.key});

  @override
  State<Recuperar_Senha> createState() => _Recuperar_SenhaState();
}

class _Recuperar_SenhaState extends State<Recuperar_Senha> {
  final TextEditingController emailController = TextEditingController();

  void mostrarAlerta(String mensagem, bool sucesso) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (context) => AlertaWidget(mensagem: mensagem, sucesso: sucesso),
    );

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); 
      }
    });
  }

  Future<void> recuperarSenha() async {
  final email = emailController.text.trim();

  if (email.isEmpty) {
    mostrarAlerta("Digite um e-mail válido.", false);
    return;
  }

  // teste de email corretor
  if (email == "teste@poliedro.com") {
    mostrarAlerta(
      "Um código de verificação foi enviado para seu e-mail.",
      true,
    );

    await Future.delayed(const Duration(seconds: 2));
    

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CodigoVerificacao()),
    );
  } else {
    mostrarAlerta("E-mail não cadastrado!", false);
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
                    const SizedBox(height: 10),
                    Text(
                      "Lembre-se: utilize o e-mail cadastrado em nossa plataforma.",
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 14,
                        color: Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // CAMPO DE EMAIL
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Email",
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 16,
                          color: AppColors.preto,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      cursorColor: AppColors.azulClaro,
                      decoration: InputDecoration(
                        hintText: "exemplo@poliedro.com",
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              BorderSide(color: AppColors.azulClaro, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.azulClaro),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // BOTÃO ENVIAR
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulClaro,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: AppColors.preto),
                          ),
                        ),
                        onPressed: recuperarSenha,
                        child: Text(
                          "Enviar",
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
}
