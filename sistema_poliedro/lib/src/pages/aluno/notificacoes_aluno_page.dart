import 'package:flutter/material.dart';

// Modelo para representar uma mensagem
class Mensagem {
  final String id;
  final String data;
  final String remetente;
  final String materia;
  final String conteudo;
  bool isUnread;
  bool isFavorita;
  bool isSelected;

  Mensagem({
    required this.id,
    required this.data,
    required this.remetente,
    required this.materia,
    required this.conteudo,
    this.isUnread = true,
    this.isFavorita = false,
    this.isSelected = false,
  });
}

// Um widget reutilizável para cada item da lista de notificações.
class NotificacaoItem extends StatefulWidget {
  final Mensagem mensagem;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorita;
  final ValueChanged<bool?> onSelect;

  const NotificacaoItem({
    super.key,
    required this.mensagem,
    required this.onTap,
    required this.onToggleFavorita,
    required this.onSelect,
  });

  @override
  State<NotificacaoItem> createState() => _NotificacaoItemState();
}

class _NotificacaoItemState extends State<NotificacaoItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: widget.mensagem.isUnread ? Colors.blue.shade50 : Colors.white,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox para seleção
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

            // Conteúdo principal da Notificação
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Data
                      Text(
                        widget.mensagem.data,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: widget.mensagem.isUnread ? FontWeight.bold : FontWeight.normal,
                          color: widget.mensagem.isUnread ? Colors.blue.shade800 : Colors.grey.shade600,
                        ),
                      ),
                      // Bolinha Azul de 'Não lida'
                      if (widget.mensagem.isUnread)
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
                  // Remetente
                  Text(
                    widget.mensagem.remetente,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Matéria
                  Text(
                    widget.mensagem.materia,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Preview da mensagem
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

            // Ícone de Estrela (Favoritar)
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
                'Não há mensagens selecionadas',
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
            // Cabeçalho da mensagem
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  mensagem!.remetente,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
            // Conteúdo da mensagem
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
  // Lista de todas as mensagens
  final List<Mensagem> _todasMensagens = [
    Mensagem(
      id: '1',
      data: '24 de setembro de 2025',
      remetente: 'Professor Luan Masael',
      materia: 'Geografia',
      conteudo: 'Prezado aluno, sua atividade sobre relevo brasileiro foi muito bem elaborada. Gostaria de marcar uma conversa para discutir possíveis melhorias e próximos passos. Aguardo seu retorno.',
    ),
    Mensagem(
      id: '2',
      data: '24 de setembro de 2025',
      remetente: 'Professor Luan Masael',
      materia: 'Geografia',
      conteudo: 'Lembrete: a prova sobre clima e vegetação será na próxima sexta-feira. Não se esqueça de revisar os materiais sobre biomas brasileiros.',
    ),
    Mensagem(
      id: '3',
      data: '23 de setembro de 2025',
      remetente: 'Coordenador João',
      materia: 'Avisos Gerais',
      conteudo: 'Reunião de pais e mestres será realizada no próximo sábado, das 8h às 12h. Contamos com a presença de todos para discutirmos o planejamento do próximo semestre.',
      isUnread: false,
    ),
    Mensagem(
      id: '4',
      data: '22 de setembro de 2025',
      remetente: 'Professora Maria',
      materia: 'Matemática',
      conteudo: 'Parabéns pelo excelente desempenho na última avaliação de álgebra. Sua dedicação aos estudos está rendendo frutos!',
      isUnread: false,
      isFavorita: true,
    ),
  ];

  // Filtros ativos
  String _filtroMateria = 'Todas as matérias';
  String _filtroStatus = 'Mensagens não lidas';
  String _termoBusca = '';

  // Mensagem selecionada
  Mensagem? _mensagemSelecionada;

  // Lista filtrada de mensagens
  List<Mensagem> get _mensagensFiltradas {
    return _todasMensagens.where((mensagem) {
      // Filtro por matéria
      final bool passaFiltroMateria = _filtroMateria == 'Todas as matérias' || 
          mensagem.materia == _filtroMateria;

      // Filtro por status
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

      // Filtro por busca
      final bool passaFiltroBusca = _termoBusca.isEmpty ||
          mensagem.remetente.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          mensagem.materia.toLowerCase().contains(_termoBusca.toLowerCase()) ||
          mensagem.conteudo.toLowerCase().contains(_termoBusca.toLowerCase());

      return passaFiltroMateria && passaFiltroStatus && passaFiltroBusca;
    }).toList();
  }

  void _selecionarMensagem(Mensagem mensagem) {
    setState(() {
      _mensagemSelecionada = mensagem;
      // Marcar como lida
      mensagem.isUnread = false;
    });
  }

  void _toggleFavorita(Mensagem mensagem) {
    setState(() {
      mensagem.isFavorita = !mensagem.isFavorita;
    });
  }

  void _toggleSelecionar(Mensagem mensagem, bool? selecionado) {
    setState(() {
      mensagem.isSelected = selecionado ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double notificationListWidth = 400.0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Dropdown 'Todas as matérias'
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  value: _filtroMateria,
                  items: ['Todas as matérias', 'Geografia', 'Matemática', 'Avisos Gerais']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _filtroMateria = newValue!;
                    });
                  },
                ),
              ),
            ),

            // Dropdown 'Mensagens não lidas'
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  value: _filtroStatus,
                  items: ['Mensagens não lidas', 'Todas as mensagens', 'Favoritas']
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _filtroStatus = newValue!;
                    });
                  },
                ),
              ),
            ),

            // Campo de busca
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: SizedBox(
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
              ),
            ),
          ],
        ),
      ),
      
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PAINEL ESQUERDO: Lista de Notificações
          SizedBox(
            width: notificationListWidth,
            child: _mensagensFiltradas.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma mensagem encontrada',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _mensagensFiltradas.length,
                    itemBuilder: (context, index) {
                      final mensagem = _mensagensFiltradas[index];
                      return NotificacaoItem(
                        mensagem: mensagem,
                        onTap: () => _selecionarMensagem(mensagem),
                        onToggleFavorita: () => _toggleFavorita(mensagem),
                        onSelect: (selecionado) => _toggleSelecionar(mensagem, selecionado),
                      );
                    },
                  ),
          ),
          
          // Divisor vertical
          Container(
            width: 1,
            color: Colors.grey.shade300,
          ),

          // PAINEL DIREITO: Visualização da Mensagem
          Expanded(
            child: VisualizadorMensagem(mensagem: _mensagemSelecionada),
          ),
        ],
      ),
    );
  }
}