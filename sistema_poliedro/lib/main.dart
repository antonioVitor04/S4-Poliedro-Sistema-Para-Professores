import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/pages/professor/home_professor.dart';
import 'src/pages/login_page.dart';
import 'src/pages/aluno/main_aluno_page.dart';
import 'src/components/auth_guard.dart';
import 'src/styles/cores.dart';
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/aluno_protected': (context) =>
            AuthGuard(child: const MainAlunoPage()),
        '/professor_protected': (context) =>
            AuthGuard(child: const HomeProfessor()),
        '/nova_senha': (context) => const NovaSenha(),
      },
    );
  }
}
