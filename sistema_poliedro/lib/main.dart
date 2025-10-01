import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/pages/professor/home_professor.dart';
import 'src/pages/login_page.dart';
import 'src/pages/aluno/main_aluno_page.dart';
import 'src/components/auth_guard.dart';
import 'src/pages/recuperar_senha.dart';
import 'src/pages/codigo_verificacao.dart';
import 'src/pages/nova_senha.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poliedro Educação',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      // 👇 Tela inicial
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/aluno_protected': (context) =>
            AuthGuard(child: const MainAlunoPage()),
        '/professor_protected': (context) =>
            AuthGuard(child: const HomeProfessor()),
        '/recuperar_senha': (context) => Recuperar_Senha(),

        // '/codigo_verificacao': (context) => const CodigoVerificacao(),
        // '/nova_senha': (context) => const NovaSenha(),
      },
    );
  }
}