import 'package:flutter/material.dart';
import 'src/pages/login_page.dart';
import 'src/pages/aluno/main_aluno_page.dart';
import 'src/components/auth_guard.dart';
import 'src/styles/cores.dart';

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
        '/aluno': (context) => const MainAlunoPage(),
      },
    );
  }
}
