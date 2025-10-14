import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import '../../../styles/fontes.dart';
import '../../../components/disciplina_card.dart';
import '../../../services/card_disciplina_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../dialogs/adicionar_card_dialog.dart';
import '../../../dialogs/editar_card_dialog.dart';

class DisciplinasPageProfessor extends StatefulWidget {
  final Function(String, String) onNavigateToDetail;

  const DisciplinasPageProfessor({super.key, required this.onNavigateToDetail});

  @override
  State<DisciplinasPageProfessor> createState() => _DisciplinasPageProfessorState();
}

class _DisciplinasPageProfessorState extends State<DisciplinasPageProfessor> {
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

  Future<void> _adicionarCard() async {
    await showDialog(
      context: context,
      builder: (context) => AdicionarCardDialog(
        onConfirm: (titulo, imagemFile, iconeFile) async {
          try {
            await CardDisciplinaService.criarCard(
              titulo,
              imagemFile,
              iconeFile,
            );
            _refreshCards();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Disciplina adicionada com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao adicionar disciplina: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _editarCard(CardDisciplina card) async {
    await showDialog(
      context: context,
      builder: (context) => EditarCardDialog(
        card: card,
        onConfirm: (id, titulo, imagemFile, iconeFile) async {
          try {
            await CardDisciplinaService.atualizarCard(
              id,
              titulo,
              imagemFile,
              iconeFile,
            );
            _refreshCards();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Disciplina atualizada com sucesso!'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro ao atualizar disciplina: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _deletarCard(CardDisciplina card) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.branco,
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir a disciplina "${card.titulo}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await CardDisciplinaService.deletarCard(card.id);
        _refreshCards();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Disciplina "${card.titulo}" excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir disciplina: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      backgroundColor: Colors.white, //
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
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _adicionarCard,
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar Primeira Disciplina'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.azulClaro,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
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
              color: Colors
                  .white, // ✅ Fundo branco, garantindo que o Scaffold não herde lilás
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
                        return Stack(
                          children: [
                            DisciplinaCard(
                              disciplina: card.titulo,
                              imageUrl: card.imagem,
                              iconUrl: card.icone,
                              isMobile: isMobile,
                              onTap: () => widget.onNavigateToDetail(
                                card.slug,
                                card.titulo,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: PopupMenuButton<String>(
                                color: AppColors.branco,
                                icon: const Icon(
                                  Icons.more_vert,
                                  color: Colors.white,
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _editarCard(card);
                                  } else if (value == 'delete') {
                                    _deletarCard(card);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 20),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.delete,
                                          size: 20,
                                          color: Colors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Text('Excluir'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarCard,
        backgroundColor: AppColors.azulClaro,
        child: const Icon(Icons.add, color: Colors.white),
      ),
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
