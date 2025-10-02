// disciplinas_aluno_page.dart
import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import '../../../styles/fontes.dart';
import '../../../components/disciplina_card.dart';
import '../../../services/card_disciplina_service.dart';
import '../../../models/modelo_card_disciplina.dart';

class DisciplinasPage extends StatefulWidget {
  final Function(String, String) onNavigateToDetail; // 🔥 Novo parâmetro

  const DisciplinasPage({
    super.key,
    required this.onNavigateToDetail, // 🔥 Recebe a função
  });

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
      if (mounted) { // Verifica se o widget ainda está montado
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

    // Se ainda carregando globalmente, mostra loader simples
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Se erro global, mostra erro simples
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Erro ao carregar disciplinas',
              style: TextStyle(fontSize: 16, color: Colors.red),
            ),
            Text(
              _errorMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey),
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

    return RefreshIndicator(
      onRefresh: () async {
        _refreshCards();
        await _futureCards; // Espera o futuro completar
      },
      child: FutureBuilder<List<CardDisciplina>>(
        future: _futureCards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
            return const Center(
              child: Text('Nenhuma disciplina encontrada.'),
            );
          }

          final cards = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // Título como SliverToBoxAdapter (rola junto com o conteúdo)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 20, 20, 10), // Padding similar ao original
                  child: Text(
                    "Disciplinas",
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: isMobile ? 22 : 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Grid como SliverGrid (scroll fluido)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _getCrossAxisCount(screenWidth),
                    crossAxisSpacing: 20, // Reduzido de 30 para 20 (espaçamento menor entre cards)
                    mainAxisSpacing: 12, // Reduzido de 16 para 12 (espaçamento vertical menor)
                    childAspectRatio: _getAspectRatio(screenWidth), // Ajustado para cards menores
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final card = cards[index];
                      return DisciplinaCard(
                        disciplina: card.titulo,
                        imageUrl: card.imagem,
                        iconUrl: card.icone,
                        isMobile: isMobile,
                        // 🔥 USA A FUNÇÃO PASSADA COMO PARÂMETRO
                        onTap: () => widget.onNavigateToDetail(
                          card.slug,
                          card.titulo,
                        ),
                      );
                    },
                    childCount: cards.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1000) {
      return 3;
    } else if (width > 600) {
      return 2;
    } else {
      return 1;
    }
  }

  double _getAspectRatio(double width) {
    if (width > 1000) {
      return 1.5; // Aumentado de 1.3 para 1.5 (cards mais "achatados" = menores em altura)
    } else if (width > 600) {
      return 1.2; // Aumentado de 1.0 para 1.2
    } else {
      return 1.5; // Aumentado de 1.2 para 1.5 (menor altura no mobile)
    }
  }
}