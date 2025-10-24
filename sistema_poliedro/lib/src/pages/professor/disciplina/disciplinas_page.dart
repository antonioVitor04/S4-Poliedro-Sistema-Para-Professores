import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:sistema_poliedro/src/styles/cores.dart';
import '../../../styles/fontes.dart';
import '../../../components/disciplina_card.dart';
import '../../../services/card_disciplina_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../dialogs/adicionar_card_dialog.dart';
import '../../../dialogs/editar_card_dialog.dart';
import '../../../dialogs/gerenciar_relacionamentos_dialog.dart';

class DisciplinasPageProfessor extends StatefulWidget {
  final Function(String, String) onNavigateToDetail;

  const DisciplinasPageProfessor({super.key, required this.onNavigateToDetail});

  @override
  State<DisciplinasPageProfessor> createState() =>
      _DisciplinasPageProfessorState();
}

class _DisciplinasPageProfessorState extends State<DisciplinasPageProfessor> {
  late Future<List<CardDisciplina>> _futureCards;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isAdmin = false;
  bool _isProfessor = false;

  @override
  void initState() {
    super.initState();
    _verificarPermissoes();
    _futureCards = _loadCards();
  }

  Future<void> _verificarPermissoes() async {
    final isAdmin = await AuthService.isAdmin();
    final isProfessor = await AuthService.isProfessor();
    setState(() {
      _isAdmin = isAdmin;
      _isProfessor = isProfessor;
    });
  }

  Future<List<CardDisciplina>> _loadCards() async {
    try {
      List<CardDisciplina> cards;

      if (_isAdmin) {
        // Admin vê todas as disciplinas
        cards = await CardDisciplinaService.getAllCards();
      } else {
        // Professor/Aluno vê apenas suas disciplinas
        cards = await CardDisciplinaService.getMinhasDisciplinas();
      }

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
    // Verificar permissões antes de editar
    final podeEditar = await card.podeEditar();
    if (!podeEditar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem permissão para editar esta disciplina'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
    // Verificar permissões antes de deletar
    final podeDeletar = await card.podeDeletar();
    if (!podeDeletar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem permissão para deletar esta disciplina'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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

  Future<void> _gerenciarRelacionamentos(CardDisciplina card) async {
    final podeEditar = await card.podeEditar();
    if (!podeEditar) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Você não tem permissão para gerenciar esta disciplina',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) =>
          GerenciarRelacionamentosDialog(card: card, onUpdated: _refreshCards),
    );
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
                            _isAdmin
                                ? 'Nenhuma disciplina encontrada.'
                                : 'Você não está vinculado a nenhuma disciplina.',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if ((_isProfessor ||
                              _isAdmin)) // Adicione || _isAdmin
                            ElevatedButton.icon(
                              onPressed: _adicionarCard,
                              icon: const Icon(Icons.add),
                              label: const Text(
                                'Adicionar Primeira Disciplina',
                              ), // Ou "Adicionar Disciplina (Admin)" se quiser diferenciar
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
              color: Colors.white,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 20, 20, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAdmin
                                ? "Todas as Disciplinas"
                                : "Minhas Disciplinas",
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: isMobile ? 22 : 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_isAdmin)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Modo Administrador - Visualizando todas as disciplinas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
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
                        return _buildDisciplinaCard(card, isMobile);
                      }, childCount: cards.length),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton:
          (_isProfessor || _isAdmin) // Adicione || _isAdmin
          ? FloatingActionButton(
              onPressed: _adicionarCard,
              backgroundColor: AppColors.azulClaro,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildDisciplinaCard(CardDisciplina card, bool isMobile) {
    return FutureBuilder<bool>(
      future: card.podeEditar(),
      builder: (context, snapshot) {
        final podeEditar = snapshot.data ?? false;

        return Stack(
          children: [
            DisciplinaCard(
              disciplina: card.titulo,
              imageUrl: card.imagem,
              iconUrl: card.icone,
              isMobile: isMobile,
              onTap: () => widget.onNavigateToDetail(card.slug, card.titulo),
              badge: _isAdmin ? 'ADMIN' : null,
            ),
            if (podeEditar)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<String>(
                    color: AppColors.branco,
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _editarCard(card);
                      } else if (value == 'delete') {
                        _deletarCard(card);
                      } else if (value == 'manage') {
                        _gerenciarRelacionamentos(card);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'manage',
                        child: Row(
                          children: [
                            Icon(Icons.group, size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Gerenciar Acessos'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
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
