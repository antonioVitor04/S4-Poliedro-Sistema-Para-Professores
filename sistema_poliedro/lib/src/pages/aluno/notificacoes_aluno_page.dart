import 'package:flutter/material.dart';

// Modelo para representar uma mensagem
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import '../../services/notificacoes_service.dart';
import '../../services/auth_service.dart';

/// ====== NOVO: contador global reativo para a Navbar exibir o badge ======
/// Em sua Navbar, use:
/// ValueListenableBuilder<int>(
///   valueListenable: notificationsUnreadCount,
///   builder: (_, count, __) => IconWithBadge(count: count),
/// )
final ValueNotifier<int> notificationsUnreadCount = ValueNotifier<int>(0);

class Mensagem {
  final String id;
  final String data;
  final String remetente;
  final String materia;
  final String conteudo;
  final String disciplinaId;
  bool isUnread;
  bool isFavorita;
  bool isSelected;

  Mensagem({
    required this.id,
    required this.data,
    required this.remetente,
    required this.materia,
    required this.conteudo,
    required this.disciplinaId,
    this.isUnread = true,
    this.isFavorita = false,
    this.isSelected = false,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    // Tratamento seguro para disciplina
    String materia = '';
    String disciplinaId = '';

    if (json['disciplina'] != null) {
      if (json['disciplina'] is String) {
        disciplinaId = json['disciplina'];
        materia = 'Disciplina';
      } else if (json['disciplina'] is Map) {
        final disciplina = json['disciplina'] as Map<String, dynamic>;
        disciplinaId = disciplina['_id']?.toString() ?? '';
        materia =
            disciplina['titulo']?.toString() ??
            disciplina['nome']?.toString() ??
            'Disciplina';
      }
    }

    // Tratamento seguro para professor
    String remetente = 'Professor';
    if (json['professor'] != null) {
      if (json['professor'] is String) {
        remetente = 'Professor';
      } else if (json['professor'] is Map) {
        final professor = json['professor'] as Map<String, dynamic>;
        remetente = professor['nome']?.toString() ?? 'Professor';
      }
    }

    // Tratamento seguro para data
    String data = '';
    if (json['dataCriacao'] != null) {
      try {
        data = DateTime.parse(
          json['dataCriacao'].toString(),
        ).toString().substring(0, 10);
      } catch (e) {
        data = 'Data inválida';
      }
    }

    return Mensagem(
      id: json['_id']?.toString() ?? '',
      data: data,
      remetente: remetente,
      materia: materia,
      conteudo: json['mensagem']?.toString() ?? '',
      disciplinaId: disciplinaId,
      isUnread: json['lida'] == false,
      isFavorita: json['favorita'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'dataCriacao': data,
      'professor': {'nome': remetente},
      'disciplina': {'_id': disciplinaId, 'titulo': materia},
      'mensagem': conteudo,
      'lida': !isUnread,
      'favorita': isFavorita,
    };
  }
}

class NotificacaoItem extends StatefulWidget {
  final Mensagem mensagem;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorita;
  final ValueChanged<bool?> onSelect;
  final bool isSelectedMessage;

  const NotificacaoItem({
    super.key,
    required this.mensagem,
    required this.onTap,
    required this.onToggleFavorita,
    required this.onSelect,
    this.isSelectedMessage = false,
  });

  @override
  State<NotificacaoItem> createState() => _NotificacaoItemState();
}

class _NotificacaoItemState extends State<NotificacaoItem> {
  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.isSelectedMessage;
    final bool isUnread = widget.mensagem.isUnread;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: isSelected ? 2 : 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox de seleção
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: widget.mensagem.isSelected,
                    onChanged: widget.onSelect,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              // Conteúdo da mensagem
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header com data e status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.mensagem.data,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isUnread
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (isUnread && !isSelected)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'NOVA',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Remetente
                    Text(
                      widget.mensagem.remetente,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // Matéria
                    Text(
                      widget.mensagem.materia,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Conteúdo
                    Text(
                      widget.mensagem.conteudo.length > 120
                          ? '${widget.mensagem.conteudo.substring(0, 120)}...'
                          : widget.mensagem.conteudo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Botão favorito
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: Icon(
                    widget.mensagem.isFavorita
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: widget.mensagem.isFavorita
                        ? Colors.amber.shade600
                        : Colors.grey.shade400,
                    size: 24,
                  ),
                  onPressed: widget.onToggleFavorita,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VisualizadorMensagem extends StatelessWidget {
  final Mensagem? mensagem;

  const VisualizadorMensagem({super.key, this.mensagem});

  @override
  Widget build(BuildContext context) {
    if (mensagem == null) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Selecione uma mensagem',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha uma notificação para visualizar',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      mensagem!.remetente.isNotEmpty
                          ? mensagem!.remetente[0].toUpperCase()
                          : 'P',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mensagem!.remetente,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          mensagem!.materia,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    mensagem!.data,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Conteúdo
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                mensagem!.conteudo,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage> {
  List<Mensagem> _todasMensagens = [];
  List<String> _materiasDisponiveis = ['Todas as matérias'];
  List<String> _disciplinasIds = [];
  String _filtroMateria = 'Todas as matérias';
  String _filtroStatus = 'Mensagens não lidas';
  String _termoBusca = '';
  Mensagem? _mensagemSelecionada;
  bool _isLoading = true;
  String? _errorMessage;

  // ====== NOVO: para comparar e disparar popup quando chegarem novas ======
  int _lastUnread = 0;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _lastUnread = notificationsUnreadCount.value;
    _loadData();
  }

  @override
  void dispose() {
    _removeOverlay();
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
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      ApiService.setToken(token);

      final disciplinas = await ApiService.fetchDisciplinas();
      setState(() {
        _materiasDisponiveis = [
          'Todas as matérias',
          ...disciplinas.map((d) => d['titulo'] as String),
        ];
        _disciplinasIds = disciplinas.map((d) => d['_id'] as String).toList();
      });

      await _loadNotificacoes();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotificacoes() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final disciplinaId = _filtroMateria != 'Todas as matérias'
          ? _disciplinasIds[_materiasDisponiveis.indexOf(_filtroMateria) - 1]
          : null;

      final notificacoes = await ApiService.fetchNotificacoes(disciplinaId);

      // ====== NOVO: calcula não lidas, atualiza global e dispara popup se aumentou
      final int newUnread = notificacoes.where((m) => m.isUnread).length;

      setState(() {
        _todasMensagens = notificacoes;
        _isLoading = false;
      });

      if (newUnread > notificationsUnreadCount.value) {
        _showNewNotificationPopup(newUnread);
        // SnackBar removido
      }

      notificationsUnreadCount.value = newUnread;
      _lastUnread = newUnread;
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selecionarMensagem(Mensagem mensagem) async {
    try {
      await ApiService.markAsRead(mensagem.id);
      setState(() {
        _mensagemSelecionada = mensagem;
        if (mensagem.isUnread) {
          mensagem.isUnread = false;
          // ====== NOVO: decrementa contador global
          notificationsUnreadCount.value =
              (notificationsUnreadCount.value - 1).clamp(0, 999);
          _lastUnread = notificationsUnreadCount.value;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao marcar mensagem como lida: $e';
      });
    }
  }

  void _toggleFavorita(Mensagem mensagem) async {
    try {
      await ApiService.toggleFavorita(mensagem.id, !mensagem.isFavorita);
      setState(() {
        mensagem.isFavorita = !mensagem.isFavorita;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao atualizar favorita: $e';
      });
    }
  }

  void _toggleSelecionar(Mensagem mensagem, bool? selecionado) {
    setState(() {
      mensagem.isSelected = selecionado ?? false;
    });
  }

  // ====== Popup leve (Overlay) no canto superior direito ======
  void _showNewNotificationPopup(int unread) {
    _removeOverlay();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final media = MediaQuery.of(context);
        final padding = media.padding;
        return Positioned(
          right: 16,
          top: padding.top + 12,
          child: Material(
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(milliseconds: 150),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      unread == 1
                          ? '1 nova notificação'
                          : '$unread novas notificações',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);

    // some depois de 1.8s
    Future.delayed(const Duration(milliseconds: 1800), _removeOverlay);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // SnackBar removido 👇
  // void _showSnack(String msg) { ... }

  List<Mensagem> get _mensagensFiltradas {
    return _todasMensagens.where((mensagem) {
      final bool passaFiltroMateria =
          _filtroMateria == 'Todas as matérias' ||
          mensagem.materia == _filtroMateria;
      bool passaFiltroStatus = true;
      switch (_filtroStatus) {
        case 'Mensagens não lidas':
          passaFiltroStatus = mensagem.isUnread;
          break;
        case 'Favoritas':
          passaFiltroStatus = mensagem.isFavorita;
          break;
        case 'Todas as mensagens':
          passaFiltroStatus = true;
          break;
      }
      final bool passaFiltroBusca =
          _termoBusca.isEmpty ||
          mensagem.remetente.toLowerCase().contains(
            _termoBusca.toLowerCase(),
          ) ||
          mensagem.materia.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          mensagem.conteudo.toLowerCase().contains(_termoBusca.toLowerCase());

      return passaFiltroMateria && passaFiltroStatus && passaFiltroBusca;
    }).toList();
  }

  Widget _buildWideScreenLayout(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lista de mensagens
          Container(
            width: 400,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade200)),
            ),
            child: _buildMessageList(),
          ),

          // Visualizador de mensagem
          Expanded(child: VisualizadorMensagem(mensagem: _mensagemSelecionada)),
        ],
      ),
    );
  }

  Widget _buildNarrowScreenLayout(BuildContext context) {
    return _buildMessageList();
  }

  Widget _buildMessageList() {
    if (_mensagensFiltradas.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma mensagem encontrada',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Tente ajustar os filtros ou termos de busca',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: ListView.builder(
        itemCount: _mensagensFiltradas.length,
        itemBuilder: (context, index) {
          final mensagem = _mensagensFiltradas[index];
          return NotificacaoItem(
            mensagem: mensagem,
            isSelectedMessage: mensagem.id == _mensagemSelecionada?.id,
            onTap: () => _selecionarMensagem(mensagem),
            onToggleFavorita: () => _toggleFavorita(mensagem),
            onSelect: (selecionado) => _toggleSelecionar(mensagem, selecionado),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 50, // Altura fixa para melhor alinhamento
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextFormField(
        cursorColor: AppColors.azulClaro,
        decoration: InputDecoration(
          hintText: 'Pesquisar mensagens...',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade500),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16, // Aumentado para centralizar verticalmente
            horizontal: 16,
          ),
          alignLabelWithHint: true,
        ),
        onChanged: (value) {
          setState(() {
            _termoBusca = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Container(
      height: 50, // Altura fixa igual ao search field
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        style: TextStyle(color: Colors.grey.shade800, fontSize: 14),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12),
        icon: Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade600),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12, // Ajustado para centralizar melhor
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade500),
          alignLabelWithHint: true,
        ),
        isExpanded: true,
      ),
    );
  }

  Widget _buildHeaderSection(double screenWidth, bool isWideScreen) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'Notificações',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),

          // Filtros
          isWideScreen
              ? Row(
                  children: [
                    Expanded(flex: 2, child: _buildSearchField()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _filtroMateria,
                        items: _materiasDisponiveis,
                        onChanged: (String? newValue) {
                          setState(() {
                            _filtroMateria = newValue!;
                          });
                          _loadNotificacoes();
                        },
                        hint: 'Matéria',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildFilterDropdown(
                        value: _filtroStatus,
                        items: [
                          'Mensagens não lidas',
                          'Todas as mensagens',
                          'Favoritas',
                        ],
                        onChanged: (String? newValue) {
                          setState(() {
                            _filtroStatus = newValue!;
                          });
                        },
                        hint: 'Status',
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildFilterDropdown(
                            value: _filtroMateria,
                            items: _materiasDisponiveis,
                            onChanged: (String? newValue) {
                              setState(() {
                                _filtroMateria = newValue!;
                              });
                              _loadNotificacoes();
                            },
                            hint: 'Matéria',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildFilterDropdown(
                            value: _filtroStatus,
                            items: [
                              'Mensagens não lidas',
                              'Todas as mensagens',
                              'Favoritas',
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _filtroStatus = newValue!;
                              });
                            },
                            hint: 'Status',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double breakpoint = 800.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= breakpoint;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header com filtros
          _buildHeaderSection(screenWidth, isWideScreen),

          // Conteúdo principal
          Expanded(
            child: _isLoading
                ? Container(
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Carregando notificações...',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : _errorMessage != null
                    ? Container(
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Erro ao carregar notificações',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32),
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadData,
                                child: const Text('Tentar novamente'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : isWideScreen
                        ? _buildWideScreenLayout(context)
                        : _buildNarrowScreenLayout(context),
          ),
        ],
      ),
    );
  }
}
