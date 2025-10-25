import 'package:flutter/material.dart';

// Modelo para representar uma mensagem
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../services/notificacoes_service.dart';
import '../../services/auth_service.dart';
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
    return Mensagem(
      id: json['_id'] ?? '',
      data: json['dataCriacao'] != null
          ? DateTime.parse(json['dataCriacao']).toString().substring(0, 10)
          : '',
      remetente: json['professor'] != null ? json['professor']['nome'] : 'Desconhecido',
      materia: json['disciplina'] != null ? json['disciplina']['titulo'] : '',
      conteudo: json['mensagem'] ?? '',
      disciplinaId: json['disciplina'] != null ? json['disciplina']['_id'] : '',
      isUnread: json['isUnread'] ?? true,
      isFavorita: json['isFavorita'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'dataCriacao': data,
      'professor': {'nome': remetente},
      'disciplina': {'_id': disciplinaId, 'titulo': materia},
      'mensagem': conteudo,
      'isUnread': isUnread,
      'isFavorita': isFavorita,
    };
  }
}
// Um widget reutilizável para cada item da lista de notificações.
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
    Color backgroundColor;
    if (widget.isSelectedMessage) {
      backgroundColor = Colors.blue.shade100;
    } else if (widget.mensagem.isUnread) {
      backgroundColor = Colors.blue.shade50;
    } else {
      backgroundColor = Colors.white;
    }

    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: widget.mensagem.isSelected,
                  onChanged: widget.onSelect,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.mensagem.data,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.mensagem.isUnread ? FontWeight.bold : FontWeight.normal,
                          color: widget.mensagem.isUnread ? Colors.blue.shade800 : Colors.grey.shade600,
                        ),
                      ),
                      if (widget.mensagem.isUnread && !widget.isSelectedMessage)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.mensagem.remetente,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.mensagem.materia,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.mensagem.conteudo.length > 100
                        ? '${widget.mensagem.conteudo.substring(0, 100)}...'
                        : widget.mensagem.conteudo,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.mensagem.isUnread ? Colors.black : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 8.0),
              child: IconButton(
                icon: Icon(
                  widget.mensagem.isFavorita ? Icons.star : Icons.star_border,
                  color: widget.mensagem.isFavorita ? Colors.amber : Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: widget.onToggleFavorita,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para exibir o conteúdo da mensagem
class VisualizadorMensagem extends StatelessWidget {
  final Mensagem? mensagem;

  const VisualizadorMensagem({super.key, this.mensagem});

  @override
  Widget build(BuildContext context) {
    if (mensagem == null) {
      return Container(
        color: const Color(0xFFFAFAFA),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mail_outline,
                size: 100,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhuma mensagem selecionada',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    mensagem!.remetente,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  mensagem!.data,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mensagem!.materia,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              mensagem!.conteudo,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget principal da página
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

  @override
  void initState() {
    super.initState();
    _loadData();
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
        _materiasDisponiveis = ['Todas as matérias', ...disciplinas.map((d) => d['titulo'] as String)];
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
      setState(() {
        _todasMensagens = notificacoes;
        _isLoading = false;
      });
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
        mensagem.isUnread = false;
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

  List<Mensagem> get _mensagensFiltradas {
    return _todasMensagens.where((mensagem) {
      final bool passaFiltroMateria = _filtroMateria == 'Todas as matérias' || mensagem.materia == _filtroMateria;
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
      final bool passaFiltroBusca = _termoBusca.isEmpty ||
          mensagem.remetente.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          mensagem.materia.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          mensagem.conteudo.toLowerCase().contains(_termoBusca.toLowerCase());

      return passaFiltroMateria && passaFiltroStatus && passaFiltroBusca;
    }).toList();
  }

  Widget _buildWideScreenLayout(BuildContext context) {
    const double notificationListWidth = 380.0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: notificationListWidth,
          child: _mensagensFiltradas.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nenhuma mensagem encontrada',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
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
        ),
        Container(
          width: 1,
          color: Colors.grey.shade300,
        ),
        Expanded(
          child: VisualizadorMensagem(mensagem: _mensagemSelecionada),
        ),
      ],
    );
  }

  Widget _buildNarrowScreenLayout(BuildContext context) {
    return _mensagensFiltradas.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Nenhuma mensagem encontrada',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
        : ListView.builder(
            itemCount: _mensagensFiltradas.length,
            itemBuilder: (context, index) {
              final mensagem = _mensagensFiltradas[index];
              return NotificacaoItem(
                mensagem: mensagem,
                isSelectedMessage: false,
                onTap: () async {
                  try {
                    await ApiService.markAsRead(mensagem.id);
                    setState(() {
                      mensagem.isUnread = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text(mensagem.materia, overflow: TextOverflow.ellipsis),
                          ),
                          body: VisualizadorMensagem(mensagem: mensagem),
                        ),
                      ),
                    );
                  } catch (e) {
                    setState(() {
                      _errorMessage = 'Erro ao marcar mensagem como lida: $e';
                    });
                  }
                },
                onToggleFavorita: () => _toggleFavorita(mensagem),
                onSelect: (selecionado) => _toggleSelecionar(mensagem, selecionado),
              );
            },
          );
  }

  PreferredSizeWidget _buildFilterControls(double screenWidth, bool isWideScreen) {
    final double preferredHeight = isWideScreen ? 60.0 : 100.0;
    final filterWidgets = [
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        value: _filtroMateria,
        items: _materiasDisponiveis
            .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: (String? newValue) {
          setState(() {
            _filtroMateria = newValue!;
          });
          _loadNotificacoes();
        },
      ),
      DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
        value: _filtroStatus,
        items: ['Mensagens não lidas', 'Todas as mensagens', 'Favoritas']
            .map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: (String? newValue) {
          setState(() {
            _filtroStatus = newValue!;
          });
        },
      ),
      SizedBox(
        height: 48,
        child: TextFormField(
          decoration: const InputDecoration(
            hintText: 'Procurar mensagens',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search, size: 20),
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
          ),
          onChanged: (value) {
            setState(() {
              _termoBusca = value;
            });
          },
        ),
      ),
    ];

    return PreferredSize(
      preferredSize: Size.fromHeight(preferredHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        child: isWideScreen
            ? Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: filterWidgets[0])),
                  Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: filterWidgets[1])),
                  Expanded(flex: 2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: filterWidgets[2])),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: filterWidgets[0],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: filterWidgets[1],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  filterWidgets[2],
                ],
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double screenWidth, bool isWideScreen) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 60,
      title: const Text('Notificações'),
      bottom: _buildFilterControls(screenWidth, isWideScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double breakpoint = 800.0;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= breakpoint;

    return Scaffold(
      appBar: _buildAppBar(screenWidth, isWideScreen),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : isWideScreen
                  ? _buildWideScreenLayout(context)
                  : _buildNarrowScreenLayout(context),
    );
  }
}
