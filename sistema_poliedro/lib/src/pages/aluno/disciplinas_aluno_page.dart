import 'package:flutter/material.dart';
import '../../styles/fontes.dart';
import '../../components/disciplina_card.dart';

class DisciplinasPage extends StatelessWidget {
  const DisciplinasPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Padding(
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

          Expanded(
            child: LayoutBuilder(
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
                  childAspectRatio: _getAspectRatio(constraints.maxWidth),
                  padding: const EdgeInsets.all(25),
                  children: [
                    DisciplinaCard(
                      disciplina: "Matemática",
                      imageAsset: "assets/images/matematica.png",
                      isMobile: isMobile,
                      onTap: () => _navigateToDisciplina(context, "Matemática"),
                    ),
                    DisciplinaCard(
                      disciplina: "Física",
                      imageAsset: "assets/images/fisica.jpg",
                      isMobile: isMobile,
                      onTap: () => _navigateToDisciplina(context, "Física"),
                    ),
                    DisciplinaCard(
                      disciplina: "Química",
                      imageAsset: "assets/images/quimica.png",
                      isMobile: isMobile,
                      onTap: () => _navigateToDisciplina(context, "Química"),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
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

  void _navigateToDisciplina(BuildContext context, String disciplina) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(disciplina)),
          body: Center(child: Text("Página de $disciplina")),
        ),
      ),
    );
  }
}