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

// Widget Stateful para gerenciar o estado das notas - VERSÃO RESPONSIVA
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
  final void Function(double) onMediaTurmaAtualizada;

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
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final num = double.tryParse(newValue.text);
    if (num == null) {
      return oldValue;
    }

    if (num < 0.0 || num > 10.0) {
      return oldValue;
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

  void _refreshData() {
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

    if (novasColunas.length != _colunasAvaliacao.length ||
        !const SetEquality().equals(
          novasColunas.toSet(),
          _colunasAvaliacao.toSet(),
        )) {
      setState(() {
        _colunasAvaliacao = novasColunas;
      });

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

        if (_controllers[aluno.id]![nome] == null) {
          _controllers[aluno.id]![nome] = TextEditingController(
            text: currentNota > 0 ? currentNota.toStringAsFixed(1) : '',
          );
        } else {
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

    if (oldWidget.disciplina.id != widget.disciplina.id ||
        oldWidget.disciplina.notas.length != widget.disciplina.notas.length) {
      _refreshData();
    } else {
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

      // Inclui TODAS as notas, mesmo as zero
      media += (currentNota * peso);
      totalPeso += peso;
    }

    if (totalPeso > 0) {
      media = media / totalPeso;
    }
    return media;
  }

  // SOLUÇÃO SIMPLES - APENAS MODIFIQUE O MÉTODO _saveAllNotas EXISTENTE
  Future<void> _saveAllNotas() async {
    if (_isSaving) return;

    _isSaving = true;
    setState(() {});

    try {
      int successCount = 0;
      int errorCount = 0;
      List<String> errors = [];

      // Processar todas as notas primeiro
      for (final aluno in _allAlunos) {
        try {
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
                id: notaExistente?.id ?? '',
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
          successCount++;
        } catch (e) {
          errorCount++;
          errors.add('${aluno.nome}: $e');
        }
      }

      final mediaAtualizada = _calcularMediaTurma();
      await widget.onReloadDisciplinas();

      // MOSTRAR APENAS UM ALERTA
      if (errorCount == 0) {
        widget.showSuccess(
          'Todas as $successCount notas foram salvas com sucesso!',
        );
      } else {
        widget.showSuccess(
          '$successCount notas salvas com sucesso. '
          '$errorCount notas não puderam ser salvas.',
        );
      }

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
    if (value.isEmpty) {
      setState(() {
        _localNotas[alunoId]![nome] = 0.0;
      });
      return;
    }

    final num = double.tryParse(value);

    if (num == null) {
      final previousValue = _localNotas[alunoId]![nome] ?? 0.0;
      _controllers[alunoId]![nome]!.text = previousValue > 0
          ? previousValue.toStringAsFixed(1)
          : '';
      return;
    }

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
      setState(() {
        _localNotas[alunoId]![nome] = num;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth < 1024;

    return Column(
      children: [
        // Header responsivo
        _buildHeader(isMobile, isTablet),

        // Tabela editável responsiva
        Expanded(
          child: Container(
            margin: EdgeInsets.fromLTRB(
              isMobile ? 8 : 16,
              isMobile ? 8 : 16,
              isMobile ? 8 : 16,
              isMobile ? 8 : 16,
            ),
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
            child: isMobile
                ? _buildMobileNotasView()
                : _buildDesktopNotasView(isTablet),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isMobile, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: isMobile ? _buildMobileHeader() : _buildDesktopHeader(isTablet),
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Linha 1: Botões principais
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.onAddGlobalAvaliacao(widget.disciplina),
                icon: const Icon(Icons.add, size: 16),
                label: Text('Avaliação', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: AppColors.branco,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            if (_colunasAvaliacao.isNotEmpty)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onManageAvaliacoes(widget.disciplina),
                  icon: const Icon(Icons.settings, size: 16),
                  label: Text('Gerenciar', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: AppColors.branco,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: 8),
        // Linha 2: Botão salvar
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAllNotas,
          icon: _isSaving
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.branco,
                  ),
                )
              : Icon(Icons.save, size: 16),
          label: Text(
            _isSaving ? 'Salvando...' : 'Salvar Todas',
            style: TextStyle(fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSaving
                ? Colors.grey
                : AppColors.verdeConfirmacao,
            foregroundColor: AppColors.branco,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader(bool isTablet) {
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: () => widget.onAddGlobalAvaliacao(widget.disciplina),
          icon: Icon(Icons.add, size: isTablet ? 16 : 18),
          label: Text(
            'Avaliação',
            style: TextStyle(fontSize: isTablet ? 12 : 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: AppColors.branco,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : 16,
              vertical: isTablet ? 8 : 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        SizedBox(width: 8),
        if (_colunasAvaliacao.isNotEmpty) ...[
          ElevatedButton.icon(
            onPressed: () => widget.onManageAvaliacoes(widget.disciplina),
            icon: Icon(Icons.settings, size: isTablet ? 16 : 18),
            label: Text(
              'Gerenciar',
              style: TextStyle(fontSize: isTablet ? 12 : 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: AppColors.branco,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 12 : 16,
                vertical: isTablet ? 8 : 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
        Spacer(),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _saveAllNotas,
          icon: _isSaving
              ? SizedBox(
                  width: isTablet ? 14 : 16,
                  height: isTablet ? 14 : 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(Icons.save, size: isTablet ? 16 : 18),
          label: Text(
            _isSaving ? 'Salvando...' : 'Salvar Todas as Notas',
            style: TextStyle(fontSize: isTablet ? 12 : 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _isSaving
                ? Colors.grey
                : AppColors.verdeConfirmacao,
            foregroundColor: AppColors.branco,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 16 : 20,
              vertical: isTablet ? 8 : 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileNotasView() {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _allAlunos.length,
      itemBuilder: (context, index) {
        final aluno = _allAlunos[index];
        final nota = widget.disciplina.notas.firstWhereOrNull(
          (n) => n.alunoId == aluno.id,
        );
        final media = _calcularMedia(aluno.id);

        return Card(
          color: AppColors.branco,
          margin: EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header do aluno
                Row(
                  children: [
                    _buildRACell(aluno, nota != null),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            aluno.nome,
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            nota != null
                                ? '${nota.avaliacoes.length} avaliações'
                                : 'Sem notas',
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              color: nota != null
                                  ? widget.primaryColor
                                  : Colors.orange,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildMediaCell(media),
                  ],
                ),

                SizedBox(height: 12),

                // VERSÃO MAIS SEGURA - sem spread operator
                // Avaliações
                if (_colunasAvaliacao.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avaliações:',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 8),
                      ..._colunasAvaliacao.map((nome) {
                        return _buildMobileNotaRow(aluno.id, nome);
                      }).toList(),
                    ],
                  )
                else
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Nenhuma avaliação cadastrada',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileNotaRow(String alunoId, String nome) {
    final tipo = _nomeToTipo[nome] ?? '';
    final color = tipo == 'atividade' ? Colors.green : widget.primaryColor;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: color,
                  ),
                ),
                Text(
                  '${tipo.toUpperCase()} • Peso: ${_nomeToPeso[nome]?.toStringAsFixed(1) ?? '1.0'}',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Container(
            width: 80,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[400]!, width: 1),
            ),
            child: TextField(
              controller: _controllers[alunoId]![nome]!,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^\d{1,2}(\.\d{0,2})?$'),
                ),
                _NotaInputFormatter(),
              ],
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 6,
                ),
                isDense: true,
                hintText: '0.0',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 12,
              ),
              onChanged: (value) => _onNotaChanged(alunoId, nome, value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopNotasView(bool isTablet) {
    return Column(
      children: [
        if (_colunasAvaliacao.length > 3)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '← Deslize para ver mais colunas →',
              style: TextStyle(
                fontSize: isTablet ? 10 : 12,
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
                  minWidth:
                      MediaQuery.of(context).size.width - (isTablet ? 48 : 32),
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
                      headingRowHeight: isTablet ? 70 : 80,
                      dataRowHeight: isTablet ? 60 : 70,
                      headingRowColor: MaterialStateProperty.all(
                        Colors.grey[50],
                      ),
                      dividerThickness: 1,
                      columnSpacing: isTablet ? 8 : 12,
                      horizontalMargin: isTablet ? 12 : 16,
                      headingTextStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF424242),
                        fontSize: isTablet ? 10 : 12,
                        letterSpacing: 0.5,
                      ),
                      dataTextStyle: AppTextStyles.fonteUbuntuSans.copyWith(
                        color: const Color(0xFF424242),
                        fontSize: isTablet ? 12 : 14,
                      ),
                      columns: [
                        DataColumn(
                          label: Text(
                            'RA',
                            style: TextStyle(fontSize: isTablet ? 10 : 12),
                          ),
                          numeric: false,
                          tooltip: 'Registro Acadêmico',
                        ),
                        DataColumn(
                          label: Text(
                            'Nome do Aluno',
                            style: TextStyle(fontSize: isTablet ? 10 : 12),
                          ),
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
                              constraints: BoxConstraints(
                                minWidth: isTablet ? 120 : 150,
                              ),
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
                                              fontSize: isTablet ? 10 : 12,
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    tipo.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: isTablet ? 8 : 10,
                                      color: color.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Peso: ${peso.toStringAsFixed(1)}',
                                    style: TextStyle(
                                      fontSize: isTablet ? 7 : 9,
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
                        DataColumn(
                          label: Text(
                            'Média',
                            style: TextStyle(fontSize: isTablet ? 10 : 12),
                          ),
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
                            DataCell(
                              _buildNomeCell(aluno, nota != null, isTablet),
                            ),
                            ..._colunasAvaliacao.map((nome) {
                              return DataCell(
                                _buildNotaCell(aluno.id, nome, isTablet),
                              );
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
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: hasNota
            ? widget.primaryColor.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
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
          fontSize: 10,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNomeCell(Usuario aluno, bool hasNota, bool isTablet) {
    final nota = widget.disciplina.notas.firstWhereOrNull(
      (n) => n.alunoId == aluno.id,
    );

    return SizedBox(
      width: isTablet ? 120 : 150,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            aluno.nome,
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: isTablet ? 12 : 14,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            hasNota ? '${nota?.avaliacoes.length} avaliações' : 'Sem notas',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              color: hasNota ? widget.primaryColor : Colors.orange,
              fontSize: isTablet ? 9 : 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaCell(String alunoId, String nome, bool isTablet) {
    final tipo = _nomeToTipo[nome] ?? '';
    final color = tipo == 'atividade' ? Colors.green : widget.primaryColor;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: isTablet ? 80 : 100,
          height: isTablet ? 32 : 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey[400]!, width: 1.5),
          ),
          child: TextField(
            controller: _controllers[alunoId]![nome]!,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                RegExp(r'^\d{1,2}(\.\d{0,2})?$'),
              ),
              _NotaInputFormatter(),
            ],
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 6,
                vertical: isTablet ? 6 : 8,
              ),
              isDense: true,
              hintText: '0.0',
              hintStyle: TextStyle(
                color: Colors.grey,
                fontSize: isTablet ? 12 : 14,
              ),
            ),
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: isTablet ? 12 : 14,
            ),
            onChanged: (value) => _onNotaChanged(alunoId, nome, value),
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Peso: ${_nomeToPeso[nome]?.toStringAsFixed(1) ?? '1.0'}',
          style: TextStyle(fontSize: isTablet ? 8 : 9, color: Colors.grey[600]),
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        temNota ? media.toStringAsFixed(1) : '-',
        style: AppTextStyles.fonteUbuntu.copyWith(
          fontWeight: FontWeight.w700,
          color: textColor,
          fontSize: 12,
        ),
      ),
    );
  }
}
