import 'package:flutter/material.dart';
import 'animated_card_button.dart';

class DisciplinaCard extends StatelessWidget {
  final String disciplina;
  final String imageAsset;
  final bool isMobile;
  final VoidCallback onTap;

  const DisciplinaCard({
    super.key,
    required this.disciplina,
    required this.imageAsset,
    required this.isMobile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCardButton(
      onTap: onTap,
      childBuilder: (hovering, scale) {
        return AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          child: Card(
            elevation: hovering ? 10 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Banner
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      image: DecorationImage(
                        image: AssetImage(imageAsset),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, left: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _getIconForDisciplina(disciplina),
                          color: Colors.white,
                          size: isMobile ? 24 : 26,
                        ),
                      ),
                    ),
                  ),
                ),

                // Nome
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(left: 12, top: 8, bottom: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        disciplina,
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 21,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForDisciplina(String disciplina) {
    switch (disciplina.toLowerCase()) {
      case 'matemática':
        return Icons.calculate;
      case 'física':
        return Icons.science;
      case 'química':
        return Icons.emoji_objects;
      default:
        return Icons.school;
    }
  }
}