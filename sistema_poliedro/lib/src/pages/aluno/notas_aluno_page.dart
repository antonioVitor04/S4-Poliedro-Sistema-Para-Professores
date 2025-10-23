import 'package:flutter/material.dart';
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

class _NotasPageState extends State<NotasPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = "";
  List<Map<String, dynamic>> disciplinas = [];
  bool isLoading = true;
  String errorMessage = '';
  late NotasService notasService;

  @override
  void initState() {
    super.initState();
    notasService = NotasService(widget.token);
    _carregarNotas();
  }

  Future<void> _carregarNotas() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final notasData = await notasService.getNotasAluno();

      // Converter os dados da API para o formato esperado pelo componente
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

      // Mostrar snackbar de erro
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar notas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _atualizarNota(
    String disciplinaId,
    List<Map<String, dynamic>> novosDetalhes,
  ) async {
    try {
      // Encontrar a nota correspondente
      final nota = disciplinas.firstWhere(
        (d) => d['disciplinaId'] == disciplinaId,
        orElse: () => {},
      );

      if (nota.isNotEmpty && nota['_id'] != null) {
        await notasService.atualizarNota(nota['_id'], {
          'avaliacoes': novosDetalhes
              .map(
                (detalhe) => {
                  'tipo': detalhe['tipo'],
                  'nota': detalhe['nota'],
                  'peso': detalhe['peso'],
                },
              )
              .toList(),
        });

        // Recarregar as notas
        await _carregarNotas();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notas atualizadas com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar notas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 600;
            final double padding = isMobile ? 12.0 : 24.0;

            return Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// CABEÇALHO RESPONSIVO
                  _buildHeader(isMobile),
                  SizedBox(height: isMobile ? 12 : 20),

                  if (isLoading) ...[
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ] else if (errorMessage.isNotEmpty) ...[
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar notas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32.0,
                              ),
                              child: Text(
                                errorMessage,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _carregarNotas,
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    /// BARRA DE PESQUISA RESPONSIVA
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 600,
                        minWidth: 300,
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => searchText = value.toLowerCase());
                        },
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: "Pesquisar disciplina...",
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    /// LEGENDA RESPONSIVA
                    _buildLegend(isMobile),
                    SizedBox(height: isMobile ? 12 : 16),

                    /// LISTA DE DISCIPLINAS
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _carregarNotas,
                        child: ListaDisciplinas(
                          disciplinas: disciplinas,
                          searchText: searchText,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: isLoading
          ? null
          : FloatingActionButton(
              onPressed: _carregarNotas,
              child: const Icon(Icons.refresh),
              mini: true,
            ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Notas",
          style: TextStyle(
            fontSize: isMobile ? 22 : 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        if (!isMobile) const SizedBox(height: 4),
        if (!isMobile)
          Text(
            "Acompanhe seu desempenho acadêmico",
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        if (isMobile && disciplinas.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            "${disciplinas.length} disciplina${disciplinas.length != 1 ? 's' : ''} encontrada${disciplinas.length != 1 ? 's' : ''}",
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ],
    );
  }

  Widget _buildLegend(bool isMobile) {
    return Wrap(
      spacing: isMobile ? 12 : 20,
      runSpacing: isMobile ? 8 : 0,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: isMobile ? 4 : 6, backgroundColor: Colors.red),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              "Abaixo da média",
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: isMobile ? 4 : 6,
              backgroundColor: Colors.teal,
            ),
            SizedBox(width: isMobile ? 4 : 6),
            Text(
              "Acima da média",
              style: TextStyle(fontSize: isMobile ? 12 : 14),
            ),
          ],
        ),
      ],
    );
  }
}
