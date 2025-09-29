import 'package:flutter/material.dart';

class LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Login Page')),
        body: const Center(child: Text('Welcome to the Login Page!')),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  State<LoginPage> createState() {
    return LoginPageState();
  }
}
