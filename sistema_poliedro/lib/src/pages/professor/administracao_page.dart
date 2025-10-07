import 'package:flutter/material.dart';

class AdministracaoPage extends StatefulWidget {
  @override
  State<AdministracaoPage> createState() => _AdministracaoPageState();
}

class _AdministracaoPageState extends State<AdministracaoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Administração")),
      body: const Center(child: Text("Página de Administração")),
    );
  }
}
