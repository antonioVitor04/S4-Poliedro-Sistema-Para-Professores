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
  final ScrollController _scrollController = ScrollController();
  List<MensagemEnviada> _mensagensEnviadas = [];
  bool _isLoading = true;
  bool _enviandoMensagem = false;
  String? _errorMessage;
  String? _nomeProfessor;
  bool _expandidoDisciplinas = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mensagemController.dispose();
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
      });
    } catch (e) {
      print('Erro ao carregar mensagens enviadas: $e');
      setState(() {
        _mensagensEnviadas = [];
        _isLoading = false;
      });
    }
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Notificações',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      backgroundColor: Colors.white,
      elevation: 0.5,
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh_rounded,
            color: _isLoading ? Colors.grey : AppColors.azulClaro,
          ),
          onPressed: _isLoading ? null : _loadData,
          tooltip: 'Recarregar',
        ),
        const SizedBox(width: 8),
      ],
    );
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

                    // Seção de disciplinas
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
                                  Icon(Icons.send_rounded, size: 20),
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

        // Lista de disciplinas responsiva
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final maxHeight = isMobile ? 150.0 : 200.0;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _expandidoDisciplinas ? null : maxHeight,
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
                    )
                  : Column(
                      children: [
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
                                value: disciplina.selecionada,
                                onChanged: (value) => _toggleDisciplina(index),
                                dense: true,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
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
                                  _expandidoDisciplinas =
                                      !_expandidoDisciplinas;
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _expandidoDisciplinas
                                        ? 'Mostrar menos'
                                        : 'Mostrar todas',
                                    style: TextStyle(
                                      color: AppColors.azulClaro,
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildListaMensagensEnviadas() {
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
          // Header do histórico
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
                  Icons.history_rounded,
                  color: Colors.green.shade600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Histórico de Mensagens',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
          ),

          // Lista de mensagens
          _mensagensEnviadas.isEmpty
              ? _buildEmptyState(
                  icon: Icons.history_toggle_off_rounded,
                  title: 'Nenhuma mensagem enviada',
                  subtitle: 'As mensagens que você enviar aparecerão aqui',
                  height: 200,
                )
              : Padding(
                  padding: const EdgeInsets.all(4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _mensagensEnviadas.length,
                    itemBuilder: (context, index) {
                      final mensagem = _mensagensEnviadas[index];
                      return _buildItemMensagemEnviada(mensagem, index);
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildItemMensagemEnviada(MensagemEnviada mensagem, int index) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: index.isEven ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header com data e informações
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
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
              FutureBuilder<bool>(
                future: AuthService.isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.data == true && mensagem.professorNome != null) {
                    return Row(
                      children: [
                        Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mensagem.professorNome!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mensagem
          Text(
            mensagem.mensagem,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Disciplinas
          if (mensagem.disciplinas.isNotEmpty) ...[
            const Divider(height: 1),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: mensagem.disciplinas.map((disciplina) {
                return Chip(
                  label: Text(disciplina, style: const TextStyle(fontSize: 11)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: AppColors.azulClaro.withOpacity(0.1),
                  side: BorderSide(color: AppColors.azulClaro.withOpacity(0.3)),
                  labelPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 0,
                  ),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
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
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              color: AppColors.azulClaro,
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

// Modelos auxiliares
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

  // CORREÇÃO: Mover a função auxiliar para o topo
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
        if (valor != null && valor.isNotEmpty) {
          return valor;
        }
      }

      // CORREÇÃO: Agora a função já está declarada
      final disciplinas = _parseDisciplinasSimplificado(json['disciplinas']);
      if (disciplinas.isNotEmpty) {
        return 'Mensagem para ${disciplinas.join(', ')}';
      }

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
