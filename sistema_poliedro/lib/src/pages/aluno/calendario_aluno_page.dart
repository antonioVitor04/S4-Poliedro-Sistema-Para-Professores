import 'package:flutter/material.dart';
import '../../styles/fontes.dart';
import '../../services/card_disciplina_service.dart';
import '../../models/modelo_card_disciplina.dart';
import 'disciplina/visualizacao_material_page.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime mesAtual = DateTime.now();
  List<EventoCalendario> eventos = [];
  bool _isLoading = true;

  List<String> diasSemana = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
  List<String> meses = [
    'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
    'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
  ];

  @override
  void initState() {
    super.initState();
    _carregarEventos();
  }

  Future<void> _carregarEventos() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Buscar todas as disciplinas
      final cards = await CardDisciplinaService.getAllCards();
      
      // Extrair atividades com prazo
      final List<EventoCalendario> eventosEncontrados = [];
      
      for (final card in cards) {
        for (final topico in card.topicos) {
          for (final material in topico.materiais) {
            if (material.tipo == 'atividade' && material.prazo != null) {
              eventosEncontrados.add(EventoCalendario(
                material: material,
                topicoTitulo: topico.titulo,
                disciplinaTitulo: card.titulo,
                disciplinaSlug: card.slug,
                topicoId: topico.id,
              ));
            }
          }
        }
      }

      // Ordenar por data
      eventosEncontrados.sort((a, b) => a.material.prazo!.compareTo(b.material.prazo!));

      setState(() {
        eventos = eventosEncontrados;
        _isLoading = false;
      });

    } catch (e) {
      print('Erro ao carregar eventos: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _mesAnterior() {
    setState(() {
      mesAtual = DateTime(mesAtual.year, mesAtual.month - 1);
    });
  }

  void _proximoMes() {
    setState(() {
      mesAtual = DateTime(mesAtual.year, mesAtual.month + 1);
    });
  }

  List<DateTime?> _obterDiasDoMes() {
    final primeiroDia = DateTime(mesAtual.year, mesAtual.month, 1);
    final ultimoDia = DateTime(mesAtual.year, mesAtual.month + 1, 0);
    final diasNoMes = ultimoDia.day;
    final diaSemanaInicio = primeiroDia.weekday % 7;

    List<DateTime?> dias = [];

    for (int i = 0; i < diaSemanaInicio; i++) {
      dias.add(null);
    }

    for (int i = 1; i <= diasNoMes; i++) {
      dias.add(DateTime(mesAtual.year, mesAtual.month, i));
    }

    return dias;
  }

  List<EventoCalendario> _obterEventosDoDia(DateTime? dia) {
    if (dia == null) return [];
    return eventos.where((evento) {
      final dataEvento = evento.material.prazo!;
      return dataEvento.year == dia.year &&
          dataEvento.month == dia.month &&
          dataEvento.day == dia.day;
    }).toList();
  }

  Color _obterCorEvento(EventoCalendario evento) {
    final agora = DateTime.now();
    final prazo = evento.material.prazo!;
    
    if (prazo.isBefore(agora)) return Colors.red;
    
    final diferenca = prazo.difference(agora).inDays;
    if (diferenca < 7) return Colors.orange;
    if (diferenca < 14) return Colors.blue;
    return Colors.green;
  }

  String _formatarData(DateTime data) {
    final mesesAbreviados = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '${data.day} ${mesesAbreviados[data.month - 1]} às $hora:$minuto';
  }

  void _mostrarDetalhesEvento(EventoCalendario evento, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero, // Remove default padding to control fully
          content: Container(
            width: isMobile ? screenWidth * 0.95 : screenWidth * 0.6,
            height: isMobile ? screenHeight * 0.7 : screenHeight * 0.6,
            child: Column(
              children: [
                // Header with title and icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.assignment,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  evento.material.titulo,
                                  style: TextStyle(
                                    fontSize: isMobile ? 20 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  evento.disciplinaTitulo,
                                  style: TextStyle(
                                    fontSize: isMobile ? 14 : 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: isMobile ? 20 : 24,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Prazo: ${_formatarData(evento.material.prazo!)}',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (evento.material.descricao != null && evento.material.descricao!.isNotEmpty) ...[
                          const Text(
                            'Descrição:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            evento.material.descricao!,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (evento.material.peso != null && evento.material.peso! > 0) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.balance,
                                size: isMobile ? 20 : 24,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Peso: ${evento.material.peso!.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: isMobile ? 14 : 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        Text(
                          'Tópico: ${evento.topicoTitulo}',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            foregroundColor: Colors.grey[600],
                          ),
                          child: Text(
                            'Fechar',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VisualizacaoMaterialPage(
                                  material: evento.material,
                                  topicoTitulo: evento.topicoTitulo,
                                  topicoId: evento.topicoId,
                                  slug: evento.disciplinaSlug,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Abrir Atividade',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final dias = _obterDiasDoMes();

    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: isMobile ? 0 : 10),
                child: Text(
                  "Calendário",
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontSize: isMobile ? 22 : 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _mesAnterior,
                    icon: Icon(Icons.chevron_left, size: isMobile ? 24 : 28),
                  ),
                  Text(
                    '${meses[mesAtual.month - 1]} ${mesAtual.year}',
                    style: TextStyle(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _proximoMes,
                    icon: Icon(Icons.chevron_right, size: isMobile ? 24 : 28),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Legenda
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendaItem(Colors.red, 'Atrasadas'),
                _buildLegendaItem(Colors.orange, '< 1 semana'),
                _buildLegendaItem(Colors.blue, '< 2 semanas'),
                _buildLegendaItem(Colors.green, '> 2 semanas'),
              ],
            ),
          ),
          SizedBox(height: isMobile ? 16 : 20),

          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            // Grade do calendário
            Expanded(
              child: Column(
                children: [
                  // Cabeçalho dos dias da semana
                  Row(
                    children: diasSemana.map((dia) {
                      return Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12),
                          alignment: Alignment.center,
                          child: Text(
                            dia,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 10 : 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 1),

                  // Grade de dias
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: isMobile ? 1.1 : 1.0, // Slightly taller for mobile
                      ),
                      itemCount: dias.length,
                      itemBuilder: (context, index) {
                        final dia = dias[index];
                        if (dia == null) {
                          return Container();
                        }

                        final eventosDoDia = _obterEventosDoDia(dia);
                        final isHoje = dia.year == DateTime.now().year &&
                            dia.month == DateTime.now().month &&
                            dia.day == DateTime.now().day;

                        return Container(
                          margin: EdgeInsets.all(isMobile ? 1 : 2),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            color: isHoje ? Colors.blue[50] : Colors.white,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(isMobile ? 4 : 6),
                                child: Text(
                                  '${dia.day}',
                                  style: TextStyle(
                                    fontSize: isMobile ? 13 : 14,
                                    fontWeight: isHoje
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isHoje ? Colors.blue : Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile ? 2 : 4,
                                  ),
                                  itemCount: eventosDoDia.length,
                                  itemBuilder: (context, idx) {
                                    final evento = eventosDoDia[idx];
                                    final cor = _obterCorEvento(evento);
                                    final hora = evento.material.prazo!.hour;
                                    final minuto = evento.material.prazo!.minute;
                                    
                                    return GestureDetector(
                                      onTap: () => _mostrarDetalhesEvento(evento, context),
                                      child: Container(
                                        margin: EdgeInsets.only(bottom: isMobile ? 2 : 4),
                                        padding: EdgeInsets.all(isMobile ? 6 : 8),
                                        decoration: BoxDecoration(
                                          color: cor.withOpacity(0.2),
                                          border: Border.all(
                                            color: cor,
                                            width: 1,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.assignment,
                                                  color: cor,
                                                  size: isMobile ? 12 : 14,
                                                ),
                                                SizedBox(width: isMobile ? 4 : 6),
                                                Text(
                                                  '${hora.toString().padLeft(2, '0')}:${minuto.toString().padLeft(2, '0')}',
                                                  style: TextStyle(
                                                    fontSize: isMobile ? 10 : 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: cor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              evento.material.titulo,
                                              style: TextStyle(
                                                fontSize: isMobile ? 10 : 12,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[800],
                                              ),
                                              maxLines: isMobile ? 2 : 3,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(Color cor, String texto) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isMobile ? 10 : 12,
          height: isMobile ? 10 : 12,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.3),
            border: Border.all(color: cor, width: 2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: isMobile ? 4 : 6),
        Text(
          texto,
          style: TextStyle(fontSize: isMobile ? 9 : 10),
        ),
      ],
    );
  }
}

class EventoCalendario {
  final MaterialDisciplina material;
  final String topicoTitulo;
  final String disciplinaTitulo;
  final String disciplinaSlug;
  final String topicoId;

  EventoCalendario({
    required this.material,
    required this.topicoTitulo,
    required this.disciplinaTitulo,
    required this.disciplinaSlug,
    required this.topicoId,
  });
}