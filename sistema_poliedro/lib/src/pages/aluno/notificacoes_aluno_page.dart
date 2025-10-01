import 'package:flutter/material.dart';
import '../../styles/fontes.dart';
class NotificacoesPage extends StatelessWidget {
  const NotificacoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              "Notificações",
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        SizedBox(height: 20),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text("Nova tarefa de Matemática disponível."),
          subtitle: Text("Postado em 29/09/2025"),
        ),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text("Prova de Física adiada para 05/10."),
          subtitle: Text("Postado em 28/09/2025"),
        ),
        ListTile(
          leading: Icon(Icons.notifications),
          title: Text("Entrega de Projeto de Programação amanhã."),
          subtitle: Text("Postado em 27/09/2025"),
        ),
        // Adicione mais notificações
      ],
    );
  }
}
