import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../styles/cores.dart';
import '../styles/fontes.dart';
import '../components/alerta.dart';
import '../components/botao_voltar.dart';
import 'nova_senha.dart';

class CodigoVerificacao extends StatefulWidget {
  final String email;

  const CodigoVerificacao({super.key, required this.email});

  @override
  State<CodigoVerificacao> createState() => _CodigoVerificacaoState();
}

class _CodigoVerificacaoState extends State<CodigoVerificacao> {
  bool _carregando = false;
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

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

  // Função para validar o código com o backend
  Future<void> _validarCodigoComBackend(String codigo) async {
    try {
      setState(() {
        _carregando = true;
      });

      final response = await _chamarApiValidacao(codigo);

      if (response['sucesso'] == true) {
        // Mostra alerta de sucesso
        mostrarAlerta("Código validado com sucesso!", true);

        // Aguarda 2 segundos e redireciona para NovaSenha
        await Future.delayed(const Duration(seconds: 2));

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  NovaSenha(email: widget.email, codigo: codigo),
            ),
          );
        }
      } else {
        // Código inválido
        mostrarAlerta(response['mensagem'] ?? "Código inválido!", false);
      }
    } catch (error) {
      // Erro de conexão ou servidor
      mostrarAlerta("Erro ao validar código. Tente novamente.", false);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  // Função REAL para chamada API
  Future<Map<String, dynamic>> _chamarApiValidacao(String codigo) async {
    const String url =
        'http://localhost:5000/api/enviarEmail/verificar-codigo'; // Ajuste a URL conforme necessário

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email, 'codigo': codigo}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'sucesso': true,
          'mensagem': data['message'] ?? 'Código verificado com sucesso',
        };
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        return {
          'sucesso': false,
          'mensagem': data['error'] ?? 'Código inválido',
        };
      } else {
        return {
          'sucesso': false,
          'mensagem': 'Erro no servidor. Tente novamente.',
        };
      }
    } catch (error) {
      throw Exception('Erro de conexão: $error');
    }
  }

  void _continuar() {
    String codigo = _controllers.map((c) => c.text).join();

    if (codigo.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Digite todos os 6 dígitos.")),
      );
      return;
    }

    // Chama a função de validação com o backend
    _validarCodigoComBackend(codigo);
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
          } else if (value.isEmpty) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LOGO
                  Image.asset(
                    'assets/images/logo.png',
                    width: 139,
                    height: 200,
                  ),
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
                          "Enviamos um código de 6 dígitos para ${widget.email}. Insira-o abaixo para continuar.",
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
                            onPressed: _carregando ? null : _continuar,
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

          // BOTÃO VOLTAR NO CANTO SUPERIOR ESQUERDO
          BotaoVoltar(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },

            corFundo: AppColors.azulClaro,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Limpa os controllers para evitar memory leaks
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
