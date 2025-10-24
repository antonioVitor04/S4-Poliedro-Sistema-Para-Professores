// dialogs/adicionar_card_dialog.dart
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';
import '../components/alerta.dart'; // ✅ usa o seu componente de alerta

class AdicionarCardDialog extends StatefulWidget {
  final Function(
    String titulo,
    PlatformFile imagem,
    PlatformFile icone,
  ) onConfirm;

  const AdicionarCardDialog({super.key, required this.onConfirm});

  @override
  State<AdicionarCardDialog> createState() => _AdicionarCardDialogState();
}

class _AdicionarCardDialogState extends State<AdicionarCardDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();

  PlatformFile? _imagemSelecionada;
  PlatformFile? _iconeSelecionado;

  // ✅ helper local: mostra o AlertaWidget acima do diálogo
  Future<void> _mostrarAlerta(
    String mensagem, {
    required bool sucesso,
    bool barrierDismissible = true,
    Duration autoClose = const Duration(seconds: 3),
  }) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    // some qualquer SnackBar que possa estar visível
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.clearSnackBars();

    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (_) => AlertaWidget(
        mensagem: mensagem,
        sucesso: sucesso,
      ),
    );

    await Future.delayed(autoClose);
    if (mounted && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
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
                              Icons.add_circle,
                              size: 32,
                              color: AppColors.azulClaro,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Adicionar Disciplina',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Preencha as informações da nova disciplina',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título
                    TextFormField(
                      controller: _tituloController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Título da Disciplina*',
                        labelStyle: AppTextStyles.fonteUbuntu.copyWith(color: Colors.black),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.preto.withOpacity(0.1)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.azulClaro,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: Icon(Icons.title, color: AppColors.azulClaro),
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

                    // Imagem Principal
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Imagem Principal*',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.azulClaro,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.azulClaro.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              if (_imagemSelecionada == null)
                                ElevatedButton.icon(
                                  onPressed: _selecionarImagem,
                                  icon: const Icon(
                                    Icons.image,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Selecionar Imagem',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.azulClaro,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.image,
                                          color: AppColors.azulClaro,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _imagemSelecionada!.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${(_imagemSelecionada!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _imagemSelecionada = null;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ElevatedButton.icon(
                                      onPressed: _selecionarImagem,
                                      icon: const Icon(
                                        Icons.swap_horiz,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Trocar Imagem',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[100],
                                        foregroundColor: Colors.grey[800],
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    // Ícone
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ícone*',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.azulClaro,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.azulClaro.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              if (_iconeSelecionado == null)
                                ElevatedButton.icon(
                                  onPressed: _selecionarIcone,
                                  icon: const Icon(
                                    Icons.image,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Selecionar Ícone',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.azulClaro,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                )
                              else
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.image,
                                          color: AppColors.azulClaro,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                _iconeSelecionado!.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                '${(_iconeSelecionado!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _iconeSelecionado = null;
                                            });
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          padding: const EdgeInsets.all(4),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ElevatedButton.icon(
                                      onPressed: _selecionarIcone,
                                      icon: const Icon(
                                        Icons.swap_horiz,
                                        size: 16,
                                      ),
                                      label: const Text(
                                        'Trocar Ícone',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey[100],
                                        foregroundColor: Colors.grey[800],
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                    // ⚠️ Textinhos de validação visual continuam (não são SnackBar)
                    if (_imagemSelecionada == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '⚠️ Por favor, selecione uma imagem principal',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (_iconeSelecionado == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '⚠️ Por favor, selecione um ícone',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 11,
                          ),
                        ),
                      ),

                    // Botões
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
                          onPressed: _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulClaro,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text(
                            'Adicionar',
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
    );
  }

  Future<void> _selecionarImagem() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _imagemSelecionada = result.files.first;
        });

        // Preencher automaticamente o título se estiver vazio
        if (_tituloController.text.isEmpty) {
          _tituloController.text =
              _imagemSelecionada!.name.replaceAll(RegExp(r'\.[^.\s]+$'), '');
        }
      }
    } catch (e) {
      // ❌ antes era SnackBar; agora usa o alerta padrão
      await _mostrarAlerta('Erro ao selecionar imagem: $e', sucesso: false);
    }
  }

  Future<void> _selecionarIcone() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _iconeSelecionado = result.files.first;
        });
      }
    } catch (e) {
      // ❌ antes era SnackBar; agora usa o alerta padrão
      await _mostrarAlerta('Erro ao selecionar ícone: $e', sucesso: false);
    }
  }

  void _salvar() async {
    // ✅ validação com alerta padrão (sem SnackBar)
    if (_imagemSelecionada == null) {
      await _mostrarAlerta(
        'Por favor, selecione uma imagem principal',
        sucesso: false,
      );
      return;
    }

    if (_iconeSelecionado == null) {
      await _mostrarAlerta(
        'Por favor, selecione um ícone',
        sucesso: false,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      widget.onConfirm(
        _tituloController.text.trim(),
        _imagemSelecionada!,
        _iconeSelecionado!,
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    super.dispose();
  }
}
