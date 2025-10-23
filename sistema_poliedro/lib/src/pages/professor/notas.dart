// Widget Stateful para gerenciar o estado das notas
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:collection/collection.dart';

import '../../styles/cores.dart';
import '../../styles/fontes.dart';

import 'package:sistema_poliedro/src/pages/professor/administracao_page.dart';
import '../../models/modelo_disciplina.dart';
import '../../models/modelo_avaliacao.dart';
import '../../models/modelo_nota.dart';
import '../../models/modelo_usuario.dart';

// Widget Stateful para gerenciar o estado das notas - CORRIGIDO
class NotasDataTable extends StatefulWidget {
  final Disciplina disciplina;
  final Color primaryColor;
  final Future<void> Function(Disciplina) onAddGlobalAvaliacao;
  final Future<void> Function(Disciplina) onManageAvaliacoes;
  final Future<void> Function(Nota) onCreateNota;
  final Future<void> Function(String, Nota) onUpdateNota;
  final Future<void> Function() onReloadDisciplinas;
  final void Function(String) showSuccess;
  final void Function(String) showError;
  final void Function(double)
  onMediaTurmaAtualizada; // NOVO: callback para atualizar média

  const NotasDataTable({
    super.key,
    required this.disciplina,
    required this.primaryColor,
    required this.onAddGlobalAvaliacao,
    required this.onManageAvaliacoes,
    required this.onCreateNota,
    required this.onUpdateNota,
    required this.onReloadDisciplinas,
    required this.showSuccess,
    required this.showError,
    required this.onMediaTurmaAtualizada,
  });

  @override
  State<NotasDataTable> createState() => _NotasDataTableState();
}

class _NotaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Se estiver vazio, permite
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Verifica se é um número válido
    final num = double.tryParse(newValue.text);
    if (num == null) {
      return oldValue; // Não permite caracteres não numéricos
    }

    // Verifica se está dentro do range permitido
    if (num < 0.0 || num > 10.0) {
      return oldValue; // Não permite valores fora do range
    }

    return newValue;
  }
}

class _NotasDataTableState extends State<NotasDataTable> {
  final _horizontalController = ScrollController();
  final _verticalController = ScrollController();
  final Map<String, Map<String, TextEditingController>> _controllers = {};
  final Map<String, Map<String, double?>> _localNotas = {};
  late List<Usuario> _allAlunos;
  late List<String> _colunasAvaliacao;
  late Map<String, String> _nomeToTipo;
  late Map<String, double> _nomeToPeso;
  bool _isSaving = false;

