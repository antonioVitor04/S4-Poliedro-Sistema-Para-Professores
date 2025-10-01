import 'package:flutter/material.dart';
import '../../styles/fontes.dart';

class CalendarioPage extends StatelessWidget {
  const CalendarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              "Calendário",
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text("01/10 - Prova de Matemática"),
          const Text("03/10 - Entrega de Projeto de Programação"),
          const Text("05/10 - Aula de Física"),
          const Text("10/10 - Reunião de Pais e Mestres"),
          // Adicione eventos do calendário
        ],
      ),
    );
  }
}
