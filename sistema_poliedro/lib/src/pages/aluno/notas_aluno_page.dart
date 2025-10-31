import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:sistema_poliedro/src/components/lista_disciplinas.dart';
import 'package:sistema_poliedro/src/services/calculadora_medias.dart';
import 'package:sistema_poliedro/src/services/notas_service.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';

class NotasPage extends StatefulWidget {
  final String token;

  const NotasPage({super.key, required this.token});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String searchText = "";
  List<Map<String, dynamic>> disciplinas = [];
  bool isLoading = true;
  String errorMessage = '';
  late NotasService notasService;

  // Estados para UX
  late TabController _tabController;
  VisualizacaoNotas _visualizacaoAtual = VisualizacaoNotas.lista;
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    notasService = NotasService(widget.token);

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    _scrollController.addListener(() {
      setState(() {
        _showScrollToTop = _scrollController.offset > 100;
      });
    });

    _carregarNotas();
  }

  void _handleTabSelection() {
    setState(() {
      _visualizacaoAtual = VisualizacaoNotas.values[_tabController.index];
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _carregarNotas() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final notasData = await notasService.getNotasAluno();

      final disciplinasProcessadas = notasData.map<Map<String, dynamic>>((
        nota,
      ) {
        return {
          "disciplina": nota['disciplina'] ?? 'Disciplina não informada',
          "disciplinaId": nota['disciplinaId'],
          "detalhes": (nota['detalhes'] as List).map<Map<String, dynamic>>((
            detalhe,
          ) {
            return {
              "nome": detalhe['nome'],
              "tipo": detalhe['tipo'],
              "nota": detalhe['nota']?.toDouble(),
              "peso": detalhe['peso']?.toDouble(),
            };
          }).toList(),
          "media": nota['media']?.toDouble() ?? 0.0,
        };
      }).toList();

      setState(() {
        disciplinas = CalculadoraMedias.processarDisciplinas(
          disciplinasProcessadas,
        );
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar notas: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              onPressed: _carregarNotas,
            ),
          ),
        );
      }
    }
  }

  double _calcularMediaPonderada(List<Map<String, dynamic>> avaliacoes) {
    if (avaliacoes.isEmpty) return 0.0;

    double somaPonderada = 0.0;
    double somaPesos = 0.0;

    for (final av in avaliacoes) {
      final nota = (av["nota"] as double?) ?? 0.0;
      final peso = (av["peso"] as double?) ?? 1.0;
      somaPonderada += nota * peso;
      somaPesos += peso;
    }

    return somaPesos > 0 ? somaPonderada / somaPesos : 0.0;
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.azulClaro),
          SizedBox(height: 16),
          Text(
            'Carregando suas notas...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
            const SizedBox(height: 24),
            Text(
              'Ops! Algo deu errado',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _carregarNotas,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulEscuro,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma nota encontrada',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Suas notas aparecerão aqui quando forem lançadas',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulEscuro,
              foregroundColor: Colors.white,
            ),
            onPressed: _carregarNotas,
            icon: const Icon(Icons.refresh),
            label: const Text('Recarregar'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final mediaGeral = disciplinas.isNotEmpty
        ? disciplinas.map((d) => d['media'] as double).reduce((a, b) => a + b) /
              disciplinas.length
        : 0.0;

    final acimaMedia = disciplinas
        .where((d) => (d['media'] as double) >= 6.0)
        .length;
    final abaixoMedia = disciplinas.length - acimaMedia;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Média Geral',
              mediaGeral.toStringAsFixed(1),
              Icons.school,
              AppColors.azulEscuro,
            ),
            _buildStatItem(
              'Acima da Média',
              acimaMedia.toString(),
              Icons.thumb_up,
              Colors.green,
            ),
            _buildStatItem(
              'Atenção',
              abaixoMedia.toString(),
              Icons.warning,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.azulEscuro, width: 3.0),
          ),
        ),
        labelColor: AppColors.azulEscuro,
        unselectedLabelColor: Colors.grey[600],
        tabs: const [
          Tab(icon: Icon(Icons.list_alt), text: 'Lista'),
          Tab(icon: Icon(Icons.bar_chart), text: 'Gráficos'),
        ],
      ),
    );
  }

  Widget _buildListView() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return RefreshIndicator(
      onRefresh: _carregarNotas,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: ListaDisciplinas(
          disciplinas: disciplinas,
          searchText: searchText,
          isNestedScroll: true, // Nova propriedade para ajustar o layout
        ),
      ),
    );
  }

  Widget _buildChartsView() {
    final disciplinasFiltradas = _filtrarDisciplinas();
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double horizontalPadding = isMobile ? 12.0 : 24.0;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 16,
      ),
      child: Column(
        children: [
          // Gráfico de barras - Médias por disciplina
          Container(
            width: double.infinity,
            height: isMobile ? 400 : 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.bar_chart,
                        size: 24,
                        color: AppColors.azulEscuro,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Médias por Disciplina',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Desempenho em cada disciplina',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SfCartesianChart(
                      plotAreaBackgroundColor: Colors.transparent,
                      primaryXAxis: CategoryAxis(
                        labelRotation: disciplinasFiltradas.length > 4
                            ? -45
                            : 0,
                        labelStyle: const TextStyle(fontSize: 12),
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        minimum: 0,
                        maximum: 10,
                        interval: 2,
                        labelStyle: const TextStyle(fontSize: 12),
                        majorGridLines: const MajorGridLines(
                          width: 1,
                          color: Colors.grey,
                        ),
                      ),
                      series: <CartesianSeries>[
                        ColumnSeries<Map<String, dynamic>, String>(
                          dataSource: disciplinasFiltradas,
                          xValueMapper: (disciplina, _) {
                            final nome = disciplina['disciplina'] as String;
                            if (isMobile && nome.length > 15) {
                              return '${nome.substring(0, 15)}...';
                            }
                            return nome;
                          },
                          yValueMapper: (disciplina, _) => disciplina['media'],
                          pointColorMapper: (disciplina, _) {
                            final media = disciplina['media'] as double;
                            return media >= 6.0 ? Colors.green : Colors.orange;
                          },
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelAlignment: ChartDataLabelAlignment.auto,
                            textStyle: TextStyle(fontSize: 12),
                          ),
                          animationDuration: 1000,
                          width: 0.6,
                        ),
                      ],
                      tooltipBehavior: TooltipBehavior(
                        enable: true,
                        header: 'Disciplina',
                        format: 'point.x : point.y',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Gráfico de pizza - Distribuição de status
          Container(
            width: double.infinity,
            height: isMobile ? 400 : 500,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.pie_chart,
                        size: 24,
                        color: AppColors.azulEscuro,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Distribuição de Desempenho',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visão geral do seu desempenho',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SfCircularChart(
                      palette: [Colors.green, Colors.orange],
                      legend: Legend(
                        isVisible: true,
                        position: isMobile
                            ? LegendPosition.bottom
                            : LegendPosition.right,
                        overflowMode: LegendItemOverflowMode.wrap,
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                      series: <CircularSeries>[
                        DoughnutSeries<_ChartData, String>(
                          dataSource: _preparePieChartData(
                            disciplinasFiltradas,
                          ),
                          xValueMapper: (_ChartData data, _) => data.label,
                          yValueMapper: (_ChartData data, _) => data.value,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            textStyle: TextStyle(fontSize: 12),
                          ),
                          animationDuration: 1000,
                          radius: isMobile ? '70%' : '80%',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<_ChartData> _preparePieChartData(
    List<Map<String, dynamic>> disciplinas,
  ) {
    final acimaMedia = disciplinas
        .where((d) => (d['media'] as double) >= 6.0)
        .length;
    final abaixoMedia = disciplinas.length - acimaMedia;

    return [
      _ChartData('Acima da Média\n($acimaMedia)', acimaMedia, Colors.green),
      _ChartData('Abaixo da Média\n($abaixoMedia)', abaixoMedia, Colors.orange),
    ];
  }

  List<Map<String, dynamic>> _filtrarDisciplinas() {
    if (searchText.isEmpty) return disciplinas;

    return disciplinas.where((disciplina) {
      return disciplina["disciplina"].toString().toLowerCase().contains(
        searchText.toLowerCase(),
      );
    }).toList();
  }

  Widget _buildSearchBar(bool isMobile) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600, minWidth: 300),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => searchText = value.toLowerCase()),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: "Pesquisar disciplina...",
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          suffixIcon: searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchText = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double padding = isMobile ? 12.0 : 24.0;

    return Scaffold(
      backgroundColor: AppColors.branco,
      body: SafeArea(
        child: isLoading
            ? Padding(
                padding: EdgeInsets.all(padding),
                child: _buildLoadingState(),
              )
            : errorMessage.isNotEmpty
            ? Padding(
                padding: EdgeInsets.all(padding),
                child: _buildErrorState(),
              )
            : disciplinas.isEmpty
            ? Padding(
                padding: EdgeInsets.all(padding),
                child: _buildEmptyState(),
              )
            : NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    // Sliver com header fixo (título e barra de pesquisa)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(padding),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(isMobile),
                            SizedBox(height: isMobile ? 12 : 20),
                            _buildSearchBar(isMobile),
                          ],
                        ),
                      ),
                    ),

                    // Sliver com indicadores e abas que rolam
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: padding,
                          vertical: 8,
                        ),
                        child: Column(
                          children: [
                            _buildQuickStats(),
                            const SizedBox(height: 16),
                            _buildTabBar(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  controller: _tabController,
                  children: [_buildListView(), _buildChartsView()],
                ),
              ),
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              child: const Icon(Icons.arrow_upward),
              mini: true,
              backgroundColor: AppColors.azulEscuro,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notas",
          style: TextStyle(
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (!isMobile) const SizedBox(height: 4),
        if (!isMobile)
          Text(
            "Acompanhe seu desempenho acadêmico",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        if (isMobile) ...[
          const SizedBox(height: 8),
          Text(
            "${disciplinas.length} disciplina${disciplinas.length != 1 ? 's' : ''}",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }
}

// Enums e classes auxiliares
enum VisualizacaoNotas { lista, graficos }

class _ChartData {
  final String label;
  final int value;
  final Color color;

  _ChartData(this.label, this.value, this.color);
}
