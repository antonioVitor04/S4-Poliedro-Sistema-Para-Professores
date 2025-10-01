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
import 'visualizacao_material_page.dart';

class DisciplinaDetailPage extends StatefulWidget {
  final String slug;
  final String titulo;

  const DisciplinaDetailPage({
    super.key,
    required this.slug,
    required this.titulo,
  });

  @override
  State<DisciplinaDetailPage> createState() => _DisciplinaDetailPageState();
}

class _DisciplinaDetailPageState extends State<DisciplinaDetailPage> {
  late Future<CardDisciplina> _futureCard;
  final List<int> _expandedTopicos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('🔍 Iniciando disciplina: ${widget.slug}');
    _carregarDisciplina();
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

  // No _DisciplinaDetailPageState, método _adicionarMaterial:
  // No método _adicionarMaterial do DisciplinaDetailPage, atualize:
  Future<void> _adicionarMaterial(int topicoIndex) async {
    final card = await _futureCard;
    final topico = card.topicos[topicoIndex];

    await showDialog(
      context: context,
      builder: (context) => AdicionarMaterialDialog(
        onConfirm: (tipo, titulo, descricao, url, peso, prazo, arquivo) async {
          // ADICIONE O arquivo AQUI
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

  // No _DisciplinaDetailPageState, atualize o método _criarMaterial:
  // No _DisciplinaDetailPageState, atualize o método:
  // No _DisciplinaDetailPageState, atualize a assinatura do método:
  Future<void> _criarMaterial(
    int topicoIndex,
    String tipo,
    String titulo,
    String? descricao,
    String? url,
    double peso,
    DateTime? prazo,
    PlatformFile? arquivo, // ADICIONE ESTE PARÂMETRO
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
    final descricaoController = TextEditingController(text: topico.descricao);

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 30,
          vertical: 80,
        ), // MENOS LARGO
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450), // LARGURA MÁXIMA
          child: Padding(
            padding: const EdgeInsets.all(20), // MENOS PADDING
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit,
                      color: AppColors.azulClaro,
                      size: 24,
                    ), // ÍCONE MENOR
                    const SizedBox(width: 8), // MENOS ESPAÇO
                    Text(
                      'Editar Tópico',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 18, // FONTE MENOR
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // MENOS ESPAÇO
                TextFormField(
                  controller: tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título do Tópico*',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.azulClaro,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: AppColors.azulClaro),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ), // MENOS ALTURA
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Por favor, insira um título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12), // MENOS ESPAÇO
                TextFormField(
                  controller: descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.azulClaro,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: AppColors.azulClaro),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  maxLines: 2, // MENOS LINHAS
                ),
                const SizedBox(height: 20), // MENOS ESPAÇO
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
                        ), // MENOS PADDING
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 14),
                      ), // TEXTO MENOR
                    ),
                    const SizedBox(width: 8), // MENOS ESPAÇO
                    ElevatedButton(
                      onPressed: () async {
                        if (tituloController.text.trim().isNotEmpty) {
                          await _atualizarTopico(
                            topicoIndex,
                            tituloController.text.trim(),
                            descricaoController.text.trim(),
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
                        ), // MENOS PADDING
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(fontSize: 14),
                      ), // TEXTO MENOR
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _atualizarTopico(
    int topicoIndex,
    String titulo,
    String descricao,
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
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
      floatingActionButton: !isMobile ? _buildFloatingActionButton() : null,
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
                    ), // AZUL
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
                return _buildLayoutMobile(card);
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
                  ), // AZUL
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _adicionarTopico,
      backgroundColor: AppColors.azulClaro,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Novo Tópico'),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildLayoutMobile(CardDisciplina card) {
    return Column(
      children: [
        _buildBanner(card),
        if (card.topicos.isEmpty) _buildEmptyState(),
        Expanded(child: _buildListaTopicos(card, true)),
      ],
    );
  }

  Widget _buildLayoutDesktop(CardDisciplina card) {
    return Column(
      children: [
        _buildBanner(card),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    if (card.topicos.isEmpty) _buildEmptyState(),
                    Expanded(child: _buildListaTopicos(card, false)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(flex: 1, child: _buildSidebarTarefas(card)),
            ],
          ),
        ),
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
          _buildBotaoAdicionarTopico(),
        ],
      ),
    );
  }

  Widget _buildBotaoAdicionarTopico() {
    return ElevatedButton.icon(
      onPressed: _adicionarTopico,
      icon: const Icon(Icons.add, size: 20),
      label: const Text('Criar Primeiro Tópico'),
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
      slivers: [
        if (isMobile && card.topicos.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBotaoAdicionarTopico(),
            ),
          ),
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
                    // Header do tópico
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
                                      style: TextStyle(color: Colors.red),
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

                    // Conteúdo expandido
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
              : null, // REMOVIDA A PRÉ-VISUALIZAÇÃO DE DATA E PESO
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
                    Text('Excluir', style: TextStyle(color: Colors.red)),
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

  Color _getPrazoColor(DateTime prazo) {
    final now = DateTime.now();
    final difference = prazo.difference(now);

    if (difference.inDays < 0) return Colors.red;
    if (difference.inDays <= 3) return Colors.orange;
    return Colors.green;
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
                    'Tarefas Pendentes',
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
                    : ListView.builder(
                        itemCount: tarefas.length,
                        itemBuilder: (context, index) {
                          final tarefa = tarefas[index];
                          return _buildTarefaItem(tarefa, index);
                        },
                      ),
              ),
            ],
          ),
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

  Widget _buildTarefaItem(MaterialDisciplina tarefa, int index) {
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
        builder: (context) => VisualizacaoMaterialPage(
          material: material,
          topicoTitulo: topicoTitulo,
        ),
      ),
    );
  }
}
