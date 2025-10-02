import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/components/lista_disciplinas.dart';
import 'package:sistema_poliedro/src/services/calculadora_medias.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';

class NotasPage extends StatefulWidget {
  const NotasPage({super.key});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = "";
  List<Map<String, dynamic>> disciplinas = [];

  @override
  void initState() {
    super.initState();
    _carregarDisciplinas();
  }

  void _carregarDisciplinas() {
    // Dados brutos - apenas com detalhes, sem médias calculadas
    final dadosBrutos = [
      {
        "disciplina": "Física",
        "detalhes": [
          {"tipo": "Prova 1", "nota": 3.5, "peso": 0.5},
          {"tipo": "Prova 2", "nota": 2.5, "peso": 0.5},
          {"tipo": "Atividade 1", "nota": 5.0, "peso": 0.5},
        ]
      },
      {
        "disciplina": "Matemática",
        "detalhes": [
          {"tipo": "Prova 1", "nota": 9.0, "peso": 0.5},
          {"tipo": "Prova 2", "nota": 8.0, "peso": 0.5},
          {"tipo": "Atividade 1", "nota": 9.0, "peso": 0.5}
        ]
      },
      {
        "disciplina": "Química",
        "detalhes": [
          {"tipo": "Prova 1", "nota": 3.5, "peso": 0.5},
          {"tipo": "Prova 2", "nota": 2.5, "peso": 0.5},
          {"tipo": "Atividade 1", "nota": 5.0, "peso": 0.5},
        ]
      },
    ];

    // Processa as disciplinas calculando as médias automaticamente
    setState(() {
      disciplinas = CalculadoraMedias.processarDisciplinas(dadosBrutos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return CustomScrollView(
      slivers: [
        // Título como SliverToBoxAdapter (mesma posição que em Disciplinas)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 20, 20, 30), // Mesma padding: top 20, bottom 30 para mais espaço
            child: Text(
              "Notas",
              style: TextStyle(
                fontSize: isMobile ? 22 : 25, // Ajustado para consistência com Disciplinas
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        // Conteúdo (search, legend, list) em SliverToBoxAdapter para mover para baixo
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16), // Padding horizontal igual ao original
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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

                /// LISTA DE DISCIPLINAS (agora sem Expanded, para caber no scroll)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7, // Altura flexível para o resto da tela
                  child: ListaDisciplinas(
                    disciplinas: disciplinas,
                    searchText: searchText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}