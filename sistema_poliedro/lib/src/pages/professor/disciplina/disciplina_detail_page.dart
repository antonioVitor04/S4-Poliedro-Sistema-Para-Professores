// pages/disciplina/disciplina_detail_page.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../services/card_disciplina_service.dart';
import '../../../services/topico_service.dart';
import '../../../services/material_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../styles/cores.dart';
import '../../../styles/fontes.dart';
import '../../../dialogs/adicionar_topico_dialog.dart';
import '../../../dialogs/adicionar_material_dialog.dart';
import 'visualizacao_material_professor.dart';

class DisciplinaDetailPageProfessor extends StatefulWidget {
  final String slug;
  final String titulo;

  const DisciplinaDetailPageProfessor({
    super.key,
    required this.slug,
    required this.titulo,
  });

  @override
  State<DisciplinaDetailPageProfessor> createState() =>
      _DisciplinaDetailPageState();
}

class _DisciplinaDetailPageState extends State<DisciplinaDetailPageProfessor> {
  late Future<CardDisciplina> _futureCard;
  final List<int> _expandedTopicos = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  DateTime _lastScrollUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    print('🔍 Iniciando disciplina: ${widget.slug}');
    _carregarDisciplina();

    // Adicione o listener para o scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Otimização: throttle para evitar updates muito frequentes
    final now = DateTime.now();
    if (now.difference(_lastScrollUpdate).inMilliseconds < 16) {
      return; // Limita a ~60fps
    }

    // Define um threshold (pode ajustar conforme necessário)
    const threshold = 100.0;
    final newIsScrolled = _scrollController.offset > threshold;

