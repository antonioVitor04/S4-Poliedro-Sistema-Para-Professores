import 'package:flutter/material.dart';

class HomeProfessor extends StatelessWidget {
  const HomeProfessor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home - Professor")),
      body: Center(child: Text("Bem-vindo, Professor!")),
    );
  }
}
