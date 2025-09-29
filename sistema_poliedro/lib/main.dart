import 'package:flutter/material.dart';
import 'src/pages/login_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // garante que o Flutter está inicializado antes de carregar dotenv
  WidgetsFlutterBinding.ensureInitialized();

  // carrega as variáveis do .env
  await dotenv.load();

  // inicializa o app
  runApp(const LoginPage());
}
