import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/services/calculadora_medias.dart';

class DisciplinaCard extends StatelessWidget {
  final Map<String, dynamic> disciplina;
  final bool isExpanded;
  final VoidCallback onTap;

  const DisciplinaCard({
    super.key,
    required this.disciplina,
    required this.isExpanded,
    required this.onTap,
  });

  Map<String, dynamic> get _disciplinaProcessada {
    if (disciplina["mediaProvas"] != null &&
        disciplina["mediaAtividades"] != null &&
        disciplina["mediaFinal"] != null) {
      return disciplina;
    }
    return CalculadoraMedias.processarDisciplina(disciplina);
  }

  @override
  Widget build(BuildContext context) {
    final disciplinaProcessada = _disciplinaProcessada;
    bool acimaMedia = disciplinaProcessada["mediaFinal"] >= 6.0;

    return Card(
      color: Colors.white, // <- FONDO BRANCO PADRÃO
      elevation: 1.5,
      shadowColor: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme( // <- Remove o tom lilás interno do ExpansionTile
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          colorScheme: Theme.of(context).colorScheme.copyWith(
                surface: Colors.white,
                surfaceVariant: Colors.white,
              ),
        ),
        child: ExpansionTile(
          backgroundColor: Colors.grey.shade50, // <- Fundo leve quando fechado
          collapsedBackgroundColor: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: CircleAvatar(
            backgroundColor: acimaMedia ? Colors.teal : Colors.red,
            radius: 8,
          ),
          title: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  disciplinaProcessada["disciplina"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildNota("Média de Provas", disciplinaProcessada["mediaProvas"], destaque: true),
                    const SizedBox(width: 8),
                    _buildNota("Média de Atividades", disciplinaProcessada["mediaAtividades"], destaque: true),
                    const SizedBox(width: 8),
                    _buildNota("Média Final", disciplinaProcessada["mediaFinal"], destaque: true),
                  ],
                ),
              ),
            ],
          ),
          children: disciplinaProcessada["detalhes"].isNotEmpty
              ? [_buildTabelaDetalhes(disciplinaProcessada)]
              : [],
        ),
      ),
    );
  }

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

  Widget _buildTabelaDetalhes(Map<String, dynamic> disciplina) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                children: [
                  _buildCelulaCabecalho("Tipo"),
                  _buildCelulaCabecalho("Nota"),
                  _buildCelulaCabecalho("Peso"),
                ],
              ),
              ...disciplina["detalhes"].map<TableRow>((detalhe) {
                return TableRow(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade200,
                        width: 0.5,
                      ),
                    ),
                  ),
                  children: [
                    _buildCelulaConteudo(detalhe["tipo"]),
                    _buildCelulaNota(detalhe["nota"]),
                    _buildCelulaConteudo(detalhe["peso"].toString()),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelulaCabecalho(String texto) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        texto,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCelulaConteudo(String texto) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildCelulaNota(dynamic nota) {
    double notaValue = double.parse(nota.toString());
    Color corNota = notaValue >= 6 ? Colors.teal : Colors.red;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: corNota,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            nota.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: corNota,
            ),
          ),
        ],
      ),
    );
  }
}
