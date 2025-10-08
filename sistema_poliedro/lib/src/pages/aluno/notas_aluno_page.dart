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
    final dadosBrutos = [
      {
        "disciplina": "Física",
        "detalhes": [
          {"tipo": "Prova 1", "nota": 3.5, "peso": 0.5},
          {"tipo": "Prova 2", "nota": 2.5, "peso": 0.5},
          {"tipo": "Atividade 1", "nota": 5.0, "peso": 0.5},
        ],
      },
      {
        "disciplina": "Matemática",
        "detalhes": [
          {"tipo": "Prova 1", "nota": 9.0, "peso": 0.5},
          {"tipo": "Prova 2", "nota": 8.0, "peso": 0.5},
          {"tipo": "Atividade 1", "nota": 9.0, "peso": 1.0}
        ]
      },
      {
        "disciplina": "Química",
        "detalhes": [
          {"tipo": "Prova 1", "nota": 3.5, "peso": 0.5},
          {"tipo": "Prova 2", "nota": 2.5, "peso": 0.5},
          {"tipo": "Atividade 1", "nota": 5.0, "peso": 0.5},
        ],
      },
    ];

    setState(() {
      disciplinas = CalculadoraMedias.processarDisciplinas(dadosBrutos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 600;
            final double padding = isMobile ? 12.0 : 24.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// CABEÇALHO RESPONSIVO
                  _buildHeader(isMobile),
                  SizedBox(height: isMobile ? 12 : 20),

                  /// BARRA DE PESQUISA RESPONSIVA
                  _buildSearchBar(isMobile),
                  SizedBox(height: isMobile ? 12 : 20),

                  /// LEGENDA RESPONSIVA
                  _buildLegend(isMobile),
                  SizedBox(height: isMobile ? 12 : 16),

                  /// LISTA DE DISCIPLINAS
                  Expanded(
                    child: ListaDisciplinas(
                      disciplinas: disciplinas,
                      searchText: searchText,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notas",
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (!isMobile) const SizedBox(height: 4),
        if (!isMobile)
          Text(
            "Acompanhe seu desempenho acadêmico",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
      ],
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isMobile ? 20 : 30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => searchText = value.toLowerCase());
        },
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: "Pesquisar disciplina...",
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: EdgeInsets.symmetric(
            vertical: isMobile ? 8 : 12,
            horizontal: isMobile ? 12 : 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(isMobile ? 20 : 30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(bool isMobile) {
    return Wrap(
      spacing: isMobile ? 12 : 20,
      runSpacing: isMobile ? 8 : 0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: isMobile ? 4 : 6, 
              backgroundColor: Colors.red
            ),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              "Abaixo da média",
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: isMobile ? 4 : 6, 
              backgroundColor: Colors.teal
            ),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              "Acima da média",
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ],
        ),
      ],
    );
  }
}