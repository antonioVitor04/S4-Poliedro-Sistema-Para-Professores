import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import '../../../styles/fontes.dart';
import '../../../components/disciplina_card.dart';
import '../../../services/card_disciplina_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../dialogs/adicionar_card_dialog.dart';
import '../../../dialogs/editar_card_dialog.dart';

class DisciplinasPage extends StatefulWidget {
  final Function(String, String) onNavigateToDetail;

  const DisciplinasPage({super.key, required this.onNavigateToDetail});

  @override
  State<DisciplinasPage> createState() => _DisciplinasPageState();
}

class _DisciplinasPageState extends State<DisciplinasPage> {
  late Future<List<CardDisciplina>> _futureCards;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _futureCards = _loadCards();
  }

  Future<List<CardDisciplina>> _loadCards() async {
    try {
      final cards = await CardDisciplinaService.getAllCards();
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return cards;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
      return [];
    }
  }

  void _refreshCards() {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _futureCards = _loadCards();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulClaro),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Erro ao carregar disciplinas',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            Text(
              _errorMessage,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _refreshCards,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshCards();
          await _futureCards;
        },
        child: FutureBuilder<List<CardDisciplina>>(
          future: _futureCards,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.azulClaro,
                  ),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Erro: ${snapshot.error}'),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _refreshCards,
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.menu_book,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma disciplina encontrada.',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            final cards = snapshot.data!;

            return Container(
              color: Colors.white,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 20, 20, 10),
                      child: Text(
                        "Disciplinas",
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: isMobile ? 22 : 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(screenWidth),
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 12,
                        childAspectRatio: _getAspectRatio(screenWidth),
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final card = cards[index];
                        return DisciplinaCard(
                          disciplina: card.titulo,
                          imageUrl: card.imagem,
                          iconUrl: card.icone,
                          isMobile: isMobile,
                          onTap: () => widget.onNavigateToDetail(
                            card.slug,
                            card.titulo,
                          ),
                        );
                      }, childCount: cards.length),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      // Botão de adicionar removido
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1000) return 3;
    if (width > 600) return 2;
    return 1;
  }

  double _getAspectRatio(double width) {
    if (width > 1000) return 1.5;
    if (width > 600) return 1.2;
    return 1.5;
  }
}