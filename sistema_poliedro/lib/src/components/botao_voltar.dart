import 'package:flutter/material.dart';
import '../styles/cores.dart';

class BotaoVoltar extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? corIcone;
  final Color? corFundo;

  const BotaoVoltar({super.key, this.onPressed, this.corIcone, this.corFundo});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16, // Considera a status bar
      left: 16,
      child: Container(
        decoration: BoxDecoration(
          color: corFundo ?? AppColors.branco, // Fundo branco por padrão
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: corIcone ?? AppColors.preto, // Ícone preto por padrão
            size: 24,
          ),
          onPressed:
              onPressed ??
              () {
                Navigator.of(context).pop();
              },
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
          ),
        ),
      ),
    );
  }
}
