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
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.grey.shade200,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
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
          leading: CircleAvatar(
            backgroundColor: acimaMedia ? Colors.teal : Colors.red,
            radius: 8,
          ),
          onExpansionChanged: (expanded) => onTap(),
          title: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return _buildLayoutMobile(disciplinaProcessada);
              }
              return _buildLayoutDesktop(disciplinaProcessada);
            },
          ),
          children: disciplinaProcessada["detalhes"].isNotEmpty
              ? [_buildTabelaDetalhes(disciplinaProcessada)]
              : [],
        ),
      ),
    );
  }

  /// Layout para Desktop/Tablet
  Widget _buildLayoutDesktop(Map<String, dynamic> disciplina) {
    return Row(
      children: [
        /// Nome da disciplina à esquerda
        Expanded(
          flex: 2,
          child: Text(
            disciplina["disciplina"],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),

        /// Notas centralizadas
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNotaItem(
                "Média Provas",
                disciplina["mediaProvas"],
                isDestaque: true,
              ),
              _buildNotaItem(
                "Média Atividades",
                disciplina["mediaAtividades"],
                isDestaque: true,
              ),
              _buildNotaItem(
                "Média Final",
                disciplina["mediaFinal"],
                isDestaque: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Layout para Mobile
  Widget _buildLayoutMobile(Map<String, dynamic> disciplina) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Nome da disciplina
        Text(
          disciplina["disciplina"],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),

        /// Notas em linha (mobile)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNotaItem(
              "Média Provas",
              disciplina["mediaProvas"],
              isDestaque: true,
            ),
            _buildNotaItem(
              "Média Atividades",
              disciplina["mediaAtividades"],
              isDestaque: true,
            ),
            _buildNotaItem(
              "Média Final",
              disciplina["mediaFinal"],
              isDestaque: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Widget para cada item de nota (responsivo)
  Widget _buildNotaItem(
    String titulo,
    double valor, {
    bool isDestaque = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isMobile = constraints.maxWidth < 400;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMobile ? _abreviarTitulo(titulo) : titulo,
              style: TextStyle(
                fontSize: isMobile ? 10 : 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              valor.toStringAsFixed(1),
              style: TextStyle(
                fontSize: isDestaque
                    ? (isMobile ? 14 : 16)
                    : (isMobile ? 12 : 14),
                fontWeight: isDestaque ? FontWeight.bold : FontWeight.normal,
                color: isDestaque
                    ? (valor >= 6 ? Colors.teal : Colors.red)
                    : Colors.black87,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Abrevia títulos para mobile
  String _abreviarTitulo(String titulo) {
    switch (titulo) {
      case "Média Provas":
        return "Provas";
      case "Média Atividades":
        return "Ativid.";
      case "Média Final":
        return "Final";
      default:
        return titulo;
    }
  }

  /// TABELA RESPONSIVA COM DIVISÕES
  Widget _buildTabelaDetalhes(Map<String, dynamic> disciplina) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isMobile = constraints.maxWidth < 600;

          if (isMobile && disciplina["detalhes"].length > 3) {
            return _buildTabelaScroll(disciplina);
          } else {
            return _buildTabelaNormal(disciplina, isMobile);
          }
        },
      ),
    );
  }

  /// Tabela normal para desktop/tablet COM DIVISÕES
  Widget _buildTabelaNormal(Map<String, dynamic> disciplina, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Table(
          border: TableBorder(
            horizontalInside: BorderSide(
              color: Colors.grey.shade300,
              width: 1.0,
            ),
            verticalInside: BorderSide(color: Colors.grey.shade300, width: 1.0),
            top: BorderSide(color: Colors.grey.shade300, width: 1.0),
            bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
            left: BorderSide(color: Colors.grey.shade300, width: 1.0),
            right: BorderSide(color: Colors.grey.shade300, width: 1.0),
          ),
          columnWidths: isMobile
              ? const {
                  0: FlexColumnWidth(1.5),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                }
              : const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
          children: [
            /// CABEÇALHO COM DIVISÕES
            TableRow(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade400, width: 1.5),
                ),
              ),
              children: [
                _buildCelulaCabecalho(
                  "Avaliação",
                  isMobile,
                ), // MUDADO: "Tipo" → "Avaliação"
                _buildCelulaCabecalho("Nota", isMobile),
                _buildCelulaCabecalho("Peso", isMobile),
              ],
            ),

            /// LINHAS DOS DETALHES COM DIVISÕES
            ...disciplina["detalhes"].asMap().entries.map<TableRow>((entry) {
              final index = entry.key;
              final detalhe = entry.value;
              final bool isLast = index == disciplina["detalhes"].length - 1;

              return TableRow(
                decoration: BoxDecoration(
                  color: index.isEven ? Colors.white : Colors.grey[50],
                ),
                children: [
                  // MUDADO: detalhe["tipo"] → detalhe["nome"] ?? detalhe["tipo"]
                  _buildCelulaConteudo(
                    detalhe["nome"] ?? detalhe["tipo"],
                    isMobile,
                    isLast: isLast,
                  ),
                  _buildCelulaNota(detalhe["nota"], isMobile, isLast: isLast),
                  _buildCelulaConteudo(
                    detalhe["peso"].toString(),
                    isMobile,
                    isLast: isLast,
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  /// Tabela com scroll horizontal para mobile COM DIVISÕES
  Widget _buildTabelaScroll(Map<String, dynamic> disciplina) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: const BoxConstraints(minWidth: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
              verticalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 1.0,
              ),
              top: BorderSide(color: Colors.grey.shade300, width: 1.0),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
              left: BorderSide(color: Colors.grey.shade300, width: 1.0),
              right: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            defaultColumnWidth: const FixedColumnWidth(100),
            children: [
              /// CABEÇALHO
              TableRow(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade400, width: 1.5),
                  ),
                ),
                children: [
                  _buildCelulaCabecalho(
                    "Avaliação",
                    true,
                  ), // MUDADO: "Tipo" → "Avaliação"
                  _buildCelulaCabecalho("Nota", true),
                  _buildCelulaCabecalho("Peso", true),
                ],
              ),

              /// LINHAS
              ...disciplina["detalhes"].asMap().entries.map<TableRow>((entry) {
                final index = entry.key;
                final detalhe = entry.value;
                final bool isLast = index == disciplina["detalhes"].length - 1;

                return TableRow(
                  decoration: BoxDecoration(
                    color: index.isEven ? Colors.white : Colors.grey[50],
                  ),
                  children: [
                    // MUDADO: detalhe["tipo"] → detalhe["nome"] ?? detalhe["tipo"]
                    _buildCelulaConteudo(
                      detalhe["nome"] ?? detalhe["tipo"],
                      true,
                      isLast: isLast,
                    ),
                    _buildCelulaNota(detalhe["nota"], true, isLast: isLast),
                    _buildCelulaConteudo(
                      detalhe["peso"].toString(),
                      true,
                      isLast: isLast,
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCelulaCabecalho(String texto, bool isMobile) {
    return Container(
      padding: isMobile
          ? const EdgeInsets.all(10.0)
          : const EdgeInsets.all(14.0),
      child: Text(
        texto,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isMobile ? 12 : 13,
          color: Colors.black87,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCelulaConteudo(
    String texto,
    bool isMobile, {
    bool isLast = false,
  }) {
    return Container(
      padding: isMobile
          ? const EdgeInsets.all(10.0)
          : const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: isMobile ? 11 : 12, color: Colors.black87),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCelulaNota(dynamic nota, bool isMobile, {bool isLast = false}) {
    double notaValue = double.parse(nota.toString());
    Color corNota = notaValue >= 6 ? Colors.teal : Colors.red;

    return Container(
      padding: isMobile
          ? const EdgeInsets.all(10.0)
          : const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: corNota, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            nota.toString(),
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: corNota,
            ),
          ),
        ],
      ),
    );
  }
}
