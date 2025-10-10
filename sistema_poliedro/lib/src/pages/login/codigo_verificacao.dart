import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/services/auth_service.dart';
import 'dart:convert';
import 'package:sistema_poliedro/src/styles/cores.dart';
import 'package:sistema_poliedro/src/styles/fontes.dart';
import 'package:sistema_poliedro/src/components/alerta.dart';
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

      await AuthService.verifyCode(widget.email, codigo);

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
    } on Exception catch (error) {
      final mensagem = error.toString().replaceFirst('Exception: ', '');
      mostrarAlerta(mensagem.isEmpty ? "Código inválido!" : mensagem, false);
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _continuar() {
    String codigo = _controllers.map((c) => c.text).join();

    if (codigo.length < 6) {
      mostrarAlerta("Digite todos os 6 dígitos.", false);
      return;
    }

    // Chama a função de validação com o backend
    _validarCodigoComBackend(codigo);
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

        // LADO DIREITO - FORMULÁRIO DE VERIFICAÇÃO
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.branco,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: _buildVerificacaoForm(isDesktop: true),
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
          child: _buildVerificacaoForm(isDesktop: false),
        ),
      ),
    );
  }

  Widget _buildVerificacaoForm({bool isDesktop = true}) {
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
            "Verificação Código",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Enviamos um código de 6 dígitos para ${widget.email}",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 16,
              color: AppColors.preto.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // AVISO IMPORTANTE
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.azulClaro.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.azulClaro.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.azulClaro, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Digite o código recebido em seu e-mail",
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 14,
                      color: AppColors.azulClaro,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // CAMPOS DE CÓDIGO
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Código de Verificação",
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.preto,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (i) => _campoCodigo(_controllers[i]),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // BOTÃO CONTINUAR
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
              onPressed: _carregando ? null : _continuar,
              child: _carregando
                  ? SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "Verificar Código",
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // BOTÃO VOLTAR PARA LOGIN
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back, size: 18, color: AppColors.azulClaro),
                  const SizedBox(width: 8),
                  Text(
                    "Voltar para o login",
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.azulClaro,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campoCodigo(TextEditingController controller) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return SizedBox(
      width: isDesktop ? 55 : 40,
      height: isDesktop ? 60 : 48,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        maxLength: 1,
        keyboardType: TextInputType.number,
        cursorColor: AppColors.azulClaro,
        style: AppTextStyles.fonteUbuntu.copyWith(
          fontSize: isDesktop ? 24 : 12,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: "",
          filled: true,
          fillColor: AppColors.azulClaro.withOpacity(0.15),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
            borderRadius: BorderRadius.circular(10),
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
  void dispose() {
    // Limpa os controllers para evitar memory leaks
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }
}