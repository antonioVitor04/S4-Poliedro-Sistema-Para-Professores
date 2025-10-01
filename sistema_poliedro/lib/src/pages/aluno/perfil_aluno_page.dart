import 'package:flutter/material.dart';
import '../../styles/fontes.dart';
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:  [
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              "Perfil do aluno",
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
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
