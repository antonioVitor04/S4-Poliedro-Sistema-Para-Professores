import 'package:flutter/material.dart';

class NotasPage extends StatelessWidget {
  const NotasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Notas",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          DataTable(
            columns: const [
              DataColumn(label: Text("Disciplina")),
              DataColumn(label: Text("Nota 1")),
              DataColumn(label: Text("Nota 2")),
              DataColumn(label: Text("Média")),
            ],
            rows: const [
              DataRow(cells: [
                DataCell(Text("Matemática")),
                DataCell(Text("8.5")),
                DataCell(Text("9.0")),
                DataCell(Text("8.75")),
              ]),
              DataRow(cells: [
                DataCell(Text("Programação")),
                DataCell(Text("7.0")),
                DataCell(Text("8.0")),
                DataCell(Text("7.5")),
              ]),
              DataRow(cells: [
                DataCell(Text("Física")),
                DataCell(Text("9.0")),
                DataCell(Text("9.5")),
                DataCell(Text("9.25")),
              ]),
              // Adicione mais linhas conforme necessário
            ],
          ),
        ],
      ),
    );
  }
}
