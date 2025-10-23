import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../styles/cores.dart';
import '../styles/fontes.dart';

class EditarMaterialDialog extends StatefulWidget {
  final Function(
    String tipo,
    String titulo,
    String? descricao,
    String? url,
    double peso,
    DateTime? prazo,
    PlatformFile? arquivo, // Opcional para troca
  )
  onConfirm;

  final String tipo;
  final String titulo;
  final String? descricao;
  final String? url;
  final double peso;
  final DateTime? prazo;
  final String nomeArquivoAtual; // Para mostrar o atual

  const EditarMaterialDialog({
    super.key,
    required this.onConfirm,
    required this.tipo,
    required this.titulo,
    this.descricao,
    this.url,
    required this.peso,
    this.prazo,
    required this.nomeArquivoAtual,
  });

  @override
  State<EditarMaterialDialog> createState() => _EditarMaterialDialogState();
}

class _EditarMaterialDialogState extends State<EditarMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloController;
  late TextEditingController _descricaoController;
  late TextEditingController _urlController;
  late TextEditingController _pesoController;

  String _tipoSelecionado = '';
  DateTime? _prazoSelecionado;
  PlatformFile? _arquivoSelecionado;
  String? _nomeArquivoSelecionado; // Nome do arquivo selecionado
  bool _arquivoFoiAlterado = false; // Flag para controlar se o arquivo foi alterado

  final List<String> _tipos = ['atividade', 'pdf', 'imagem', 'link'];

  final Map<String, String> _nomesTipos = {
    'atividade': 'Atividade',
    'pdf': 'PDF',
    'imagem': 'Imagem',
    'link': 'Link',
  };

  @override
  void initState() {
    super.initState();
    _tipoSelecionado = widget.tipo;
    _tituloController = TextEditingController(text: widget.titulo);
    _descricaoController = TextEditingController(text: widget.descricao ?? '');
    _urlController = TextEditingController(text: widget.url ?? '');
    _pesoController = TextEditingController(text: widget.peso.toString());
    _prazoSelecionado = widget.prazo;
    _nomeArquivoSelecionado = widget.nomeArquivoAtual;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _urlController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

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
              primary: AppColors.azulClaro,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: AppColors.azulClaro),
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
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              // FORÇAR FORMATO 24 HORAS
              alwaysUse24HourFormat: true,
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.azulClaro,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
                textButtonTheme: TextButtonThemeData(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.azulClaro,
                  ),
                ),
              ),
              child: child!,
            ),
          );
        },
      );

      if (hora != null) {
        // CORREÇÃO: Criar DateTime com fuso horário local MAS enviar como se fosse UTC
        // Isso evita a conversão automática do Flutter
        final localDateTime = DateTime(
          data.year,
          data.month,
          data.day,
          hora.hour,
          hora.minute,
        );

        // IMPORTANTE: Não converter para UTC, enviar como local mas marcar como UTC
        // O backend vai tratar como UTC
        setState(() {
          _prazoSelecionado = localDateTime;
        });

        print(
          '=== DEBUG: Horário selecionado (local): ${localDateTime.toLocal()}',
        );
        print(
          '=== DEBUG: Horário para enviar: ${localDateTime.toIso8601String()}',
        );
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
          _nomeArquivoSelecionado = result.files.first.name;
          _arquivoFoiAlterado = true;
        });
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

  // Método para remover o arquivo selecionado
  void _removerArquivoSelecionado() {
    setState(() {
      _arquivoSelecionado = null;
      _nomeArquivoSelecionado = widget.nomeArquivoAtual;
      _arquivoFoiAlterado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

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
                              Icons.edit,
                              size: 32,
                              color: AppColors.azulClaro,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Editar Material',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Atualize as informações do material',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Tipo (readonly para simplificar, ou permita mudança se quiser)
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Tipo',
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
                      child: Text(_nomesTipos[_tipoSelecionado] ?? 'N/A'),
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
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'Por favor, insira um título'
                          : null,
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
                    // URL (se link)
                    if (_tipoSelecionado == 'link')
                      TextFormField(
                        controller: _urlController,
                        cursorColor: AppColors.azulClaro,
                        style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'URL',
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
                      ),
                    if (_tipoSelecionado == 'link') const SizedBox(height: 16),
                    // Peso (se atividade)
                    if (_tipoSelecionado == 'atividade')
                      TextFormField(
                        controller: _pesoController,
                        cursorColor: AppColors.azulClaro,
                        style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Peso (%)',
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
                          if (value == null || value.isEmpty) return null;
                          final peso = double.tryParse(value);
                          if (peso == null || peso < 0 || peso > 100) {
                            return 'Peso deve ser entre 0 e 100';
                          }
                          return null;
                        },
                      ),
                    if (_tipoSelecionado == 'atividade')
                      const SizedBox(height: 16),
                    // Prazo (se atividade)
                    if (_tipoSelecionado == 'atividade')
                      InkWell(
                        onTap: _selecionarPrazo,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Prazo',
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
                                    : 'Sem prazo',
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
                      const SizedBox(height: 16),
                    // Seção de arquivo - AGORA ATUALIZÁVEL
                    if (widget.tipo != 'link') ...[
                      Text(
                        _arquivoFoiAlterado ? 'Novo Arquivo:' : 'Arquivo:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _arquivoFoiAlterado ? Colors.green : AppColors.azulClaro,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _arquivoFoiAlterado 
                                ? Colors.green.withOpacity(0.5)
                                : AppColors.azulClaro.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getIconByType(widget.tipo),
                              color: _arquivoFoiAlterado ? Colors.green : AppColors.azulClaro,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _nomeArquivoSelecionado ?? widget.nomeArquivoAtual,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _arquivoFoiAlterado ? Colors.green : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    _arquivoFoiAlterado ? 'Arquivo novo selecionado' : 'Arquivo atual',
                                    style: TextStyle(
                                      color: _arquivoFoiAlterado ? Colors.green : Colors.grey[600],
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_arquivoFoiAlterado)
                              IconButton(
                                onPressed: _removerArquivoSelecionado,
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 18,
                                ),
                                padding: const EdgeInsets.all(4),
                                tooltip: 'Remover arquivo selecionado',
                              ),
                            IconButton(
                              onPressed: _selecionarArquivo,
                              icon: Icon(
                                _arquivoFoiAlterado ? Icons.swap_horiz : Icons.edit,
                                color: _arquivoFoiAlterado ? Colors.orange : AppColors.azulClaro,
                                size: 20,
                              ),
                              padding: const EdgeInsets.all(4),
                              tooltip: _arquivoFoiAlterado ? 'Trocar arquivo' : 'Editar arquivo',
                            ),
                          ],
                        ),
                      ),
                      if (_arquivoFoiAlterado) ...[
                        const SizedBox(height: 8),
                        Text(
                          '✓ Um novo arquivo foi selecionado e substituirá o atual ao salvar.',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
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
                            'Salvar',
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

  // Método auxiliar para obter ícone baseado no tipo
  IconData _getIconByType(String tipo) {
    switch (tipo) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'imagem':
        return Icons.image;
      case 'atividade':
        return Icons.assignment;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _salvar() {
    if (_formKey.currentState!.validate()) {
      // Se um arquivo foi selecionado, envia o novo arquivo
      // Se não foi selecionado nenhum arquivo, envia null (mantém o atual)
      PlatformFile? arquivoParaEnviar = _arquivoFoiAlterado ? _arquivoSelecionado : null;

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
        arquivoParaEnviar, // Null se não trocou, ou o novo arquivo se trocou
      );
      Navigator.pop(context);
    }
  }
}