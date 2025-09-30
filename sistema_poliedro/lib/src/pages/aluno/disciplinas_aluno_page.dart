import 'package:flutter/material.dart';

class DisciplinasPage extends StatelessWidget {
  const DisciplinasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: ListView(
        children: const [
          Text(
            "Disciplinas",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          ListTile(
            title: Text("Matemática"),
            subtitle: Text("Professor: Maria Souza"),
          ),
          ListTile(
            title: Text("Programação"),
            subtitle: Text("Professor: Carlos Lima"),
          ),
          ListTile(
            title: Text("Física"),
            subtitle: Text("Professor: Ana Pereira"),
          ),
          // Adicione mais disciplinas
        ],
      ),
    );
  }
}
