import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import 'package:sistema_poliedro/src/styles/fontes.dart';
import 'package:sistema_poliedro/src/components/alerta.dart';

class NovaSenha extends StatefulWidget {
  const NovaSenha({super.key});

  @override
  State<NovaSenha> createState() => _NovaSenhaState();
}

class _NovaSenhaState extends State<NovaSenha> {
  final TextEditingController novaSenhaController = TextEditingController();
  final TextEditingController confirmarSenhaController =
      TextEditingController();

  //funcao pra mostrar alerta
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

  @override
  void initState() {
    super.initState();
    // Adiciona listeners para atualizar a UI quando o texto mudar
    novaSenhaController.addListener(_updateUI);
    confirmarSenhaController.addListener(_updateUI);
  }

  void _updateUI() {
    setState(() {}); // Força o rebuild do widget
  }

  @override
  void dispose() {
    // Limpa os controllers quando o widget for destruído
    novaSenhaController.removeListener(_updateUI);
    confirmarSenhaController.removeListener(_updateUI);
    novaSenhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  // Função para verificar se a senha tem pelo menos uma letra maiúscula
  bool get hasUpperCase {
    return novaSenhaController.text.contains(RegExp(r'[A-Z]'));
  }

  // Função para verificar se a senha tem pelo menos um número
  bool get hasNumber {
    return novaSenhaController.text.contains(RegExp(r'[0-9]'));
  }

  //funcao para verificar se as senhas são iguais
  bool get senhasIguais {
    if (novaSenhaController.text.isEmpty ||
        confirmarSenhaController.text.isEmpty) {
      return false;
    }
    return novaSenhaController.text == confirmarSenhaController.text;
  }

  //funcao para verificar se possui um simbolo
  bool get hasSymbol {
    return novaSenhaController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
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
                width: 390,
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
                      alignment: Alignment.center,
                      child: Text(
                        "Informe sua nova senha",
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.preto,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    //texto acima do campo nova senha
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Digite sua nova senha",
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 16,
                          color: AppColors.preto,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    //campo de digitação da nova senha
                    TextField(
                      controller: novaSenhaController,
                      cursorColor: AppColors.azulClaro,
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.azulClaro,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.azulClaro),
                        ),
                        hintText: "Nova Senha",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    //texto acima do campo confirmar senha
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Confirme sua nova senha",
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 16,
                          color: AppColors.preto,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    //campo de digitação da confirmação da nova senha
                    TextField(
                      controller: confirmarSenhaController,
                      cursorColor: AppColors.azulClaro,
                      decoration: InputDecoration(
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.azulClaro,
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: AppColors.azulClaro),
                        ),
                        hintText: "Confirmar Nova Senha",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          "Sua senha deve conter:",
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 16,
                            color: AppColors.preto,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            novaSenhaController.text.length >= 8
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.verdeConfirmacao,
                                    size: 20,
                                  )
                                : Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                            const SizedBox(width: 10),
                            Text(
                              "Mínimo de 8 caracteres",
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 14,
                                color: AppColors.preto,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            hasUpperCase
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.verdeConfirmacao,
                                    size: 20,
                                  )
                                : Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                            const SizedBox(width: 10),
                            Text(
                              "Pelo menos uma letra maiúscula",
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 14,
                                color: AppColors.preto,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            hasNumber
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.verdeConfirmacao,
                                    size: 20,
                                  )
                                : Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                            const SizedBox(width: 10),
                            Text(
                              "Pelo menos um número",
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 14,
                                color: AppColors.preto,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            hasSymbol
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.verdeConfirmacao,
                                    size: 20,
                                  )
                                : Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                            const SizedBox(width: 10),
                            Text(
                              "Pelo menos um símbolo",
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 14,
                                color: AppColors.preto,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            senhasIguais
                                ? Icon(
                                    Icons.check,
                                    color: AppColors.verdeConfirmacao,
                                    size: 20,
                                  )
                                : Icon(
                                    Icons.close,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                            const SizedBox(width: 10),
                            Text(
                              "As senhas devem ser iguais",
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 14,
                                color: AppColors.preto,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Lógica para salvar a nova senha
                          if (senhasIguais &&
                              hasNumber &&
                              hasSymbol &&
                              hasUpperCase) {
                            // Salvar a nova senha
                            //fazer o alerta durar 2 segundos antes de redirecionar para o login

                            mostrarAlerta("Senha alterada com sucesso!", true);
                            // Aguardar 3 segundos antes de redirecionar
                            Future.delayed(const Duration(seconds: 2), () {
                              Navigator.pushReplacementNamed(context, "/login");
                            });
                          } //senhas não coincidem
                          else {
                            mostrarAlerta(
                              "A senha não atende aos requisitos",
                              false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulClaro,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: AppColors.preto),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          "Salvar Nova Senha",
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
