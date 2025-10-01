// dialogs/adicionar_topico_dialog.dart
import 'package:flutter/material.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';

class AdicionarTopicoDialog extends StatefulWidget {
  final Function(String titulo, String? descricao) onConfirm;

  const AdicionarTopicoDialog({super.key, required this.onConfirm});

  @override
  State<AdicionarTopicoDialog> createState() => _AdicionarTopicoDialogState();
}

class _AdicionarTopicoDialogState extends State<AdicionarTopicoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 30, vertical: 80), // MENOS LARGO
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450), // LARGURA MÁXIMA
        child: Padding(
          padding: const EdgeInsets.all(20), // MENOS PADDING
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.create_new_folder, color: AppColors.azulClaro, size: 24), // ÍCONE MENOR
                    const SizedBox(width: 8), // MENOS ESPAÇO
                    Text(
                      'Novo Tópico',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 18, // FONTE MENOR
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // MENOS ESPAÇO
                TextFormField(
                  controller: _tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título do Tópico*',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title, color: AppColors.azulClaro),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // MENOS ALTURA
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
                  controller: _descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description, color: AppColors.azulClaro),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.azulClaro, width: 2),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // MENOS PADDING
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontSize: 14)), // TEXTO MENOR
                    ),
                    const SizedBox(width: 8), // MENOS ESPAÇO
                    ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulClaro,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // MENOS PADDING
                      ),
                      child: const Text('Criar Tópico', style: TextStyle(fontSize: 14)), // TEXTO MENOR
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

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      widget.onConfirm(
        _tituloController.text.trim(),
        _descricaoController.text.trim().isNotEmpty 
            ? _descricaoController.text.trim() 
            : null,
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }
}