    // Só atualiza se o valor mudou
    if (newIsScrolled != _isScrolled) {
      _lastScrollUpdate = now;
      setState(() {
        _isScrolled = newIsScrolled;
      });
    }
  }

  void _carregarDisciplina() {
    print('🔄 Carregando disciplina...');
    setState(() {
      _futureCard = CardDisciplinaService.getCardBySlug(widget.slug);
    });
  }

  void _toggleTopico(int index) {
    setState(() {
      if (_expandedTopicos.contains(index)) {
        _expandedTopicos.remove(index);
      } else {
        _expandedTopicos.add(index);
      }
    });
  }

  Future<void> _adicionarTopico() async {
    await showDialog(
      context: context,
      builder: (context) => AdicionarTopicoDialog(
        onConfirm: (titulo, descricao) async {
          await _criarTopico(titulo, descricao);
        },
      ),
    );
  }

  Future<void> _criarTopico(String titulo, String? descricao) async {
    setState(() => _isLoading = true);

    try {
      print('➕ Criando tópico: $titulo');
      await TopicoService.criarTopico(
        widget.slug,
        titulo,
        descricao: descricao,
      );

      // Forçar um pequeno delay antes de recarregar
      await Future.delayed(const Duration(milliseconds: 500));

      print('🔄 Recarregando dados após criar tópico...');
      _carregarDisciplina();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tópico "$titulo" criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Erro ao criar tópico: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar tópico: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _adicionarMaterial(int topicoIndex) async {
    final card = await _futureCard;
    final topico = card.topicos[topicoIndex];

    await showDialog(
      context: context,
      builder: (context) => AdicionarMaterialDialog(
        onConfirm: (tipo, titulo, descricao, url, peso, prazo, arquivo) async {
          await _criarMaterial(
            topicoIndex,
            tipo,
            titulo,
            descricao,
            url,
            peso,
            prazo,
            arquivo,
          );
        },
      ),
    );
  }

  Future<void> _criarMaterial(
    int topicoIndex,
    String tipo,
    String titulo,
    String? descricao,
    String? url,
    double peso,
    DateTime? prazo,
    PlatformFile? arquivo,
  ) async {
    setState(() => _isLoading = true);

    try {
      final card = await _futureCard;
      final topico = card.topicos[topicoIndex];

      await MaterialService.criarMaterial(
        slug: widget.slug,
        topicoId: topico.id,
        tipo: tipo,
        titulo: titulo,
        descricao: descricao,
        url: url,
        peso: peso,
        prazo: prazo,
        arquivo: arquivo,
      );

      _carregarDisciplina();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material "$titulo" adicionado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar material: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _editarTopico(int topicoIndex) async {
    final card = await _futureCard;
    final topico = card.topicos[topicoIndex];

    final tituloController = TextEditingController(text: topico.titulo);
    final descricaoController = TextEditingController(
      text: topico.descricao ?? '',
    );
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 32,
                                color: AppColors.azulClaro,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Editar Tópico',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Atualize as informações do tópico',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: tituloController,
                        cursorColor: AppColors.azulClaro,
                        style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Título do Tópico*',
                          labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                            color: Colors.black,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.preto.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.azulClaro,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: Icon(
                            Icons.title,
                            color: AppColors.azulClaro,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, insira um título';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descricaoController,
                        cursorColor: AppColors.azulClaro,
                        style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Descrição (opcional)',
                          labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                            color: Colors.black,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.preto.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.azulClaro,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: Icon(
                            Icons.description,
                            color: AppColors.azulClaro,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                final descricao =
                                    descricaoController.text.trim().isEmpty
                                    ? null
                                    : descricaoController.text.trim();
                                await _atualizarTopico(
                                  topicoIndex,
                                  tituloController.text.trim(),
                                  descricao,
                                );
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.azulClaro,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: const Text(
                              'Salvar',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _atualizarTopico(
    int topicoIndex,
    String titulo,
    String? descricao,
  ) async {
    setState(() => _isLoading = true);

    try {
      final card = await _futureCard;
      final topico = card.topicos[topicoIndex];

      await TopicoService.atualizarTopico(
        widget.slug,
        topico.id,
        titulo: titulo,
        descricao: descricao,
      );

      _carregarDisciplina();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tópico atualizado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar tópico: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletarTopico(int topicoIndex) async {
    final card = await _futureCard;
    final topico = card.topicos[topicoIndex];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o tópico "${topico.titulo}"? Esta ação não pode ser desfeita.',
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
              foregroundColor: Colors.black,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await TopicoService.deletarTopico(widget.slug, topico.id);
        _carregarDisciplina();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tópico "${topico.titulo}" excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir tópico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deletarMaterial(int topicoIndex, int materialIndex) async {
    final card = await _futureCard;
    final topico = card.topicos[topicoIndex];
    final material = topico.materiais[materialIndex];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir o material "${material.titulo}"?',
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
              foregroundColor: Colors.black,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await MaterialService.deletarMaterial(
          slug: widget.slug,
          topicoId: topico.id,
          materialId: material.id,
        );

        _carregarDisciplina();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Material "${material.titulo}" excluído com sucesso!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir material: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: AppColors.branco,
      body: Stack(
        children: [
          FutureBuilder<CardDisciplina>(
            future: _futureCard,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
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
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar disciplina',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _carregarDisciplina,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData) {
                print('📭 Sem dados');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.orange,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Disciplina não encontrada',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final card = snapshot.data!;
              print('✅ Dados carregados: ${card.titulo}');
              print('📂 Tópicos encontrados: ${card.topicos.length}');

              for (var topico in card.topicos) {
                print(
                  '   - ${topico.titulo} (${topico.materiais.length} materiais)',
                );
              }

              if (isMobile) {
                return CustomScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(), // Física mais suave
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 200.0,
                      floating: false,
                      pinned: true,
                      automaticallyImplyLeading: false,
                      backgroundColor: _isScrolled
                          ? Colors.white
                          : Colors.transparent,
                      foregroundColor: _isScrolled
                          ? Colors.black
                          : Colors.white,
                      elevation: _isScrolled ? 4 : 0,
                      actions: [
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.assignment,
                            color: _isScrolled ? Colors.black : Colors.white,
                          ),
                          onSelected: (value) {
                            if (value == 'tasks') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TasksPage(slug: widget.slug),
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'tasks',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.assignment,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tarefas',
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        title: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _isScrolled ? 1.0 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Row(
                              children: [
                                Image.network(
                                  card.icone,
                                  width: 24,
                                  height: 24,
                                  color: _isScrolled
                                      ? Colors.black
                                      : Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    card.titulo,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _isScrolled
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              card.imagem,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (card.topicos.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildEmptyState(),
                        ),
                      )
                    else ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildBotaoAdicionarTopico(
                            card.topicos.isEmpty,
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final topico = card.topicos[index];
                          final isExpanded = _expandedTopicos.contains(index);

                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  // Header do tópico
                                  ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.azulClaro.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.folder,
                                        color: AppColors.azulClaro,
                                      ),
                                    ),
                                    title: Text(
                                      topico.titulo,
                                      style: AppTextStyles.fonteUbuntuSans
                                          .copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    subtitle: Text(
                                      '${topico.materiais.length} materiais',
                                      style: AppTextStyles.fonteUbuntuSans
                                          .copyWith(color: Colors.grey[600]),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PopupMenuButton<String>(
                                          icon: Icon(
                                            Icons.more_vert,
                                            color: Colors.grey[600],
                                          ),
                                          onSelected: (value) {
                                            if (value == 'edit') {
                                              _editarTopico(index);
                                            } else if (value == 'delete') {
                                              _deletarTopico(index);
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
                                                  Text(
                                                    'Excluir',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: AppColors.azulClaro,
                                        ),
                                      ],
                                    ),
                                    onTap: () => _toggleTopico(index),
                                  ),

                                  // Conteúdo expandido
                                  if (isExpanded) ...[
                                    const Divider(height: 1),
                                    if (topico.materiais.isEmpty)
                                      _buildEmptyMaterialState(
                                        topico.titulo,
                                        index,
                                      ),
                                    ...topico.materiais.asMap().entries.map((
                                      entry,
                                    ) {
                                      final materialIndex = entry.key;
                                      final material = entry.value;
                                      return _buildMaterialItem(
                                        material,
                                        materialIndex,
                                        topico.titulo,
                                        topicoIndex: index,
                                      );
                                    }).toList(),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: _buildBotaoAdicionarMaterial(
                                        topicoIndex: index,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }, childCount: card.topicos.length),
                      ),
                    ],
                  ],
                );
              } else {
                return _buildLayoutDesktop(card);
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.azulClaro,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ... (os métodos restantes permanecem iguais)
  Widget _buildLayoutDesktop(CardDisciplina card) {
    return Column(
      children: [
        _buildBanner(card),
        if (card.topicos.isEmpty)
          _buildEmptyState()
        else ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildBotaoAdicionarTopico(card.topicos.isEmpty),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildListaTopicos(card, false)),
                const SizedBox(width: 16),
                Expanded(flex: 1, child: _buildSidebarTarefas(card)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBanner(CardDisciplina card) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(card.imagem),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
          ),
        ),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Image.network(
                  card.icone,
                  width: 40,
                  height: 40,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  card.titulo,
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Nenhum tópico criado',
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Comece adicionando o primeiro tópico à disciplina',
            textAlign: TextAlign.center,
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          _buildBotaoAdicionarTopico(true),
        ],
      ),
    );
  }

  Widget _buildBotaoAdicionarTopico(bool isEmpty) {
    return ElevatedButton.icon(
      onPressed: _adicionarTopico,
      icon: const Icon(Icons.add, size: 20),
      label: Text(isEmpty ? 'Criar Primeiro Tópico' : 'Adicionar Novo Tópico'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.azulClaro,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      ),
    );
  }

  Widget _buildListaTopicos(CardDisciplina card, bool isMobile) {
    return CustomScrollView(
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final topico = card.topicos[index];
            final isExpanded = _expandedTopicos.contains(index);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.azulClaro.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.folder, color: AppColors.azulClaro),
                      ),
                      title: Text(
                        topico.titulo,
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${topico.materiais.length} materiais',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isMobile)
                            _buildBotaoAdicionarMaterial(topicoIndex: index),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert,
                              color: Colors.grey[600],
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editarTopico(index);
                              } else if (value == 'delete') {
                                _deletarTopico(index);
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
                                    Text(
                                      'Excluir',
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isExpanded ? Icons.expand_less : Icons.expand_more,
                            color: AppColors.azulClaro,
                          ),
                        ],
                      ),
                      onTap: () => _toggleTopico(index),
                    ),

                    if (isExpanded) ...[
                      const Divider(height: 1),
                      if (topico.materiais.isEmpty)
                        _buildEmptyMaterialState(topico.titulo, index),
                      ...topico.materiais.asMap().entries.map((entry) {
                        final materialIndex = entry.key;
                        final material = entry.value;
                        return _buildMaterialItem(
                          material,
                          materialIndex,
                          topico.titulo,
                          topicoIndex: index,
                        );
                      }).toList(),
                      if (isMobile && topico.materiais.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildBotaoAdicionarMaterial(
                            topicoIndex: index,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            );
          }, childCount: card.topicos.length),
        ),
      ],
    );
  }

  Widget _buildEmptyMaterialState(String topicoTitulo, int topicoIndex) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.insert_drive_file, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Nenhum material neste tópico',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione materiais, links ou atividades',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          _buildBotaoAdicionarMaterial(topicoIndex: topicoIndex),
        ],
      ),
    );
  }

  Widget _buildBotaoAdicionarMaterial({required int topicoIndex}) {
    return ElevatedButton.icon(
      onPressed: () => _adicionarMaterial(topicoIndex),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Adicionar Material'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green[50],
        foregroundColor: Colors.green[700],
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.green[300]!),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildMaterialItem(
    MaterialDisciplina material,
    int materialIndex,
    String topicoTitulo, {
    required int topicoIndex,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[200]!),
        ),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getMaterialColor(material.tipo).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getMaterialIconData(material.tipo),
              color: _getMaterialColor(material.tipo),
              size: 20,
            ),
          ),
          title: Text(
            material.titulo,
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: material.descricao != null
              ? Text(
                  material.descricao!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                )
              : null,
          trailing: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
            onSelected: (value) {
              if (value == 'delete') {
                _deletarMaterial(topicoIndex, materialIndex);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            _abrirVisualizacaoMaterial(material, topicoTitulo);
          },
        ),
      ),
    );
  }

  Color _getMaterialColor(String tipo) {
    switch (tipo) {
      case 'pdf':
        return Colors.red;
      case 'imagem':
        return Colors.green;
      case 'link':
        return Colors.blue;
      case 'atividade':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMaterialIconData(String tipo) {
    switch (tipo) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'imagem':
        return Icons.image;
      case 'link':
        return Icons.link;
      case 'atividade':
        return Icons.assignment;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildSidebarTarefas(CardDisciplina card) {
    final tarefas = <MaterialDisciplina>[];
    for (final topico in card.topicos) {
      for (final material in topico.materiais) {
        if (material.prazo != null) {
          tarefas.add(material);
        }
      }
    }
    tarefas.sort((a, b) => a.prazo!.compareTo(b.prazo!));

    final now = DateTime.now();
    final pendentes = tarefas
        .where((t) => t.prazo!.isAfter(now.subtract(const Duration(days: 1))))
        .toList();
    final passadas = tarefas.where((t) => t.prazo!.isBefore(now)).toList();

    return Container(
      margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.azulClaro.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.assignment,
                      color: AppColors.azulClaro,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tarefas',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: tarefas.isEmpty
                    ? _buildEmptyTarefasState()
                    : Column(
                        children: [
                          // Seção Pendentes
                          if (pendentes.isNotEmpty) ...[
                            _buildSectionHeader('Pendentes'),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Tarefas com prazo futuro ou em até 1 dia',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                physics: const ClampingScrollPhysics(),
                                itemCount: pendentes.length,
                                itemBuilder: (context, index) {
                                  final tarefa = pendentes[index];
                                  return _buildTarefaItem(tarefa);
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Seção Passadas
                          if (passadas.isNotEmpty) ...[
                            _buildSectionHeader('Passadas'),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Tarefas vencidas',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                physics: const ClampingScrollPhysics(),
                                itemCount: passadas.length,
                                itemBuilder: (context, index) {
                                  final tarefa = passadas[index];
                                  return _buildTarefaItem(tarefa);
                                },
                              ),
                            ),
                          ],
                          if (pendentes.isEmpty && passadas.isEmpty)
                            _buildEmptyTarefasState(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildEmptyTarefasState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Nenhuma tarefa',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Todas as tarefas estão em dia!',
            textAlign: TextAlign.center,
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTarefaItem(MaterialDisciplina tarefa) {
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
                '${tarefa.prazo!.day}/${tarefa.prazo!.month}/${tarefa.prazo!.year}',
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
            _abrirVisualizacaoMaterial(tarefa, 'Tarefa');
          },
        ),
      ),
    );
  }

  Color _getTarefaColor(DateTime prazo) {
    final now = DateTime.now();
    final difference = prazo.difference(now);

    if (difference.inDays < 0) return Colors.red;
    if (difference.inDays <= 3) return Colors.orange;
    return AppColors.azulClaro;
  }

  void _abrirVisualizacaoMaterial(
    MaterialDisciplina material,
    String topicoTitulo,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VisualizacaoMaterialPageProfessor(
          material: material,
          topicoTitulo: topicoTitulo,
        ),
      ),
    );
  }
}

// ... (TasksPage permanece igual)
class TasksPage extends StatefulWidget {
  final String slug;

  const TasksPage({super.key, required this.slug});

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
    final difference = prazo.difference(now);

    if (difference.inDays < 0) return Colors.red;
    if (difference.inDays <= 3) return Colors.orange;
    return AppColors.azulClaro;
  }

  Widget _buildTarefaItem(MaterialDisciplina tarefa) {
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
                '${tarefa.prazo!.day}/${tarefa.prazo!.month}/${tarefa.prazo!.year}',
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
                builder: (context) => VisualizacaoMaterialPageProfessor(
                  material: tarefa,
                  topicoTitulo: 'Tarefa',
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
              style: const TextStyle(color: Colors.grey, fontSize: 16),
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
        title: const Text('Tarefas', style: TextStyle(color: Colors.black)),
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
              child: Text(
                'Erro ao carregar tarefas',
                style: TextStyle(color: Colors.black),
              ),
            );
          }

          final card = snapshot.data!;
          final allTarefas = <MaterialDisciplina>[];
          for (final topico in card.topicos) {
            for (final material in topico.materiais) {
              if (material.prazo != null) {
                allTarefas.add(material);
              }
            }
          }

          final now = DateTime.now();
          final pendentes = allTarefas
              .where(
                (t) => t.prazo!.isAfter(now.subtract(const Duration(days: 1))),
              )
              .toList();
          final passadas = allTarefas
              .where((t) => t.prazo!.isBefore(now))
              .toList();

          pendentes.sort((a, b) => a.prazo!.compareTo(b.prazo!));
          passadas.sort((a, b) => b.prazo!.compareTo(a.prazo!));

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
                              'Tarefas com prazo futuro ou em até 1 dia',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          ...pendentes.map(
                            (tarefa) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildTarefaItem(tarefa),
                            ),
                          ),
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
                          ...passadas.map(
                            (tarefa) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: _buildTarefaItem(tarefa),
                            ),
                          ),
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
