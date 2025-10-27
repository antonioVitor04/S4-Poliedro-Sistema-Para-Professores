// pages/notificacoes_professor_page.dart
import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import '../../services/mensagens_prof_service.dart';
import '../../services/auth_service.dart';

class NotificacoesProfessorPage extends StatefulWidget {
  const NotificacoesProfessorPage({super.key});

  @override
  State<NotificacoesProfessorPage> createState() =>
      _NotificacoesProfessorPageState();
}

class _NotificacoesProfessorPageState extends State<NotificacoesProfessorPage> {
  final List<DisciplinaCheckbox> _disciplinas = [];
  final TextEditingController _mensagemController = TextEditingController();
  final TextEditingController _editarMensagemController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<MensagemEnviada> _mensagensEnviadas = [];
  bool _isLoading = true;
  bool _enviandoMensagem = false;
  String? _errorMessage;
  String? _nomeProfessor;
  bool _expandidoDisciplinas = false;

  // Novos estados para controle de seleção
  final Set<String> _mensagensSelecionadas = {};
  bool _modoSelecao = false;
  String? _mensagemEditandoId;

  // Paginação corrigida - 5 mensagens por página
  final int _mensagensPorPagina = 5;
  int _paginaAtual = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mensagemController.dispose();
    _editarMensagemController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Usuário não autenticado';
          _isLoading = false;
        });
        return;
      }

      await _carregarInfoProfessor();
      await _carregarDisciplinas();
      await _carregarMensagensEnviadas();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _carregarInfoProfessor() async {
    try {
      final professorInfo = await MensagensProfessorService.getProfessorInfo();
      if (professorInfo != null) {
        setState(() {
          _nomeProfessor = professorInfo['nome']?.toString();
        });
      }
    } catch (e) {
      print('Erro ao carregar info do professor: $e');
    }
  }

  Future<void> _carregarDisciplinas() async {
    try {
      final disciplinasData =
          await MensagensProfessorService.fetchDisciplinasProfessor();
      setState(() {
        _disciplinas.clear();
        _disciplinas.addAll(
          disciplinasData.map(
            (disciplina) => DisciplinaCheckbox(
              id: disciplina['_id']?.toString() ?? '',
              nome:
                  disciplina['titulo']?.toString() ??
                  disciplina['nome']?.toString() ??
                  'Disciplina',
              selecionada: false,
            ),
          ),
        );
      });
    } catch (e) {
      throw Exception('Erro ao carregar disciplinas: $e');
    }
  }

  Future<void> _carregarMensagensEnviadas() async {
    try {
      final mensagensData =
          await MensagensProfessorService.fetchMensagensEnviadas();

      final mensagensValidas = <MensagemEnviada>[];
      for (final item in mensagensData) {
        try {
          if (item is Map<String, dynamic>) {
            final mensagem = MensagemEnviada.fromJson(item);
            if (mensagem.mensagem.isNotEmpty &&
                mensagem.mensagem != 'Mensagem não disponível' &&
                mensagem.id.isNotEmpty) {
              mensagensValidas.add(mensagem);
            }
          }
        } catch (e) {
          print('Item inválido ignorado: $e');
        }
      }

      setState(() {
        _mensagensEnviadas = mensagensValidas;
        _mensagensEnviadas.sort((a, b) => b.data.compareTo(a.data));
        _isLoading = false;
        _paginaAtual = 1; // Resetar para primeira página
      });
    } catch (e) {
      print('Erro ao carregar mensagens enviadas: $e');
      setState(() {
        _mensagensEnviadas = [];
        _isLoading = false;
      });
    }
  }

  // Getter para mensagens da página atual
  List<MensagemEnviada> get _mensagensPaginaAtual {
    final startIndex = (_paginaAtual - 1) * _mensagensPorPagina;
    final endIndex = startIndex + _mensagensPorPagina;

    if (startIndex >= _mensagensEnviadas.length) {
      return [];
    }

    return _mensagensEnviadas.sublist(
      startIndex,
      endIndex > _mensagensEnviadas.length
          ? _mensagensEnviadas.length
          : endIndex,
    );
  }

  // Total de páginas
  int get _totalPaginas {
    return (_mensagensEnviadas.length / _mensagensPorPagina).ceil();
  }

  // Mudar página
  void _mudarPagina(int novaPagina) {
    setState(() {
      _paginaAtual = novaPagina;
    });
  }

  Future<void> _enviarMensagem() async {
    final mensagemTexto = _mensagemController.text.trim();

    if (mensagemTexto.isEmpty) {
      _mostrarSnackBar('Digite uma mensagem', tipo: SnackBarTipo.erro);
      return;
    }

    final disciplinasSelecionadas = _disciplinas
        .where((d) => d.selecionada)
        .toList();
    if (disciplinasSelecionadas.isEmpty) {
      _mostrarSnackBar(
        'Selecione pelo menos uma disciplina',
        tipo: SnackBarTipo.erro,
      );
      return;
    }

    setState(() {
      _enviandoMensagem = true;
    });

    try {
      await MensagensProfessorService.enviarMensagem(
        mensagem: mensagemTexto,
        disciplinasIds: disciplinasSelecionadas.map((d) => d.id).toList(),
      );

      _mensagemController.clear();
      for (var disciplina in _disciplinas) {
        disciplina.selecionada = false;
      }

      _mostrarSnackBar(
        'Mensagem enviada com sucesso!',
        tipo: SnackBarTipo.sucesso,
      );

      await _carregarMensagensEnviadas();

      // Scroll para o topo para ver a nova mensagem
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      _mostrarSnackBar('Erro ao enviar mensagem: $e', tipo: SnackBarTipo.erro);
    } finally {
      setState(() {
        _enviandoMensagem = false;
      });
    }
  }

  void _mostrarSnackBar(String mensagem, {required SnackBarTipo tipo}) {
    final backgroundColor = tipo == SnackBarTipo.sucesso
        ? Colors.green.shade600
        : tipo == SnackBarTipo.erro
        ? Colors.red.shade600
        : Colors.blue.shade600;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              tipo == SnackBarTipo.sucesso
                  ? Icons.check_circle
                  : tipo == SnackBarTipo.erro
                  ? Icons.error
                  : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensagem,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _toggleDisciplina(int index) {
    setState(() {
      _disciplinas[index].selecionada = !_disciplinas[index].selecionada;
    });
  }

  void _selecionarTodasDisciplinas(bool selecionar) {
    setState(() {
      for (var disciplina in _disciplinas) {
        disciplina.selecionada = selecionar;
      }
    });
  }

  Widget _buildFormularioMensagem() {
    return FutureBuilder<bool>(
      future: AuthService.isAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header do card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.send_rounded,
                      color: AppColors.azulClaro,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nova Mensagem',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),

                          if (isAdmin)
                            Text(
                              'Modo Administrador',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: Colors.grey),
                      onPressed: _isLoading ? null : _loadData,
                      tooltip: 'Recarregar',
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

              // Conteúdo do formulário
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Campo de mensagem
                    TextFormField(
                      cursorColor: AppColors.azulClaro,
                      controller: _mensagemController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: 'Mensagem',
                        labelStyle: const TextStyle(color: Colors.black54),
                        hintText: 'Digite sua mensagem para os alunos...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.azulClaro),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Seção de disciplinas - CORRIGIDA
                    _buildSelecaoDisciplinas(),
                    const SizedBox(height: 24),

                    // Botão enviar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enviandoMensagem ? null : _enviarMensagem,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.azulClaro,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          shadowColor: Colors.transparent,
                        ),
                        child: _enviandoMensagem
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Enviando...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.send_rounded,
                                    size: 20,
                                    color: AppColors.branco,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Enviar Mensagem',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // CORREÇÃO: Widget de seleção de disciplinas com tamanho fixo
  // CORREÇÃO: Widget de seleção de disciplinas com botão "Ver todas" funcionando
  Widget _buildSelecaoDisciplinas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Disciplinas Destino',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            if (_disciplinas.length > 1)
              TextButton.icon(
                onPressed: () => _selecionarTodasDisciplinas(true),
                icon: Icon(
                  Icons.checklist_rounded,
                  size: 18,
                  color: AppColors.azulClaro,
                ),
                label: Text(
                  'Selecionar Todas',
                  style: TextStyle(color: AppColors.azulClaro),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // CORREÇÃO: Container com altura fixa mas expansível
        Container(
          constraints: BoxConstraints(
            maxHeight: _expandidoDisciplinas
                ? 400
                : 150, // Altura máxima quando expandido
          ),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: _disciplinas.isEmpty
              ? _buildEmptyState(
                  icon: Icons.class_rounded,
                  title: 'Nenhuma disciplina disponível',
                  subtitle: 'Entre em contato com o administrador',
                  height: 150,
                )
              : Column(
                  children: [
                    // Lista expansível
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _disciplinas.length,
                        itemBuilder: (context, index) {
                          final disciplina = _disciplinas[index];
                          return CheckboxListTile(
                            title: Text(
                              disciplina.nome,
                              style: const TextStyle(fontSize: 14),
                            ),
                            activeColor: AppColors.azulClaro,
                            value: disciplina.selecionada,
                            onChanged: (value) => _toggleDisciplina(index),
                            dense: true,
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            tileColor: disciplina.selecionada
                                ? AppColors.azulClaro.withOpacity(0.1)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          );
                        },
                      ),
                    ),

                    // Botão "Ver todas" apenas se houver mais de 3 disciplinas
                    if (_disciplinas.length > 3)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _expandidoDisciplinas = !_expandidoDisciplinas;
                            });
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _expandidoDisciplinas
                                    ? 'Mostrar menos'
                                    : 'Ver todas (${_disciplinas.length})',
                                style: TextStyle(
                                  color: AppColors.azulClaro,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                _expandidoDisciplinas
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: AppColors.azulClaro,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildHeaderHistorico() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            color: _modoSelecao ? AppColors.azulClaro : Colors.green.shade600,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _modoSelecao
                      ? '${_mensagensSelecionadas.length} selecionada(s)'
                      : 'Histórico de Mensagens',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: _modoSelecao ? AppColors.azulClaro : Colors.black87,
                  ),
                ),
                if (_modoSelecao)
                  Text(
                    'Toque nas mensagens para selecionar',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                if (!_modoSelecao)
                  Text(
                    'Página $_paginaAtual de $_totalPaginas • ${_mensagensEnviadas.length} mensagens no total',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),

          if (!_modoSelecao && _mensagensEnviadas.isNotEmpty)
            IconButton(
              icon: Icon(Icons.select_all_rounded, color: AppColors.azulClaro),
              onPressed: _ativarModoSelecao,
              tooltip: 'Selecionar mensagens',
            ),

          if (_modoSelecao) ...[
            if (_mensagensSelecionadas.isNotEmpty)
              IconButton(
                icon: Icon(Icons.delete_rounded, color: Colors.red.shade600),
                onPressed: _excluirMensagensSelecionadas,
                tooltip: 'Excluir selecionadas',
              ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey),
              onPressed: _desativarModoSelecao,
              tooltip: 'Cancelar seleção',
            ),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.azulClaro.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.azulClaro),
              ),
              child: Text(
                _mensagensEnviadas.length.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.azulClaro,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListaMensagensEnviadas() {
    final mensagensDaPagina = _mensagensPaginaAtual;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderHistorico(),

          _mensagensEnviadas.isEmpty
              ? _buildEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Nenhuma mensagem enviada',
                  subtitle: 'As mensagens que você enviar aparecerão aqui',
                  height: 200,
                )
              : Column(
                  children: [
                    // Lista de mensagens da página atual
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mensagensDaPagina.length,
                      itemBuilder: (context, index) {
                        final mensagem = mensagensDaPagina[index];
                        return _buildItemMensagemEnviada(mensagem, index);
                      },
                    ),

                    // Paginação
                    if (_totalPaginas > 1) _buildPaginacao(),
                  ],
                ),
        ],
      ),
    );
  }

  // Widget de paginação
  Widget _buildPaginacao() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        color: Colors.grey.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Botão página anterior
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: _paginaAtual > 1
                ? () => _mudarPagina(_paginaAtual - 1)
                : null,
            tooltip: 'Página anterior',
          ),

          // Indicador de páginas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$_paginaAtual / $_totalPaginas',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // Botão próxima página
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _paginaAtual < _totalPaginas
                ? () => _mudarPagina(_paginaAtual + 1)
                : null,
            tooltip: 'Próxima página',
          ),
        ],
      ),
    );
  }

  Widget _buildBotoesAcoes(MensagemEnviada mensagem) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.edit_rounded, size: 18, color: Colors.blue.shade600),
          onPressed: () => _iniciarEdicao(mensagem),
          tooltip: 'Editar mensagem',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
        IconButton(
          icon: Icon(
            Icons.delete_rounded,
            size: 18,
            color: Colors.red.shade600,
          ),
          onPressed: () => _confirmarExclusao(mensagem),
          tooltip: 'Excluir mensagem',
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildEditorMensagem(MensagemEnviada mensagem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Editando mensagem',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.azulClaro,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _cancelarEdicao,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _salvarEdicao(mensagem.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulClaro,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  child: const Text(
                    'Salvar',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _editarMensagemController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Digite a nova mensagem...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.azulClaro),
            ),
          ),
        ),
      ],
    );
  }

  void _iniciarEdicao(MensagemEnviada mensagem) {
    setState(() {
      _mensagemEditandoId = mensagem.id;
      _editarMensagemController.text = mensagem.mensagem;
    });
  }

  void _cancelarEdicao() {
    setState(() {
      _mensagemEditandoId = null;
      _editarMensagemController.clear();
    });
  }

  Future<void> _salvarEdicao(String mensagemId) async {
    final novaMensagem = _editarMensagemController.text.trim();
    if (novaMensagem.isEmpty) {
      _mostrarSnackBar('Digite uma mensagem', tipo: SnackBarTipo.erro);
      return;
    }

    try {
      await MensagensProfessorService.editarMensagem(
        mensagemId: mensagemId,
        novaMensagem: novaMensagem,
      );
      _mostrarSnackBar(
        'Mensagem editada com sucesso!',
        tipo: SnackBarTipo.sucesso,
      );
      setState(() {
        _mensagemEditandoId = null;
        _editarMensagemController.clear();
      });
      await _carregarMensagensEnviadas();
    } catch (e) {
      _mostrarSnackBar('Erro ao editar mensagem: $e', tipo: SnackBarTipo.erro);
    }
  }

  void _confirmarExclusao(MensagemEnviada mensagem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Mensagem'),
        content: Text(
          'Tem certeza que deseja excluir esta mensagem?\n\n"${mensagem.mensagem}"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _excluirMensagem(mensagem.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  // CORREÇÃO: Excluir mensagem única - agora exclui todas as ocorrências
  Future<void> _excluirMensagem(String mensagemId) async {
    try {
      await MensagensProfessorService.excluirMensagemCompleta(mensagemId);
      _mostrarSnackBar(
        'Mensagem excluída com sucesso de todas as disciplinas!',
        tipo: SnackBarTipo.sucesso,
      );
      await _carregarMensagensEnviadas();
    } catch (e) {
      _mostrarSnackBar('Erro ao excluir mensagem: $e', tipo: SnackBarTipo.erro);
    }
  }

  // CORREÇÃO: Exclusão múltipla - agora exclui grupos completos de mensagens
  Future<void> _executarExclusaoMultipla() async {
    try {
      await MensagensProfessorService.excluirMultiplasMensagensCompletas(
        _mensagensSelecionadas.toList(),
      );

      _mostrarSnackBar(
        '${_mensagensSelecionadas.length} mensagem(ns) excluída(s) com sucesso de todas as disciplinas!',
        tipo: SnackBarTipo.sucesso,
      );

      _desativarModoSelecao();
      await _carregarMensagensEnviadas();
    } catch (e) {
      _mostrarSnackBar(
        'Erro ao excluir mensagens: $e',
        tipo: SnackBarTipo.erro,
      );
    }
  }

  // Helper para encontrar mensagem por ID
  MensagemEnviada? _encontrarMensagemPorId(String id) {
    try {
      return _mensagensEnviadas.firstWhere((mensagem) => mensagem.id == id);
    } catch (e) {
      return null;
    }
  }

  void _toggleSelecaoMensagem(String mensagemId) {
    setState(() {
      if (_mensagensSelecionadas.contains(mensagemId)) {
        _mensagensSelecionadas.remove(mensagemId);
      } else {
        _mensagensSelecionadas.add(mensagemId);
      }
      if (_mensagensSelecionadas.isEmpty) {
        _modoSelecao = false;
      }
    });
  }

  void _ativarModoSelecao() {
    setState(() {
      _modoSelecao = true;
      _mensagensSelecionadas.clear();
    });
  }

  void _desativarModoSelecao() {
    setState(() {
      _modoSelecao = false;
      _mensagensSelecionadas.clear();
    });
  }

  Future<void> _excluirMensagensSelecionadas() async {
    if (_mensagensSelecionadas.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Mensagens'),
        content: Text(
          'Tem certeza que deseja excluir ${_mensagensSelecionadas.length} mensagem(ns) selecionada(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executarExclusaoMultipla();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemMensagemEnviada(MensagemEnviada mensagem, int index) {
    final bool isSelecionada = _mensagensSelecionadas.contains(mensagem.id);
    final bool isEditando = _mensagemEditandoId == mensagem.id;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelecionada
            ? AppColors.azulClaro.withOpacity(0.2)
            : index.isEven
            ? Colors.grey.shade50
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelecionada ? AppColors.azulClaro : Colors.grey.shade100,
          width: isSelecionada ? 2 : 1,
        ),
      ),
      child: isEditando
          ? _buildEditorMensagem(mensagem)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (_modoSelecao)
                          Checkbox(
                            activeColor: AppColors.azulClaro,

                            value: isSelecionada,
                            onChanged: (value) =>
                                _toggleSelecaoMensagem(mensagem.id),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mensagem.data,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (!_modoSelecao) _buildBotoesAcoes(mensagem),
                    if (_modoSelecao && isSelecionada)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.azulClaro,
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  mensagem.mensagem,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                if (mensagem.disciplinas.isNotEmpty) ...[
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: mensagem.disciplinas
                        .map(
                          (disciplina) => Chip(
                            label: Text(
                              disciplina,
                              style: const TextStyle(fontSize: 11),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: AppColors.azulClaro.withOpacity(
                              0.1,
                            ),
                            side: BorderSide(
                              color: AppColors.azulClaro.withOpacity(0.3),
                            ),
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 0,
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    double height = 150,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulClaro),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Carregando...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Erro ao carregar',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Erro desconhecido',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.azulClaro,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Fundo da tela permanece cinza

      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildFormularioMensagem(),
                    _buildListaMensagensEnviadas(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

// Modelos auxiliares (permanecem iguais)
class DisciplinaCheckbox {
  final String id;
  final String nome;
  bool selecionada;

  DisciplinaCheckbox({
    required this.id,
    required this.nome,
    required this.selecionada,
  });
}

class MensagemEnviada {
  final String id;
  final String mensagem;
  final String data;
  final String? professorNome;
  final List<String> disciplinas;

  MensagemEnviada({
    required this.id,
    required this.mensagem,
    required this.data,
    this.professorNome,
    required this.disciplinas,
  });

  static List<String> _parseDisciplinasSimplificado(
    dynamic disciplinasDynamic,
  ) {
    if (disciplinasDynamic is List) {
      return disciplinasDynamic
          .map((d) {
            if (d is Map) {
              return d['titulo']?.toString() ??
                  d['nome']?.toString() ??
                  'Disciplina';
            }
            return 'Disciplina';
          })
          .where((d) => d != 'Disciplina')
          .toSet()
          .toList();
    }
    return [];
  }

  factory MensagemEnviada.fromJson(Map<String, dynamic> json) {
    String encontrarMensagem(Map<String, dynamic> json) {
      final camposMensagem = [
        'mensagem',
        'conteudo',
        'texto',
        'message',
        'msg',
        'content',
      ];
      for (final campo in camposMensagem) {
        final valor = json[campo]?.toString();
        if (valor != null && valor.isNotEmpty) return valor;
      }
      final disciplinas = _parseDisciplinasSimplificado(json['disciplinas']);
      if (disciplinas.isNotEmpty)
        return 'Mensagem para ${disciplinas.join(', ')}';
      return 'Mensagem sem conteúdo';
    }

    String formatarData(dynamic dataDynamic) {
      try {
        if (dataDynamic == null) return 'Data inválida';
        final dataString = dataDynamic.toString();
        if (dataString.contains('T') || dataString.contains('-')) {
          final date = DateTime.parse(dataString);
          return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
        }
        return dataString;
      } catch (e) {
        return 'Data inválida';
      }
    }

    List<String> parseDisciplinas(dynamic disciplinasDynamic) {
      return _parseDisciplinasSimplificado(disciplinasDynamic);
    }

    return MensagemEnviada(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      mensagem: encontrarMensagem(json),
      data: formatarData(
        json['dataCriacao'] ?? json['createdAt'] ?? json['data'],
      ),
      professorNome: json['professorNome']?.toString() ?? 'Professor',
      disciplinas: parseDisciplinas(json['disciplinas']),
    );
  }
}

enum SnackBarTipo { sucesso, erro, info }
