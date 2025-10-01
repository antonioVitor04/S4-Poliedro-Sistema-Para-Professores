import 'package:flutter/material.dart';

class NotasPage extends StatefulWidget {
  const NotasPage({super.key});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = "";

  final List<Map<String, dynamic>> disciplinas = [
    {
      "disciplina": "Física",
      "mediaProvas": 5.0,
      "mediaAtividades": 5.0,
      "mediaFinal": 5.0,
      "detalhes": [
        {"tipo": "Prova 1", "nota": 3.5, "peso": 0.5},
        {"tipo": "Prova 2", "nota": 2.5, "peso": 0.5},
        {"tipo": "Atividade 1", "nota": 5.0, "peso": 0.5},
      ]
    },
    {
      "disciplina": "Biologia",
      "mediaProvas": 7.5,
      "mediaAtividades": 8.0,
      "mediaFinal": 7.8,
      "detalhes": []
    },
    {
      "disciplina": "História",
      "mediaProvas": 6.0,
      "mediaAtividades": 7.0,
      "mediaFinal": 6.5,
      "detalhes": []
    },
    {
      "disciplina": "Matemática",
      "mediaProvas": 8.5,
      "mediaAtividades": 9.0,
      "mediaFinal": 8.75,
      "detalhes": []
    },
    {
      "disciplina": "Literatura",
      "mediaProvas": 3.0,
      "mediaAtividades": 5.0,
      "mediaFinal": 4.0,
      "detalhes": [
        {"tipo": "Prova 1", "nota": 3.5, "peso": 0.5},
        {"tipo": "Prova 2", "nota": 2.5, "peso": 0.5},
        {"tipo": "Atividade 1", "nota": 5.0, "peso": 0.5},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TÍTULO
              Text(
                "Notas",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 15),

              /// BARRA DE PESQUISA
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() => searchText = value.toLowerCase());
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Pesquisar disciplina...",
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),

              /// LEGENDA
              Row(
                children: const [
                  CircleAvatar(radius: 6, backgroundColor: Colors.red),
                  SizedBox(width: 5),
                  Text("Abaixo da média"),
                  SizedBox(width: 20),
                  CircleAvatar(radius: 6, backgroundColor: Colors.teal),
                  SizedBox(width: 5),
                  Text("Acima da média"),
                ],
              ),
              const SizedBox(height: 15),

              /// LISTA DE DISCIPLINAS
              Expanded(
                child: ListView(
                  children: disciplinas
                      .where((d) => d["disciplina"]
                          .toString()
                          .toLowerCase()
                          .contains(searchText))
                      .map((disciplina) {
                    bool acimaMedia = disciplina["mediaFinal"] >= 6.0;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              acimaMedia ? Colors.teal : Colors.red,
                          radius: 8,
                        ),
                        title: Row(
                          children: [
                            /// Nome da disciplina à esquerda
                            Expanded(
                              flex: 2,
                              child: Text(
                                disciplina["disciplina"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            /// Notas centralizadas
                            Expanded(
                              flex: 3,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildNota(
                                      "Provas", disciplina["mediaProvas"]),
                                  const SizedBox(width: 8),
                                  _buildNota("Atividades",
                                      disciplina["mediaAtividades"]),
                                  const SizedBox(width: 8),
                                  _buildNota("Final", disciplina["mediaFinal"],
                                      destaque: true),
                                ],
                              ),
                            ),
                          ],
                        ),

                        /// Detalhes ao expandir
                        children: disciplina["detalhes"].isNotEmpty
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Table(
                                    border: TableBorder.all(
                                        color: Colors.grey.shade300),
                                    columnWidths: const {
                                      0: FlexColumnWidth(2),
                                      1: FlexColumnWidth(1),
                                      2: FlexColumnWidth(1),
                                    },
                                    children: [
                                      const TableRow(
                                        decoration: BoxDecoration(
                                            color: Color(0xFFEFEFEF)),
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Text("Tipo",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Text("Nota",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.all(6.0),
                                            child: Text("Peso",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                      ...disciplina["detalhes"].map<TableRow>(
                                          (detalhe) {
                                        return TableRow(children: [
                                          Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child: Text(detalhe["tipo"]),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child:
                                                Text(detalhe["nota"].toString()),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(6.0),
                                            child:
                                                Text(detalhe["peso"].toString()),
                                          ),
                                        ]);
                                      }).toList(),
                                    ],
                                  ),
                                )
                              ]
                            : [],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget auxiliar para exibir notas
  Widget _buildNota(String titulo, double valor, {bool destaque = false}) {
    return Row(
      children: [
        Text(
          "$titulo: ",
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        Text(
          valor.toStringAsFixed(1),
          style: TextStyle(
            fontSize: destaque ? 14 : 12,
            fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
            color: destaque
                ? (valor >= 6 ? Colors.teal : Colors.red)
                : Colors.black87,
          ),
        ),
      ],
    );
  }
}
