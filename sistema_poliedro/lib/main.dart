import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/pages/professor/page_professor_controller.dart';
import 'src/pages/login/login_page.dart';
import 'src/pages/aluno/page_aluno_controller.dart';
import 'src/components/auth_guard.dart';
import 'src/pages/login/recuperar_senha.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); 
  await dotenv.load(fileName: "assets/.env");
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