  @override
  void dispose() {
    // Limpar todos os controllers
    for (final alunoControllers in _controllers.values) {
      for (final controller in alunoControllers.values) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  // NOVO: Método para calcular média da turma
  double _calcularMediaTurma() {
    double somaMedias = 0.0;
    int alunosComNota = 0;

    for (final aluno in _allAlunos) {
      final mediaAluno = _calcularMedia(aluno.id);
      if (mediaAluno > 0) {
        somaMedias += mediaAluno;
        alunosComNota++;
      }
    }

    return alunosComNota > 0 ? somaMedias / alunosComNota : 0.0;
  }

  // Método para atualizar os dados quando uma nova avaliação é adicionada
  void _refreshData() {
    // Coletar avaliações atualizadas
    final Set<String> avaliacaoNomes = <String>{};
    _nomeToTipo.clear();
    _nomeToPeso.clear();

    for (final nota in widget.disciplina.notas) {
      for (final av in nota.avaliacoes) {
        avaliacaoNomes.add(av.nome);
        _nomeToTipo[av.nome] = av.tipo;
        _nomeToPeso[av.nome] = av.peso ?? 1.0;
      }
    }

    final novasColunas = avaliacaoNomes.toList();

    // Verificar se houve mudanças nas colunas
    if (novasColunas.length != _colunasAvaliacao.length ||
        !const SetEquality().equals(
          novasColunas.toSet(),
          _colunasAvaliacao.toSet(),
        )) {
      setState(() {
        _colunasAvaliacao = novasColunas;
      });

      // Atualizar controllers para as novas colunas
      for (final aluno in _allAlunos) {
        final nota = widget.disciplina.notas.firstWhereOrNull(
          (n) => n.alunoId == aluno.id,
        );

        for (final nome in _colunasAvaliacao) {
          if (_controllers[aluno.id]![nome] == null) {
            final av = nota?.avaliacoes.firstWhereOrNull((a) => a.nome == nome);
            final currentNota = av?.nota ?? 0.0;

            _controllers[aluno.id]![nome] = TextEditingController(
              text: currentNota > 0 ? currentNota.toStringAsFixed(1) : '',
            );
            _localNotas[aluno.id]![nome] = currentNota;
          }
        }
      }
    }
  }

  void _initializeData() {
    _allAlunos = List<Usuario>.from(widget.disciplina.alunos)
      ..sort((a, b) => a.nome.compareTo(b.nome));

    // Coletar todas as avaliações únicas
    final Set<String> avaliacaoNomes = <String>{};
    _nomeToTipo = {};
    _nomeToPeso = {};

    for (final nota in widget.disciplina.notas) {
      for (final av in nota.avaliacoes) {
        avaliacaoNomes.add(av.nome);
        _nomeToTipo[av.nome] = av.tipo;
        _nomeToPeso[av.nome] = av.peso ?? 1.0;
      }
    }

    _colunasAvaliacao = avaliacaoNomes.toList();

    // Inicializar controllers e notas locais APENAS UMA VEZ
    for (final aluno in _allAlunos) {
      _controllers[aluno.id] = {};
      _localNotas[aluno.id] = {};
      final nota = widget.disciplina.notas.firstWhereOrNull(
        (n) => n.alunoId == aluno.id,
      );

      for (final nome in _colunasAvaliacao) {
        final av = nota?.avaliacoes.firstWhereOrNull((a) => a.nome == nome);
        final currentNota = av?.nota ?? 0.0;
        _localNotas[aluno.id]![nome] = currentNota;

        // Verificar se o controller já existe antes de criar um novo
        if (_controllers[aluno.id]![nome] == null) {
          _controllers[aluno.id]![nome] = TextEditingController(
            text: currentNota > 0 ? currentNota.toStringAsFixed(1) : '',
          );
        } else {
          // Se já existe, apenas atualize o texto se necessário
          final currentText = _controllers[aluno.id]![nome]!.text;
          final expectedText = currentNota > 0
              ? currentNota.toStringAsFixed(1)
              : '';
          if (currentText != expectedText) {
            _controllers[aluno.id]![nome]!.text = expectedText;
          }
        }
      }
    }
  }

  @override
  void didUpdateWidget(NotasDataTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Atualizar sempre que a disciplina mudar
    if (oldWidget.disciplina.id != widget.disciplina.id ||
        oldWidget.disciplina.notas.length != widget.disciplina.notas.length) {
      _refreshData();
    } else {
      // Verificar se houve mudanças nas avaliações
      bool avaliacoesMudaram = false;
      for (final nota in widget.disciplina.notas) {
        for (final av in nota.avaliacoes) {
          if (!_nomeToTipo.containsKey(av.nome) ||
              _nomeToTipo[av.nome] != av.tipo ||
              _nomeToPeso[av.nome] != av.peso) {
            avaliacoesMudaram = true;
            break;
          }
        }
        if (avaliacoesMudaram) break;
      }

      if (avaliacoesMudaram) {
        _refreshData();
      }
    }
  }

  double _calcularMedia(String alunoId) {
    double media = 0.0;
    double totalPeso = 0.0;

    for (final nome in _colunasAvaliacao) {
      final currentNota = _localNotas[alunoId]![nome] ?? 0.0;
      final peso = _nomeToPeso[nome] ?? 1.0;
      if (currentNota > 0) {
        media += (currentNota * peso);
        totalPeso += peso;
      }
    }

    if (totalPeso > 0) {
      media = media / totalPeso;
    }
    return media;
  }

  // NO MÉTODO _saveAllNotas, modifique para evitar o loop:
  Future<void> _saveAllNotas() async {
    if (_isSaving) return;

    _isSaving = true;
    setState(() {});

    try {
      for (final aluno in _allAlunos) {
        final notaExistente = widget.disciplina.notas.firstWhereOrNull(
          (n) => n.alunoId == aluno.id,
        );

        final avaliacoes = <Avaliacao>[];
        for (final nome in _colunasAvaliacao) {
          final notaValue = _localNotas[aluno.id]![nome] ?? 0.0;
          final avExistente = notaExistente?.avaliacoes.firstWhereOrNull(
            (a) => a.nome == nome,
          );

          final avaliacao =
              avExistente?.copyWith(nota: notaValue) ??
              Avaliacao(
                id: '',
                nome: nome,
                tipo: _nomeToTipo[nome] ?? 'prova',
                nota: notaValue,
                peso: _nomeToPeso[nome] ?? 1.0,
                data: DateTime.now(),
              );

          avaliacoes.add(avaliacao);
        }

        final notaToSave =
            notaExistente?.copyWith(avaliacoes: avaliacoes) ??
            Nota(
              id: '',
              disciplinaId: widget.disciplina.id,
              alunoId: aluno.id,
              alunoNome: aluno.nome,
              alunoRa: aluno.ra,
              avaliacoes: avaliacoes,
            );

        if (notaExistente == null) {
          await widget.onCreateNota(notaToSave);
        } else {
          await widget.onUpdateNota(notaExistente.id, notaToSave);
        }
      }

      // NOVA IMPLEMENTAÇÃO: Calcular a média ANTES de recarregar
      final mediaAtualizada = _calcularMediaTurma();

      // Recarregar disciplinas SEM mostrar alerta interno
      await widget.onReloadDisciplinas();

      // Mostrar sucesso APENAS UMA VEZ
      widget.showSuccess('Todas as notas foram salvas com sucesso!');

      // Notificar a média atualizada DEPOIS do sucesso
      widget.onMediaTurmaAtualizada(mediaAtualizada);
    } catch (e) {
      widget.showError('Erro ao salvar notas: $e');
    } finally {
      _isSaving = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _onNotaChanged(String alunoId, String nome, String value) {
    // Se estiver vazio, define como 0.0
    if (value.isEmpty) {
      setState(() {
        _localNotas[alunoId]![nome] = 0.0;
      });

      return;
    }

    final num = double.tryParse(value);

    // Se não for um número válido, mantém o valor anterior
    if (num == null) {
      // Restaura o valor anterior no controller
      final previousValue = _localNotas[alunoId]![nome] ?? 0.0;
      _controllers[alunoId]![nome]!.text = previousValue > 0
          ? previousValue.toStringAsFixed(1)
          : '';
      return;
    }

    // Validação: deve estar entre 0.0 e 10.0
    if (num < 0.0) {
      setState(() {
        _localNotas[alunoId]![nome] = 0.0;
      });
      _controllers[alunoId]![nome]!.text = '0.0';
    } else if (num > 10.0) {
      setState(() {
        _localNotas[alunoId]![nome] = 10.0;
      });
      _controllers[alunoId]![nome]!.text = '10.0';
    } else {
      // Valor válido
      setState(() {
        _localNotas[alunoId]![nome] = num;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header com botões de ação
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => widget.onAddGlobalAvaliacao(widget.disciplina),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Avaliação'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: AppColors.branco,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_colunasAvaliacao.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: () => widget.onManageAvaliacoes(widget.disciplina),
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Gerenciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: AppColors.branco,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveAllNotas,
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 18),
                label: Text(
                  _isSaving ? 'Salvando...' : 'Salvar Todas as Notas',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isSaving
                      ? Colors.grey
                      : AppColors.verdeConfirmacao,
                  foregroundColor: AppColors.branco,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tabela editável
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.preto.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: _buildDataTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return Column(
      children: [
        // Indicador de scroll (opcional)
        if (_colunasAvaliacao.length > 3)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '← Deslize para ver mais colunas →',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        Expanded(
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    physics: const ClampingScrollPhysics(),
                    child: DataTable(
                      headingRowHeight: 80,
                      dataRowHeight: 70,
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey[50],
                      ),
                      dividerThickness: 1,
                      columnSpacing: 12,
                      horizontalMargin: 16,
                      headingTextStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF424242),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                      dataTextStyle: AppTextStyles.fonteUbuntuSans.copyWith(
                        color: const Color(0xFF424242),
                        fontSize: 14,
                      ),
                      columns: [
                        const DataColumn(
                          label: Text('RA'),
                          numeric: false,
                          tooltip: 'Registro Acadêmico',
                        ),
                        const DataColumn(
                          label: Text('Nome do Aluno'),
                          tooltip: 'Nome completo do aluno',
                        ),
                        ..._colunasAvaliacao.map((nome) {
                          final tipo = _nomeToTipo[nome] ?? '';
                          final peso = _nomeToPeso[nome] ?? 1.0;
                          final color = tipo == 'atividade'
                              ? Colors.green
                              : widget.primaryColor;

                          return DataColumn(
                            label: Container(
                              constraints: const BoxConstraints(minWidth: 150),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Tooltip(
                                      message: nome,
                                      child: Text(
                                        nome,
                                        style: AppTextStyles.fonteUbuntu
                                            .copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    tipo.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: color.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Peso: ${peso.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: color.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        const DataColumn(
                          label: Text('Média'),
                          tooltip: 'Média ponderada das avaliações',
                        ),
                      ],
                      rows: _allAlunos.map((aluno) {
                        final nota = widget.disciplina.notas.firstWhereOrNull(
                          (n) => n.alunoId == aluno.id,
                        );
                        final media = _calcularMedia(aluno.id);

                        return DataRow(
                          key: ValueKey(aluno.id),
                          color: MaterialStateProperty.resolveWith<Color?>((
                            Set<MaterialState> states,
                          ) {
                            if (states.contains(MaterialState.hovered)) {
                              return widget.primaryColor.withOpacity(0.05);
                            }
                            if (nota == null) {
                              return Colors.orange.withOpacity(0.05);
                            }
                            return null;
                          }),
                          cells: [
                            DataCell(_buildRACell(aluno, nota != null)),
                            DataCell(_buildNomeCell(aluno, nota != null)),
                            ..._colunasAvaliacao.map((nome) {
                              return DataCell(_buildNotaCell(aluno.id, nome));
                            }).toList(),
                            DataCell(_buildMediaCell(media)),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRACell(Usuario aluno, bool hasNota) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasNota
            ? widget.primaryColor.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasNota
              ? widget.primaryColor.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Text(
        aluno.ra ?? '-',
        style: AppTextStyles.fonteUbuntu.copyWith(
          color: hasNota ? widget.primaryColor : Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildNomeCell(Usuario aluno, bool hasNota) {
    final nota = widget.disciplina.notas.firstWhereOrNull(
      (n) => n.alunoId == aluno.id,
    );

    return SizedBox(
      width: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            aluno.nome,
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            hasNota ? '${nota?.avaliacoes.length} avaliações' : 'Sem notas',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              color: hasNota ? widget.primaryColor : Colors.orange,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaCell(String alunoId, String nome) {
    final tipo = _nomeToTipo[nome] ?? '';
    final color = tipo == 'atividade' ? Colors.green : widget.primaryColor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[400]!, width: 1.5),
          ),
          child: TextField(
            controller: _controllers[alunoId]![nome]!,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // No método _buildNotaCell, substitua os inputFormatters por:
            inputFormatters: [
              // Permite apenas números com até 2 casas decimais
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d{1,2}(\.\d{0,2})?$'),
              ),
              // Validação customizada para limitar o valor
              _NotaInputFormatter(),
            ],
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              isDense: true,
              hintText: '0.0',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 14,
            ),
            onChanged: (value) => _onNotaChanged(alunoId, nome, value),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Peso: ${_nomeToPeso[nome]?.toStringAsFixed(1) ?? '1.0'}',
          style: TextStyle(fontSize: 9, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildMediaCell(double media) {
    final bool isAprovado = media >= 6.0;
    final bool temNota = media > 0;

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (!temNota) {
      backgroundColor = Colors.grey[100]!;
      borderColor = Colors.grey[300]!;
      textColor = Colors.grey[500]!;
    } else if (isAprovado) {
      backgroundColor = AppColors.verdeConfirmacao.withOpacity(0.1);
      borderColor = AppColors.verdeConfirmacao;
      textColor = AppColors.verdeConfirmacao;
    } else {
      backgroundColor = AppColors.vermelhoErro.withOpacity(0.1);
      borderColor = AppColors.vermelhoErro;
      textColor = AppColors.vermelhoErro;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        temNota ? media.toStringAsFixed(1) : '-',
        style: AppTextStyles.fonteUbuntu.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 14,
        ),
      ),
    );
  }
}
