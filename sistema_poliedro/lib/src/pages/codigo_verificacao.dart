import 'package:flutter/material.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';
// import 'nova_senha.dart'; // depois você cria essa tela

class CodigoVerificacao extends StatefulWidget {
  const CodigoVerificacao({super.key});

  @override
  State<CodigoVerificacao> createState() => _CodigoVerificacaoState();
}

class _CodigoVerificacaoState extends State<CodigoVerificacao> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());

  void _continuar() {
    String codigo = _controllers.map((c) => c.text).join();

    if (codigo.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite todos os 6 dígitos.")),
      );
      return;
    }

    // 🔥 Teste simples: código válido = 123456
    if (codigo == "123456") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Código validado com sucesso!")),
      );

      // 🔽 Aqui sim você pode mandar o usuário para "Nova Senha"
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => const NovaSenha()),
      // );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Código incorreto!")),
      );
    }
  }

  Widget _campoCodigo(TextEditingController controller) {
    return SizedBox(
      width: 45,
      height: 55,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        cursorColor: AppColors.azulClaro,
        decoration: InputDecoration(
          counterText: "",
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.preto),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            FocusScope.of(context).nextFocus();
          }
        },
      ),
    );
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
                    Text(
                      "Insira o código",
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.preto,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Enviamos um código de 6 dígitos para o seu e-mail. Insira-o abaixo para continuar.",
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 14,
                        color: AppColors.preto,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // CAMPOS DE CÓDIGO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        6,
                        (i) => _campoCodigo(_controllers[i]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // BOTÃO CONTINUAR
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
                        onPressed: _continuar,
                        child: Text(
                          "Continuar",
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
