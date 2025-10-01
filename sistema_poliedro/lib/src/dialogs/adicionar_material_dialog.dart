// dialogs/adicionar_material_dialog.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';

class AdicionarMaterialDialog extends StatefulWidget {
  final Function(
    String tipo,
    String titulo,
    String? descricao,
    String? url,
    double peso,
    DateTime? prazo,
    PlatformFile? arquivo,
  )
  onConfirm;

  const AdicionarMaterialDialog({super.key, required this.onConfirm});

  @override
  State<AdicionarMaterialDialog> createState() =>
      _AdicionarMaterialDialogState();
}

class _AdicionarMaterialDialogState extends State<AdicionarMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _urlController = TextEditingController();
  final _pesoController = TextEditingController(text: '0');

  String _tipoSelecionado = 'atividade';
  DateTime? _prazoSelecionado;
  PlatformFile? _arquivoSelecionado;

  final List<String> _tipos = ['atividade', 'pdf', 'imagem', 'link'];

  final Map<String, String> _nomesTipos = {
    'atividade': 'Atividade',
    'pdf': 'PDF',
    'imagem': 'Imagem',
    'link': 'Link',
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 40,
      ), // MENOS LARGO
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500), // LARGURA MÁXIMA
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20), // MENOS PADDING
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.add_circle,
                      color: AppColors.azulClaro,
                      size: 24,
                    ), // ÍCONE MENOR
                    const SizedBox(width: 8), // MENOS ESPAÇO
                    Text(
                      'Adicionar Material',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 18, // FONTE MENOR
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20), // MENOS ESPAÇO
                // Tipo
                DropdownButtonFormField<String>(
                  value: _tipoSelecionado,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Material*',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.category,
                      color: AppColors.azulClaro,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.azulClaro,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ), // MENOS ALTURA
                  ),
                  items: _tipos.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Text(_nomesTipos[tipo]!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _tipoSelecionado = value!;
                      _arquivoSelecionado = null;
                    });
                  },
                  validator: (value) {
                    if (value == null) return 'Selecione um tipo';
                    return null;
                  },
                ),
                const SizedBox(height: 12), // MENOS ESPAÇO
                // Título
                TextFormField(
                  controller: _tituloController,
                  decoration: InputDecoration(
                    labelText: 'Título*',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title, color: AppColors.azulClaro),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.azulClaro,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
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
                const SizedBox(height: 12),

                // Descrição
                TextFormField(
                  controller: _descricaoController,
                  decoration: InputDecoration(
                    labelText: 'Descrição (opcional)',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.description,
                      color: AppColors.azulClaro,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.azulClaro,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                // URL (apenas para tipo link)
                if (_tipoSelecionado == 'link')
                  TextFormField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'URL*',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link, color: AppColors.azulClaro),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.azulClaro,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(color: Colors.black),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    validator: _tipoSelecionado == 'link'
                        ? (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, insira uma URL';
                            }
                            return null;
                          }
                        : null,
                  ),
                if (_tipoSelecionado == 'link') const SizedBox(height: 12),

                // Upload de arquivo (para PDF e Imagem)
                if (_tipoSelecionado == 'pdf' || _tipoSelecionado == 'imagem')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Arquivo*',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.azulClaro,
                          fontSize: 14, // FONTE MENOR
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12), // MENOS PADDING
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.azulClaro.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            if (_arquivoSelecionado == null)
                              ElevatedButton.icon(
                                onPressed: _selecionarArquivo,
                                icon: const Icon(
                                  Icons.upload_file,
                                  size: 18,
                                ), // ÍCONE MENOR
                                label: const Text(
                                  'Selecionar Arquivo',
                                  style: TextStyle(fontSize: 14),
                                ), // TEXTO MENOR
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.azulClaro,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ), // MENOS PADDING
                                ),
                              )
                            else
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _tipoSelecionado == 'pdf'
                                            ? Icons.picture_as_pdf
                                            : Icons.image,
                                        color: AppColors.azulClaro,
                                        size: 20, // ÍCONE MENOR
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _arquivoSelecionado!.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14, // FONTE MENOR
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${(_arquivoSelecionado!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 11, // FONTE MENOR
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _arquivoSelecionado = null;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ), // ÍCONE MENOR
                                        padding: const EdgeInsets.all(
                                          4,
                                        ), // MENOS PADDING
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ElevatedButton.icon(
                                    onPressed: _selecionarArquivo,
                                    icon: const Icon(
                                      Icons.swap_horiz,
                                      size: 16,
                                    ), // ÍCONE MENOR
                                    label: const Text(
                                      'Trocar Arquivo',
                                      style: TextStyle(fontSize: 12),
                                    ), // TEXTO MENOR
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[100],
                                      foregroundColor: Colors.grey[800],
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ), // MENOS PADDING
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),

                // Peso
                TextFormField(
                  controller: _pesoController,
                  decoration: InputDecoration(
                    labelText: 'Peso (%)',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      Icons.assessment,
                      color: AppColors.azulClaro,
                    ),
                    suffixText: '%',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.azulClaro,
                        width: 2,
                      ),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final peso = double.tryParse(value);
                      if (peso == null || peso < 0 || peso > 100) {
                        return 'Peso deve ser entre 0 e 100';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Prazo
                InkWell(
                  onTap: _selecionarPrazo,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Prazo (opcional)',
                      border: const OutlineInputBorder(),
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: AppColors.azulClaro,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.azulClaro,
                          width: 2,
                        ),
                      ),
                      labelStyle: TextStyle(color: Colors.black),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _prazoSelecionado != null
                              ? '${_prazoSelecionado!.day}/${_prazoSelecionado!.month}/${_prazoSelecionado!.year} ${_prazoSelecionado!.hour}:${_prazoSelecionado!.minute.toString().padLeft(2, '0')}'
                              : 'Selecionar prazo',
                          style: const TextStyle(fontSize: 14), // TEXTO MENOR
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: AppColors.azulClaro,
                          size: 20,
                        ), // ÍCONE MENOR
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Validação de arquivo
                if ((_tipoSelecionado == 'pdf' ||
                        _tipoSelecionado == 'imagem') &&
                    _arquivoSelecionado == null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '⚠️ Por favor, selecione um arquivo',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 11, // FONTE MENOR
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
                        ), // MENOS PADDING
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontSize: 14),
                      ), // TEXTO MENOR
                    ),
                    const SizedBox(width: 8), // MENOS ESPAÇO
                    ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulClaro,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ), // MENOS PADDING
                      ),
                      child: const Text(
                        'Adicionar',
                        style: TextStyle(fontSize: 14),
                      ), // TEXTO MAIS CURTO
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

  // No método _selecionarPrazo do AdicionarMaterialDialog, atualize:
  Future<void> _selecionarPrazo() async {
    final DateTime? data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.azulClaro, // COR PRINCIPAL AZUL
              onPrimary: Colors.white, // COR DO TEXTO NO AZUL
              surface: Colors.white, // COR DE FUNDO
              onSurface: Colors.black, // COR DO TEXTO
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.azulClaro, // COR DOS BOTÕES
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (data != null) {
      final TimeOfDay? hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.azulClaro, // COR PRINCIPAL AZUL
                onPrimary: Colors.white, // COR DO TEXTO NO AZUL
                surface: Colors.white, // COR DE FUNDO
                onSurface: Colors.black, // COR DO TEXTO
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.azulClaro, // COR DOS BOTÕES
                ),
              ),
            ),
            child: child!,
          );
        },
      );

      if (hora != null) {
        setState(() {
          _prazoSelecionado = DateTime(
            data.year,
            data.month,
            data.day,
            hora.hour,
            hora.minute,
          );
        });
      }
    }
  }

  Future<void> _selecionarArquivo() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: _tipoSelecionado == 'pdf' ? FileType.custom : FileType.image,
        allowedExtensions: _tipoSelecionado == 'pdf'
            ? ['pdf']
            : ['jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _arquivoSelecionado = result.files.first;
        });

        // Preencher automaticamente o título se estiver vazio
        if (_tituloController.text.isEmpty) {
          _tituloController.text = _arquivoSelecionado!.name;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao selecionar arquivo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _salvar() {
    // Validação especial para arquivos
    if ((_tipoSelecionado == 'pdf' || _tipoSelecionado == 'imagem') &&
        _arquivoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecione um arquivo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      widget.onConfirm(
        _tipoSelecionado,
        _tituloController.text.trim(),
        _descricaoController.text.trim().isNotEmpty
            ? _descricaoController.text.trim()
            : null,
        _urlController.text.trim().isNotEmpty
            ? _urlController.text.trim()
            : null,
        double.tryParse(_pesoController.text) ?? 0,
        _prazoSelecionado,
        _arquivoSelecionado,
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _urlController.dispose();
    _pesoController.dispose();
    super.dispose();
  }
}
