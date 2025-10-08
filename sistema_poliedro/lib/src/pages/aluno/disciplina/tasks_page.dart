// pages/disciplina/tasks_page.dart
import 'package:flutter/material.dart';
import '../../../services/card_disciplina_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../styles/cores.dart';
import 'visualizacao_material_page.dart';

class TasksPage extends StatefulWidget {
  final String slug;

  const TasksPage({
    super.key,
    required this.slug,
  });

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  late Future<CardDisciplina> _futureCard;

  @override
  void initState() {
    super.initState();
    _futureCard = CardDisciplinaService.getCardBySlug(widget.slug);
  }

  Color _getTarefaColor(DateTime prazo) {
    final now = DateTime.now();
    if (prazo.isBefore(now)) return Colors.red;
    return AppColors.azulClaro;
  }

  Widget _buildTarefaItem(MaterialDisciplina tarefa, String topicoId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        color: _getTarefaColor(tarefa.prazo!),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading: Icon(Icons.assignment, color: Colors.white, size: 20),
          title: Text(
            tarefa.titulo,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                '${tarefa.prazo!.day}/${tarefa.prazo!.month}/${tarefa.prazo!.year} às ${tarefa.prazo!.hour.toString().padLeft(2, '0')}:${tarefa.prazo!.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
              if (tarefa.peso > 0)
                Text(
                  'Peso: ${tarefa.peso}%',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
            ],
          ),
          dense: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VisualizacaoMaterialPage(
                  material: tarefa,
                  topicoTitulo: 'Tarefa',
                  topicoId: topicoId,
                  slug: widget.slug,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildEmptySection(String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Nenhuma $title',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 16,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tarefas',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<CardDisciplina>(
        future: _futureCard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulClaro),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Erro ao carregar tarefas', style: TextStyle(color: Colors.black)),
            );
          }

          final card = snapshot.data!;
          final allTarefas = <({MaterialDisciplina material, String topicoId})>[];
          for (final topico in card.topicos) {
            for (final material in topico.materiais) {
              if (material.prazo != null) {
                allTarefas.add((material: material, topicoId: topico.id));
              }
            }
          }

          final now = DateTime.now();
          final pendentes = allTarefas.where((record) => record.material.prazo!.isAfter(now) || record.material.prazo!.isAtSameMomentAs(now)).toList();
          final passadas = allTarefas.where((record) => record.material.prazo!.isBefore(now)).toList();

          pendentes.sort((a, b) => a.material.prazo!.compareTo(b.material.prazo!));
          passadas.sort((a, b) => b.material.prazo!.compareTo(a.material.prazo!));

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: pendentes.isEmpty
                    ? _buildEmptySection('tarefa pendente')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Tarefas Pendentes'),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              'Tarefas com prazo futuro ou atual',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          ...pendentes.map((record) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildTarefaItem(record.material, record.topicoId),
                              )),
                        ],
                      ),
              ),
              SliverToBoxAdapter(
                child: passadas.isEmpty
                    ? _buildEmptySection('tarefa passada')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Tarefas Passadas'),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              'Tarefas vencidas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          ...passadas.map((record) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: _buildTarefaItem(record.material, record.topicoId),
                              )),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}