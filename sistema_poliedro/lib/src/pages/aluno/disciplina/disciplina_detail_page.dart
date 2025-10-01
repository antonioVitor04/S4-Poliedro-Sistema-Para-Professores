// pages/disciplina/disciplina_detail_page.dart
// disciplina_detail_page.dart - MANTÉM IGUAL
import 'package:flutter/material.dart';
import '../../../services/card_disciplina_service.dart';
import '../../../models/modelo_card_disciplina.dart';

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
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _futureCard = CardDisciplinaService.getCardBySlug(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 SEM Scaffold próprio - usa o da MainAlunoPage
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
                Icon(Icons.error_outline, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  'Erro ao carregar disciplina',
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
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
                Icon(Icons.search_off, size: 64, color: Colors.orange),
                SizedBox(height: 16),
                Text('Disciplina não encontrada'),
              ],
            ),
          );
        }

        final card = snapshot.data!;

        return Column(
          children: [
            // Header com imagem
            Container(
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
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
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
                        SizedBox(width: 12),
                        Text(
                          card.titulo,
                          style: TextStyle(
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

            // Tabs
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  _buildTab(0, 'Conteúdo'),
                  _buildTab(1, 'Exercícios'),
                  _buildTab(2, 'Materiais'),
                ],
              ),
            ),

            // Conteúdo da tab selecionada
            Expanded(
              child: _buildTabContent(_selectedTab, card),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTab(int index, String title) {
    return Expanded(
      child: TextButton(
        onPressed: () => setState(() => _selectedTab = index),
        style: TextButton.styleFrom(
          backgroundColor: _selectedTab == index 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: _selectedTab == index 
                ? Theme.of(context).primaryColor
                : Colors.grey,
            fontWeight: _selectedTab == index ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(int tabIndex, CardDisciplina card) {
    switch (tabIndex) {
      case 0: // Conteúdo
        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            Text(
              'Conteúdo da Disciplina',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildTopicItem('Introdução à ${card.titulo}'),
            _buildTopicItem('Conceitos Fundamentais'),
            _buildTopicItem('Aplicações Práticas'),
            _buildTopicItem('Exercícios Resolvidos'),
          ],
        );
      
      case 1: // Exercícios
        return Center(
          child: Text('Lista de exercícios em desenvolvimento...'),
        );
      
      case 2: // Materiais
        return Center(
          child: Text('Materiais de estudo em desenvolvimento...'),
        );
      
      default:
        return Container();
    }
  }

  Widget _buildTopicItem(String title) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.play_circle_filled, color: Colors.green),
        title: Text(title),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navegar para o conteúdo específico
        },
      ),
    );
  }
}