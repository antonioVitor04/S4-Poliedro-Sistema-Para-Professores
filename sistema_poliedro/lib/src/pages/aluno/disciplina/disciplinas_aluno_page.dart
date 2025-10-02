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
      final cards = await CardDisciplinaService.getCards();
      setState(() {
        _isLoading = false;
      });
      return cards;
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
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

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                "Disciplinas",
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: isMobile ? 22 : 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator())),

            if (_errorMessage.isNotEmpty)
              Expanded(
                child: Center(
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
                        child: Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              ),

            if (!_isLoading && _errorMessage.isEmpty)
              Expanded(
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
                              child: Text('Tentar Novamente'),
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

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount;
                        if (constraints.maxWidth > 1000) {
                          crossAxisCount = 3;
                        } else if (constraints.maxWidth > 600) {
                          crossAxisCount = 2;
                        } else {
                          crossAxisCount = 1;
                        }

                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 30,
                          mainAxisSpacing: 16,
                          childAspectRatio: _getAspectRatio(
                            constraints.maxWidth,
                          ),
                          padding: const EdgeInsets.all(25),
                          children: cards.map((card) {
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
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _getAspectRatio(double width) {
    if (width > 1000) {
      return 1.3;
    } else if (width > 600) {
      return 1.0;
    } else {
      return 1.2;
    }
  }
}
