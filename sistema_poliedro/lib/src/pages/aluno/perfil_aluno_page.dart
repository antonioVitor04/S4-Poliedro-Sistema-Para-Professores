import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Perfil do Aluno",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text("Nome: João da Silva"),
          Text("RA: 123456"),
          Text("Curso: Engenharia de Software"),
          // Adicione mais informações do perfil aqui
        ],
      ),
    );
  }
}
