import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sistema_poliedro/src/pages/login/Recuperar_Senha.dart';
import 'package:sistema_poliedro/src/services/auth_service.dart';
import '../../models/modelo_usuario.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import 'package:sistema_poliedro/src/styles/fontes.dart';
import 'package:sistema_poliedro/src/components/alerta.dart';
import 'package:email_validator/email_validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginBloc bloc;
  String paginaAtual = "aluno";
  bool _senhaVisivel = false;

  @override
  void initState() {
    super.initState();
    bloc = LoginBloc();
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  void mostrarAlerta(String mensagem, bool sucesso) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (context) {
        Timer(const Duration(seconds: 2), () {
          if (Navigator.of(context, rootNavigator: true).canPop()) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        });

        return AlertaWidget(mensagem: mensagem, sucesso: sucesso);
      },
    );
  }

  Future<void> _login() async {
    String emailOuRA;
    try {
      emailOuRA = bloc.currentField;
    } catch (e) {
      emailOuRA = '';
    }
    String senha;
    try {
      senha = bloc.currentPassword;
    } catch (e) {
      senha = '';
    }

    if (emailOuRA.isEmpty || senha.isEmpty) {
      mostrarAlerta("Por favor, preencha todos os campos.", false);
      return;
    }

    try {
      await AuthService.login(emailOuRA, senha, paginaAtual);

      if (!mounted) return;

      if (paginaAtual == "professor") {
        Navigator.pushReplacementNamed(context, '/professor_protected');
      } else {
        Navigator.pushReplacementNamed(
          context,
          '/aluno_protected',
          arguments: {'initialRoute': '/disciplinas'},
        );
      }
    } on Exception catch (e) {
      if (!mounted) return;

      final mensagem = e.toString().replaceFirst('Exception: ', '');
      if (mensagem.contains('login')) {
        mostrarAlerta("Erro no login. Verifique suas credenciais.", false);
      } else {
        mostrarAlerta("Erro na requisição. Tente novamente mais tarde.", false);
      }
    }
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
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.branco,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 60),
                child: _buildLoginForm(isDesktop: true),
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
          child: _buildLoginForm(isDesktop: false),
        ),
      ),
    );
  }

  Widget _buildLoginForm({required bool isDesktop}) {
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
          if (!isDesktop) ...[
            Column(
              children: [
                Image.asset('assets/images/logo.png', width: 70, height: 110),
                const SizedBox(height: 30),
              ],
            ),
          ],
          Text(
            "Bem-vindo!",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.preto,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Entre com suas credenciais",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 16,
              color: AppColors.preto.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 35),
          StreamBuilder<String>(
            stream: bloc.userTypeStream,
            builder: (context, snapshot) {
              final userType = snapshot.data ?? 'aluno';
              return Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.azulClaro.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(child: _tipoUsuarioBotaoModerno("Professor", userType)),
                    Expanded(child: _tipoUsuarioBotaoModerno("Aluno", userType)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: _campoTexto(paginaAtual),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: _campoSenha()),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Recuperar_Senha()),
                );
              },
              child: Text(
                "Esqueci minha senha",
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.azulClaro,
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: StreamBuilder<bool>(
              stream: bloc.isFormValid,
              builder: (context, snapshot) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulClaro,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: snapshot.hasData && snapshot.data == true ? _login : null,
                  child: Text(
                    "Entrar",
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipoUsuarioBotaoModerno(String tipo, String userType) {
    final bool selecionado = paginaAtual.toLowerCase() == tipo.toLowerCase();
    return GestureDetector(
      onTap: () {
        setState(() {
          paginaAtual = tipo.toLowerCase();
        });
        bloc.changeUserType(paginaAtual);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selecionado ? AppColors.azulClaro : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            tipo,
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 16,
              fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
              color: selecionado
                  ? Colors.white
                  : AppColors.preto.withOpacity(0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _campoTexto(String tipo) {
    return StreamBuilder<String>(
      stream: bloc.fieldStream,
      builder: (context, snapshot) {
        return TextFormField(
          onChanged: bloc.changeField,
          keyboardType: tipo == "professor" ? TextInputType.emailAddress : TextInputType.number,
          cursorColor: AppColors.azulClaro,
          style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
          decoration: InputDecoration(
            labelText: tipo == "professor" ? "Email*" : "RA*",
            labelStyle: AppTextStyles.fonteUbuntu.copyWith(color: Colors.black),
            hintStyle: AppTextStyles.fonteUbuntu.copyWith(
              color: AppColors.preto.withOpacity(0.4),
            ),
            errorText: snapshot.hasError ? snapshot.error.toString() : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: Icon(
              tipo == "professor" ? Icons.email : Icons.badge,
              color: AppColors.azulClaro,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.preto.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _campoSenha() {
    return StreamBuilder<String>(
      stream: bloc.passwordStream,
      builder: (context, snapshot) {
        return TextFormField(
          onChanged: bloc.changePassword,
          cursorColor: AppColors.azulClaro,
          obscureText: !_senhaVisivel,
          style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
          decoration: InputDecoration(
            labelText: 'Senha*',
            labelStyle: AppTextStyles.fonteUbuntu.copyWith(color: Colors.black),
            hintStyle: AppTextStyles.fonteUbuntu.copyWith(
              color: AppColors.preto.withOpacity(0.4),
            ),
            errorText: snapshot.hasError ? snapshot.error.toString() : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.lock, color: AppColors.azulClaro),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.preto.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
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
        );
      },
    );
  }
}

class LoginBloc {
  final _fieldController = BehaviorSubject<String>();
  final _passwordController = BehaviorSubject<String>();
  final _userTypeController = BehaviorSubject<String>.seeded('aluno');

  Stream<String> get fieldStream => Rx.combineLatest2(
    _fieldController,
    _userTypeController,
    (String field, String userType) => (field, userType),
  ).transform(
    StreamTransformer.fromHandlers(
      handleData: (pair, sink) {
        final field = pair.$1.trim();
        final userType = pair.$2;
        if (field.isEmpty) {
          sink.addError(
            userType == 'professor' ? 'Por favor, insira o email.' : 'Por favor, insira o RA.',
          );
          return;
        }
        if (userType == 'professor' && !EmailValidator.validate(field)) {
          sink.addError('E-mail inválido');
          return;
        }
        sink.add(field);
      },
    ),
  );

  Stream<String> get passwordStream => _passwordController.transform(
    StreamTransformer.fromHandlers(
      handleData: (password, sink) {
        final trimmed = password.trim();
        if (trimmed.isEmpty) {
          sink.addError('Por favor, insira a senha.');
          return;
        }
        if (trimmed.length < 8) {
          sink.addError('Senha deve ter, pelo menos, 8 caracteres');
          return;
        }
        sink.add(trimmed);
      },
    ),
  );

  Stream<bool> get isFormValid => Rx.combineLatest2(
    fieldStream,
    passwordStream,
    (f, p) => true,
  );

  Stream<String> get userTypeStream => _userTypeController.stream;

  String get currentField {
    try {
      return _fieldController.value.trim();
    } catch (e) {
      return '';
    }
  }

  String get currentPassword {
    try {
      return _passwordController.value.trim();
    } catch (e) {
      return '';
    }
  }

  String get currentUserType => _userTypeController.value;

  void changeField(String value) => _fieldController.add(value);
  void changePassword(String value) => _passwordController.add(value);
  void changeUserType(String value) => _userTypeController.add(value);

  void dispose() {
    _fieldController.close();
    _passwordController.close();
    _userTypeController.close();
  }
}