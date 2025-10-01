// pages/disciplina/disciplina_detail_page.dart
import 'package:flutter/material.dart';
import '../../../services/card_disciplina_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../styles/cores.dart';
import '../../../styles/fontes.dart';

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

  @override
  void initState() {
    super.initState();
    _futureCard = CardDisciplinaService.getCardBySlug(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return FutureBuilder<CardDisciplina>(
      future: _futureCard,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar disciplina',
                  style: AppTextStyles.fonteUbuntuSans.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.fonteUbuntuSans.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  'Disciplina não encontrada',
                  style: AppTextStyles.fonteUbuntuSans.copyWith(fontSize: 18),
                ),
              ],
            ),
          );
        }

        final card = snapshot.data!;

        return Column(
          children: [
            // Header com imagem
            Container(
              height: isMobile ? 200 : 200,
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
            ),
          ],
        );
      },
    );
  }


  Widget _buildTabContent(int tabIndex, CardDisciplina card) {
    switch (tabIndex) {
      case 0: // Conteúdo
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Conteúdo da Disciplina',
              style: AppTextStyles.fonteUbuntuCondensed.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTopicItem('Introdução à ${card.titulo}'),
            _buildTopicItem('Conceitos Fundamentais'),
            _buildTopicItem('Aplicações Práticas'),
            _buildTopicItem('Exercícios Resolvidos'),
          ],
        );

      case 1: // Exercícios
        return Center(
          child: Text(
            'Lista de exercícios em desenvolvimento...',
            style: AppTextStyles.fonteUbuntuSans.copyWith(fontSize: 16),
          ),
        );

      case 2: // Materiais
        return Center(
          child: Text(
            'Materiais de estudo em desenvolvimento...',
            style: AppTextStyles.fonteUbuntuSans.copyWith(fontSize: 16),
          ),
        );

      default:
        return Container();
    }
  }

  Widget _buildTopicItem(String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(
          Icons.play_circle_filled,
          color: AppColors.azulClaro,
        ),
        title: Text(
          title,
          style: AppTextStyles.fonteUbuntuSans.copyWith(fontSize: 16),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navegar para o conteúdo específico
        },
      ),
    );
  }
}
