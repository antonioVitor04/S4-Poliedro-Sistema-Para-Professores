import 'package:flutter/material.dart';

class HomeAluno extends StatelessWidget {
  const HomeAluno({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home - Aluno")),
      body: Center(child: Text("Bem-vindo, Aluno!")),
    );
  }
}
