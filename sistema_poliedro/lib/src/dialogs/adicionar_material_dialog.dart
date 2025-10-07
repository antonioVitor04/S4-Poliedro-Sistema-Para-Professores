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
                            'Adicionar Material',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Crie um novo material de estudo',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tipo
                    DropdownButtonFormField<String>(
                      value: _tipoSelecionado,
                      decoration: InputDecoration(
                        labelText: 'Tipo de Material*',
                        labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                          color: Colors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.preto.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.azulClaro,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: Icon(
                          Icons.category,
                          color: AppColors.azulClaro,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
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
                          if (value != 'atividade') {
                            _prazoSelecionado = null;
                            _pesoController.text = '0';
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) return 'Selecione um tipo';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Título
                    TextFormField(
                      controller: _tituloController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Título*',
                        labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                          color: Colors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.preto.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.azulClaro,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: Icon(
                          Icons.title,
                          color: AppColors.azulClaro,
                        ),
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

                    // Descrição
                    TextFormField(
                      controller: _descricaoController,
                      cursorColor: AppColors.azulClaro,
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Descrição (opcional)',
                        labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                          color: Colors.black,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.preto.withOpacity(0.1),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.azulClaro,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        prefixIcon: Icon(
                          Icons.description,
                          color: AppColors.azulClaro,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    // URL (apenas para tipo link)
                    if (_tipoSelecionado == 'link')
                      TextFormField(
                        controller: _urlController,
                        cursorColor: AppColors.azulClaro,
                        style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'URL*',
                          labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                            color: Colors.black,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.preto.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.azulClaro,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: Icon(
                            Icons.link,
                            color: AppColors.azulClaro,
                          ),
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
                    if (_tipoSelecionado == 'link') const SizedBox(height: 16),

                    // Upload de arquivo (para PDF, Imagem e Atividade)
                    if (_tipoSelecionado == 'pdf' ||
                        _tipoSelecionado == 'imagem' ||
                        _tipoSelecionado == 'atividade')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Arquivo*',
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
                                if (_arquivoSelecionado == null)
                                  ElevatedButton.icon(
                                    onPressed: _selecionarArquivo,
                                    icon: const Icon(
                                      Icons.upload_file,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _tipoSelecionado == 'atividade'
                                          ? 'Selecionar PDF'
                                          : 'Selecionar Arquivo',
                                      style: const TextStyle(fontSize: 14),
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
                                          Icon(
                                            _tipoSelecionado == 'pdf' ||
                                                    _tipoSelecionado ==
                                                        'atividade'
                                                ? Icons.picture_as_pdf
                                                : Icons.image,
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
                                                  _arquivoSelecionado!.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  '${(_arquivoSelecionado!.size / 1024 / 1024).toStringAsFixed(2)} MB',
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
                                                _arquivoSelecionado = null;
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
                                        onPressed: _selecionarArquivo,
                                        icon: const Icon(
                                          Icons.swap_horiz,
                                          size: 16,
                                        ),
                                        label: Text(
                                          _tipoSelecionado == 'atividade'
                                              ? 'Trocar PDF'
                                              : 'Trocar Arquivo',
                                          style: const TextStyle(fontSize: 12),
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

                    // Peso (apenas para atividade)
                    if (_tipoSelecionado == 'atividade')
                      TextFormField(
                        controller: _pesoController,
                        cursorColor: AppColors.azulClaro,
                        style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Peso (%) *',
                          labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                            color: Colors.black,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.preto.withOpacity(0.1),
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.azulClaro,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          prefixIcon: Icon(
                            Icons.assessment,
                            color: AppColors.azulClaro,
                          ),
                          suffixText: '%',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (_tipoSelecionado == 'atividade') {
                            if (value == null || value.isEmpty) {
                              return 'Peso é obrigatório para atividades';
                            }
                            final peso = double.tryParse(value);
                            if (peso == null || peso < 0 || peso > 100) {
                              return 'Peso deve ser entre 0 e 100';
                            }
                          }
                          return null;
                        },
                      ),
                    if (_tipoSelecionado == 'atividade')
                      const SizedBox(height: 16),

                    // Prazo (apenas para atividade)
                    if (_tipoSelecionado == 'atividade')
                      InkWell(
                        onTap: _selecionarPrazo,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Prazo *',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.black,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.preto.withOpacity(0.1),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.azulClaro,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            prefixIcon: Icon(
                              Icons.calendar_today,
                              color: AppColors.azulClaro,
                            ),
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
                                style: AppTextStyles.fonteUbuntu.copyWith(
                                  fontSize: 16,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.azulClaro,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_tipoSelecionado == 'atividade')
                      const SizedBox(height: 30),

                    // Validação de arquivo
                    if ((_tipoSelecionado == 'pdf' ||
                            _tipoSelecionado == 'imagem' ||
                            _tipoSelecionado == 'atividade') &&
                        _arquivoSelecionado == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '⚠️ Por favor, selecione um arquivo',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 11,
                          ),
                        ),
                      ),

                    // Validação de prazo para atividade
                    if (_tipoSelecionado == 'atividade' &&
                        _prazoSelecionado == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          '⚠️ Por favor, selecione um prazo',
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
      List<String>? allowedExtensions;
      FileType fileType = FileType.custom;

      if (_tipoSelecionado == 'pdf') {
        allowedExtensions = ['pdf'];
      } else if (_tipoSelecionado == 'atividade') {
        allowedExtensions = ['pdf'];
      } else if (_tipoSelecionado == 'imagem') {
        allowedExtensions = ['jpg', 'jpeg', 'png', 'gif'];
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowedExtensions: allowedExtensions,
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
    if ((_tipoSelecionado == 'pdf' ||
            _tipoSelecionado == 'imagem' ||
            _tipoSelecionado == 'atividade') &&
        _arquivoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecione um arquivo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validação especial para prazo em atividade
    if (_tipoSelecionado == 'atividade' && _prazoSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, selecione um prazo para a atividade'),
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
