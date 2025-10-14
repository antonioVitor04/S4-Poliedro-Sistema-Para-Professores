// pages/disciplina/tasks_page.dart
import 'package:flutter/material.dart';
import '../../../services/card_disciplina_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../styles/cores.dart';
import 'visualizacao_material_professor.dart';

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
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 6 : 8),
      child: Material(
        borderRadius: BorderRadius.circular(8),
        color: _getTarefaColor(tarefa.prazo!),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 8 : 10,
          ),
          leading: Icon(
            Icons.assignment, 
            color: Colors.white, 
            size: isMobile ? 18 : 20
          ),
          title: Text(
            tarefa.titulo,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: isMobile ? 2 : 4),
              Text(
                '${tarefa.prazo!.day}/${tarefa.prazo!.month}/${tarefa.prazo!.year} às ${tarefa.prazo!.hour.toString().padLeft(2, '0')}:${tarefa.prazo!.minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: isMobile ? 11 : 12, 
                  color: Colors.white70
                ),
              ),
              if (tarefa.peso > 0)
                Text(
                  'Peso: ${tarefa.peso}%',
                  style: TextStyle(
                    fontSize: isMobile ? 10 : 11, 
                    color: Colors.white60
                  ),
                ),
            ],
          ),
          dense: isMobile,
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 12 : 16, 
        isMobile ? 16 : 20, 
        isMobile ? 12 : 16, 
        isMobile ? 6 : 8
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: isMobile ? 16 : 18,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildEmptySection(String title) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Padding(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.assignment_turned_in, 
              size: isMobile ? 40 : 48, 
              color: Colors.grey[400]
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              'Nenhuma $title',
              style: TextStyle(
                color: Colors.grey,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Tarefas',
          style: TextStyle(
            color: Colors.black,
            fontSize: isMobile ? 18 : 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<CardDisciplina>(
        future: _futureCard,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulClaro),
              ),
            );
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline, 
                    size: isMobile ? 48 : 64, 
                    color: Colors.red
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    'Erro ao carregar tarefas', 
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: isMobile ? 16 : 18,
                    )
                  ),
                  SizedBox(height: isMobile ? 16 : 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureCard = CardDisciplinaService.getCardBySlug(widget.slug);
                      });
                    },
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
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
          final pendentes = allTarefas.where((record) => 
            record.material.prazo!.isAfter(now) || 
            record.material.prazo!.isAtSameMomentAs(now)
          ).toList();
          final passadas = allTarefas.where((record) => 
            record.material.prazo!.isBefore(now)
          ).toList();

          pendentes.sort((a, b) => a.material.prazo!.compareTo(b.material.prazo!));
          passadas.sort((a, b) => b.material.prazo!.compareTo(a.material.prazo!));

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: SizedBox(height: isMobile ? 12 : 20)),
              SliverToBoxAdapter(
                child: pendentes.isEmpty
                    ? _buildEmptySection('tarefa pendente')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Tarefas Pendentes'),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              isMobile ? 12 : 16, 
                              0, 
                              isMobile ? 12 : 16, 
                              isMobile ? 8 : 12
                            ),
                            child: Text(
                              'Tarefas com prazo futuro ou atual',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          ...pendentes.map((record) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16
                                ),
                                child: _buildTarefaItem(record.material, record.topicoId),
                              )),
                          SizedBox(height: isMobile ? 16 : 20),
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
                            padding: EdgeInsets.fromLTRB(
                              isMobile ? 12 : 16, 
                              0, 
                              isMobile ? 12 : 16, 
                              isMobile ? 8 : 12
                            ),
                            child: Text(
                              'Tarefas vencidas',
                              style: TextStyle(
                                fontSize: isMobile ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          ...passadas.map((record) => Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 16
                                ),
                                child: _buildTarefaItem(record.material, record.topicoId),
                              )),
                          SizedBox(height: isMobile ? 16 : 20),
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