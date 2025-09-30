import 'package:flutter/material.dart';

class CalendarioPage extends StatelessWidget {
  const CalendarioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Calendário",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Text("01/10 - Prova de Matemática"),
          Text("03/10 - Entrega de Projeto de Programação"),
          Text("05/10 - Aula de Física"),
          Text("10/10 - Reunião de Pais e Mestres"),
          // Adicione eventos do calendário
        ],
      ),
    );
  }
}
