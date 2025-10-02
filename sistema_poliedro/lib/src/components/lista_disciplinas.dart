import 'package:flutter/material.dart';
import 'card_notas.dart';

class ListaDisciplinas extends StatefulWidget {
  final List<Map<String, dynamic>> disciplinas;
  final String searchText;

  const ListaDisciplinas({
    super.key,
    required this.disciplinas,
    required this.searchText,
  });

  @override
  State<ListaDisciplinas> createState() => _ListaDisciplinasState();
}

class _ListaDisciplinasState extends State<ListaDisciplinas> {
  int? _expandedIndex;

  void _toggleExpansion(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? null : index;
    });
  }

  List<Map<String, dynamic>> get _disciplinasFiltradas {
    if (widget.searchText.isEmpty) {
      return widget.disciplinas;
    }
    
    return widget.disciplinas.where((disciplina) {
      return disciplina["disciplina"]
          .toString()
          .toLowerCase()
          .contains(widget.searchText.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_disciplinasFiltradas.isEmpty) {
      return const Center(
        child: Text(
          "Nenhuma disciplina encontrada",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      children: _disciplinasFiltradas
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final disciplina = entry.value;
            
            return DisciplinaCard(
              disciplina: disciplina,
              isExpanded: _expandedIndex == index,
              onTap: () => _toggleExpansion(index),
            );
          })
          .toList(),
    );
  }
}