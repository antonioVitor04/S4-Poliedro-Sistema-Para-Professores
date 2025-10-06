import 'package:flutter/material.dart';
import '../../styles/fontes.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({super.key});

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime mesAtual = DateTime.now();
  List<Evento> eventos = [
    Evento(
      titulo: "Atividade 4 - Labora...",
      data: DateTime(2024, 10, 2, 11, 10),
    ),
    Evento(
      titulo: "Atividade 4 - Labora...",
      data: DateTime(2024, 10, 2, 13, 0),
    ),
    Evento(
      titulo: "Atividade 4 - Labora...",
      data: DateTime(2024, 10, 30, 13, 0),
    ),
  ];

  List<String> diasSemana = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];
  List<String> meses = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];

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

  List<Evento> _obterEventosDoDia(DateTime? dia) {
    if (dia == null) return [];
    return eventos.where((evento) {
      return evento.data.year == dia.year &&
          evento.data.month == dia.month &&
          evento.data.day == dia.day;
    }).toList();
  }

  Color _obterCorEvento(Evento evento) {
    final diasRestantes = evento.diasRestantes;
    if (diasRestantes < 7) return Colors.red;
    if (diasRestantes < 14) return Colors.orange;
    return Colors.blue;
  }

  void _adicionarEvento(DateTime dia) {
    showDialog(
      context: context,
      builder: (context) {
        String titulo = '';
        TimeOfDay horario = TimeOfDay.now();

        return AlertDialog(
          title: Text('Novo Evento - ${dia.day}/${dia.month}/${dia.year}'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Título do Evento',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => titulo = value,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Horário'),
                    subtitle: Text(
                      '${horario.hour}:${horario.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final hora = await showTimePicker(
                        context: context,
                        initialTime: horario,
                      );
                      if (hora != null) {
                        setStateDialog(() {
                          horario = hora;
                        });
                      }
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titulo.isNotEmpty) {
                  setState(() {
                    eventos.add(
                      Evento(
                        titulo: titulo,
                        data: DateTime(
                          dia.year,
                          dia.month,
                          dia.day,
                          horario.hour,
                          horario.minute,
                        ),
                      ),
                    );
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dias = _obterDiasDoMes();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  "Calendário",
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _mesAnterior,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${meses[mesAtual.month - 1]} ${mesAtual.year}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: _proximoMes,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Legenda
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendaItem(Colors.red, '< 1 semana'),
                _buildLegendaItem(Colors.orange, '< 2 semanas'),
                _buildLegendaItem(Colors.blue, '> 1 mês'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Grade do calendário
          Expanded(
            child: Column(
              children: [
                // Cabeçalho dos dias da semana
                Row(
                  children: diasSemana.map((dia) {
                    return Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        child: Text(
                          dia,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: dias.length,
                    itemBuilder: (context, index) {
                      final dia = dias[index];
                      if (dia == null) {
                        return Container();
                      }

                      final eventosDoDia = _obterEventosDoDia(dia);
                      final isHoje =
                          dia.year == DateTime.now().year &&
                          dia.month == DateTime.now().month &&
                          dia.day == DateTime.now().day;

                      return GestureDetector(
                        onTap: () => _adicionarEvento(dia),
                        child: Container(
                          margin: const EdgeInsets.all(2),
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
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  '${dia.day}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isHoje
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isHoje ? Colors.blue : Colors.black,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  itemCount: eventosDoDia.length,
                                  itemBuilder: (context, idx) {
                                    final evento = eventosDoDia[idx];
                                    final cor = _obterCorEvento(evento);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 2),
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: cor.withOpacity(0.2),
                                        border: Border.all(
                                          color: cor,
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${evento.data.hour}:${evento.data.minute.toString().padLeft(2, '0')} ${evento.titulo}',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  },
                                ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLegendaItem(Color cor, String texto) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.3),
            border: Border.all(color: cor, width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class Evento {
  final String titulo;
  final DateTime data;

  Evento({required this.titulo, required this.data});

  int get diasRestantes {
    final diferenca = data.difference(DateTime.now()).inDays;
    return diferenca;
  }
}
