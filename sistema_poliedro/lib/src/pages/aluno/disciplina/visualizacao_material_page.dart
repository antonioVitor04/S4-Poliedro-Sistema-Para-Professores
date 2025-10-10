// pages/material/visualizacao_material_page.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:typed_data';
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;

import '../../../services/material_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../styles/cores.dart';
import '../../../styles/fontes.dart';

class VisualizacaoMaterialPage extends StatefulWidget {
  final MaterialDisciplina material;
  final String topicoTitulo;
  final String topicoId;
  final String slug;

  const VisualizacaoMaterialPage({
    super.key,
    required this.material,
    required this.topicoTitulo,
    required this.topicoId,
    required this.slug,
  });

  @override
  State<VisualizacaoMaterialPage> createState() =>
      _VisualizacaoMaterialPageState();
}

class _VisualizacaoMaterialPageState extends State<VisualizacaoMaterialPage> {
  late Future<Uint8List?> _fileBytesFuture;

  @override
  void initState() {
    super.initState();
    print(
      '=== DEBUG INIT: Material ID=${widget.material.id}, Tipo=${widget.material.tipo}, HasArquivo=${widget.material.hasArquivo} ===',
    );

    if (widget.material.hasArquivo) {
      _fileBytesFuture =
          MaterialService.getFileBytes(
            slug: widget.slug,
            topicoId: widget.topicoId,
            materialId: widget.material.id,
          ).catchError((error) {
            print('=== DEBUG ERROR in getFileBytes: $error ===');
            return Future.value(null);
          });
    } else {
      _fileBytesFuture = Future.value(null);
    }
  }

  // Métodos para PDF
  Future<bool> _isPdfValid(Uint8List bytes) async {
    try {
      if (bytes.length < 10) return false;

      final header = String.fromCharCodes(bytes.sublist(0, 8));
      final hasValidHeader = header.contains('%PDF');

      print(
        '=== DEBUG PDF Validation: Header=$hasValidHeader, Size=${bytes.length} ===',
      );

      return hasValidHeader;
    } catch (e) {
      print('=== DEBUG ERRO validar PDF: $e ===');
      return false;
    }
  }

  // NOVO: Método universal para download
  Future<void> _downloadFileMobile(Uint8List bytes, String fileName, String mimeType) async {
    try {
      if (Platform.isAndroid) {
        await _downloadAndroid(bytes, fileName, mimeType);
      } else if (Platform.isIOS) {
        await _downloadIOS(bytes, fileName, mimeType);
      }
    } catch (e) {
      print('=== DEBUG ERRO download mobile: $e ===');
      _showError('Erro ao salvar arquivo: $e');
    }
  }

  // Método específico para Android
  Future<void> _downloadAndroid(Uint8List bytes, String fileName, String mimeType) async {
    try {
      // Solicitar permissão (Android 10+)
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _showError('Permissão de armazenamento necessária');
        return;
      }

      // Para Android 10+, usar getExternalStorageDirectory
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final folder = Directory('${directory.path}/Download');
        if (!await folder.exists()) {
          await folder.create(recursive: true);
        }
        
        final file = File('${folder.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Arquivo salvo em: Downloads/$fileName'),
            backgroundColor: AppColors.verdeConfirmacao,
          ),
        );
        
        // Tentar abrir o arquivo
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          print('=== DEBUG: Não foi possível abrir o arquivo automaticamente ===');
        }
      } else {
        _showError('Não foi possível acessar o armazenamento');
      }
    } catch (e) {
      print('=== DEBUG ERRO Android download: $e ===');
      _showError('Erro no Android: $e');
    }
  }

  // Método específico para iOS
  Future<void> _downloadIOS(Uint8List bytes, String fileName, String mimeType) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arquivo salvo com sucesso'),
          backgroundColor: AppColors.verdeConfirmacao,
        ),
      );
      
      // Abrir o arquivo
      final result = await OpenFile.open(file.path);
      if (result.type != ResultType.done) {
        print('=== DEBUG iOS: Resultado da abertura: $result ===');
      }
    } catch (e) {
      print('=== DEBUG ERRO iOS download: $e ===');
      _showError('Erro no iOS: $e');
    }
  }

  // MÉTODOS ESPECÍFICOS PARA WEB (serão chamados apenas se kIsWeb for true)
  void _downloadPdfWeb(Uint8List bytes, String fileName) {
    if (!kIsWeb) return;
    
    
    try {
      final base64Pdf = convert.base64Encode(bytes);
      final anchor =
          html.AnchorElement(href: 'data:application/pdf;base64,$base64Pdf')
            ..download = fileName
            ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download iniciado: $fileName'),
          backgroundColor: AppColors.verdeConfirmacao,
        ),
      );
    } catch (e) {
      print('=== DEBUG ERRO download web: $e ===');
      _showError('Erro ao fazer download');
    }
  }

  void _downloadImageWeb(Uint8List? bytes, String? url, String fileName) {
    if (!kIsWeb) return;
    

    
    try {
      if (bytes != null) {
        final base64Image = convert.base64Encode(bytes);
        final anchor =
            html.AnchorElement(href: 'data:image/jpeg;base64,$base64Image')
              ..download = fileName
              ..style.display = 'none';

        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
      } else if (url != null && url.isNotEmpty) {
        final anchor = html.AnchorElement(href: url)
          ..download = fileName
          ..style.display = 'none';

        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download iniciado: ${widget.material.titulo}'),
          backgroundColor: AppColors.verdeConfirmacao,
        ),
      );
    } catch (e) {
      print('=== DEBUG ERRO download imagem web: $e ===');
      _showError('Erro ao fazer download da imagem');
    }
  }

  void _openPdfInNewTabWeb(Uint8List bytes) {
    if (!kIsWeb) return;
    

    try {
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..target = '_blank'
        ..rel = 'noopener noreferrer'
        ..style.display = 'none';

      html.document.body?.append(anchor);
      anchor.click();

      Future.delayed(Duration(seconds: 1), () {
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      });

      print('=== DEBUG: PDF aberto com Blob URL ===');
    } catch (e) {
      print('=== DEBUG ERRO Blob URL: $e ===');
      _tryAlternativePdfOpenWeb(bytes);
    }
  }

  void _tryAlternativePdfOpenWeb(Uint8List bytes) {
    if (!kIsWeb) return;
    
    try {
      final base64Pdf = convert.base64Encode(bytes);
      final pdfUrl = 'data:application/pdf;base64,$base64Pdf';
      final window = html.window.open(pdfUrl, '_blank');
    } catch (e2) {
      print('=== DEBUG ERRO Data URL: $e2 ===');
      _showOpenPdfDialogWeb(bytes);
    }
  }

  void _showOpenPdfDialogWeb(Uint8List bytes) {
    final corPrincipal = _getMaterialColor(widget.material.tipo);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Abrir PDF', style: AppTextStyles.fonteUbuntu),
        content: Text(
          'O navegador bloqueou a abertura automática do PDF. Clique no botão abaixo para abrir manualmente.',
          style: AppTextStyles.fonteUbuntuSans,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: AppTextStyles.fonteUbuntuSans),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: corPrincipal,
              foregroundColor: AppColors.branco,
            ),
            onPressed: () {
              Navigator.pop(context);
              _forceOpenPdfWeb(bytes);
            },
            child: Text('Abrir PDF', style: AppTextStyles.fonteUbuntuSans),
          ),
        ],
      ),
    );
  }

  void _forceOpenPdfWeb(Uint8List bytes) {
    if (!kIsWeb) return;

    
    try {
      final base64Pdf = convert.base64Encode(bytes);
      final pdfUrl = 'data:application/pdf;base64,$base64Pdf';
      final anchor = html.AnchorElement(href: pdfUrl)
        ..target = '_blank'
        ..text = 'Abrir PDF'
        ..style.position = 'absolute'
        ..style.left = '0'
        ..style.top = '0';

      html.document.body?.append(anchor);
      anchor.click();

      Future.delayed(Duration(seconds: 2), () {
        anchor.remove();
      });
    } catch (e) {
      _showError(
        'Não foi possível abrir o PDF. Faça o download e abra manualmente.',
      );
    }
  }

  void _openLinkInNewTabWeb(String url) {
    if (!kIsWeb) return;

    html.window.open(url, '_blank');
  }

  Widget _buildPdfWeb(Uint8List bytes) {
    if (kIsWeb) {
      return _buildPdfIframe(bytes);
    } else {
      return _buildPdfMobile(bytes);
    }
  }

  Widget _buildPdfIframe(Uint8List bytes) {
    try {
      print('=== DEBUG: Criando alternativa para PDF ===');

      final base64Pdf = convert.base64Encode(bytes);
      final pdfDataUrl = 'data:application/pdf;base64,$base64Pdf';

      final corIcone = _getMaterialColor(widget.material.tipo);
      final tipoDisplay = _getTipoNome(widget.material.tipo);
      final downloadText = widget.material.tipo == 'atividade'
          ? 'Fazer Download da Atividade'
          : 'Fazer Download do PDF';
      final openText = widget.material.tipo == 'atividade'
          ? 'Abrir Atividade em Nova Aba'
          : 'Abrir PDF em Nova Aba';

      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.grey[100],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$tipoDisplay: ${widget.material.titulo}',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.open_in_new,
                          size: 20,
                          color: AppColors.azulClaro,
                        ),
                        onPressed: () => _openPdfInNewTab(bytes),
                        tooltip: 'Abrir em nova aba',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.download,
                          size: 20,
                          color: AppColors.azulClaro,
                        ),
                        onPressed: () => _downloadPdf(bytes),
                        tooltip: 'Fazer download',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getMaterialIconData(widget.material.tipo),
                      size: 64,
                      color: corIcone,
                    ),
                    SizedBox(height: 16),
                    Text(
                      '$tipoDisplay carregado com sucesso',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tamanho: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulClaro,
                        foregroundColor: AppColors.branco,
                      ),
                      onPressed: () => _openPdfInNewTab(bytes),
                      icon: Icon(
                        Icons.open_in_new,
                        color: AppColors.branco,
                      ),
                      label: Text(
                        openText,
                        style: AppTextStyles.fonteUbuntuSans,
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.azulClaro,
                        side: BorderSide(color: AppColors.azulClaro),
                      ),
                      onPressed: () => _downloadPdf(bytes),
                      icon: Icon(
                        Icons.download,
                        color: AppColors.azulClaro,
                      ),
                      label: Text(
                        downloadText,
                        style: AppTextStyles.fonteUbuntuSans,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      print('=== DEBUG ERRO alternativa PDF: $e ===');
      return _buildPdfFallback(bytes, 'Erro: $e');
    }
  }

  // NOVO: Widget para PDF no mobile
  Widget _buildPdfMobile(Uint8List bytes) {
    final corIcone = _getMaterialColor(widget.material.tipo);
    final tipoDisplay = _getTipoNome(widget.material.tipo);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '$tipoDisplay: ${widget.material.titulo}',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getMaterialIconData(widget.material.tipo),
                    size: isMobile ? 48 : 64,
                    color: corIcone,
                  ),
                  SizedBox(height: isMobile ? 12 : 16),
                  Text(
                    '$tipoDisplay disponível',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: isMobile ? 16 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  Text(
                    'Tamanho: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
                    style: AppTextStyles.fonteUbuntuSans.copyWith(
                      color: Colors.grey,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                  SizedBox(height: isMobile ? 20 : 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulClaro,
                      foregroundColor: AppColors.branco,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 16 : 20,
                        vertical: isMobile ? 12 : 16,
                      ),
                    ),
                    onPressed: () => _downloadPdf(bytes),
                    icon: Icon(
                      Icons.download, 
                      size: isMobile ? 18 : 20,
                      color: AppColors.branco,
                    ),
                    label: Text(
                      'Baixar e Abrir',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                  SizedBox(height: isMobile ? 10 : 12),
                  if (widget.material.tipo == 'atividade')
                    Text(
                      'A atividade será salva e aberta automaticamente',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        color: Colors.grey,
                        fontSize: isMobile ? 12 : 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // MÉTODOS PRINCIPAIS QUE CHAMAM AS VERSÕES WEB/MOBILE
  void _downloadPdf(Uint8List bytes) {
    final fileName = '${_sanitizeFileName(widget.material.titulo)}.pdf';
    
    if (kIsWeb) {
      _downloadPdfWeb(bytes, fileName);
    } else {
      _downloadFileMobile(bytes, fileName, 'application/pdf');
    }
  }

  void _downloadImage(Uint8List? bytes, String? url) {
    final fileName = '${_sanitizeFileName(widget.material.titulo)}.jpg';
    
    if (kIsWeb) {
      _downloadImageWeb(bytes, url, fileName);
    } else if (bytes != null) {
      _downloadFileMobile(bytes, fileName, 'image/jpeg');
    } else {
      _showError('Imagem não disponível para download');
    }
  }

  void _openPdfInNewTab(Uint8List bytes) {
    if (kIsWeb) {
      _openPdfInNewTabWeb(bytes);
    } else {
      // No mobile, fazer download
      _downloadPdf(bytes);
    }
  }

  void _openLinkInNewTab(String url) {
    if (kIsWeb) {
      _openLinkInNewTabWeb(url);
    } else {
      // No mobile, mostrar mensagem
      _showError('Funcionalidade disponível apenas na versão web');
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.fonteUbuntuSans),
        backgroundColor: AppColors.vermelhoErro,
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline, 
            size: isMobile ? 48 : 64, 
            color: AppColors.vermelhoErro
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            message,
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: isMobile ? 16 : 18,
              color: AppColors.vermelhoErro,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    try {
      return Scaffold(
        backgroundColor: AppColors.branco,
        appBar: AppBar(
          title: Text(
            widget.material.titulo,
            style: AppTextStyles.fonteUbuntu.copyWith(
              color: AppColors.branco,
              fontSize: isMobile ? 16 : 18,
            ),
          ),
          backgroundColor: AppColors.azulClaro,
          foregroundColor: AppColors.branco,
          actions: [],
        ),
        body: Padding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tópico: ${widget.topicoTitulo}',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          color: Colors.grey,
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                      SizedBox(height: isMobile ? 6 : 8),
                      Text(
                        widget.material.titulo,
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: isMobile ? 20 : 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.material.descricao != null) ...[
                        SizedBox(height: isMobile ? 8 : 12),
                        Text(
                          widget.material.descricao!,
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                      ],
                      if (widget.material.prazo != null) ...[
                        SizedBox(height: isMobile ? 8 : 12),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: widget.material.prazo!.isBefore(DateTime.now())
                                  ? AppColors.vermelhoErro
                                  : AppColors.vermelho,
                              size: isMobile ? 16 : 18,
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.material.prazo!.isBefore(DateTime.now())
                                    ? 'Prazo Expirado: ${_formatarData(widget.material.prazo!)}'
                                    : 'Prazo: ${_formatarData(widget.material.prazo!)}',
                                style: AppTextStyles.fonteUbuntuSans.copyWith(
                                  color: widget.material.prazo!.isBefore(DateTime.now())
                                      ? AppColors.vermelhoErro
                                      : AppColors.vermelho,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.material.peso > 0) ...[
                        SizedBox(height: isMobile ? 6 : 8),
                        Row(
                          children: [
                            Icon(
                              Icons.assessment,
                              color: AppColors.azulClaro,
                              size: isMobile ? 16 : 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Peso: ${widget.material.peso}%',
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                color: AppColors.azulClaro,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? 14 : 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: isMobile ? 6 : 8),
                      Row(
                        children: [
                          Icon(
                            _getMaterialIconData(widget.material.tipo),
                            color: _getMaterialColor(widget.material.tipo),
                            size: isMobile ? 16 : 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            _getTipoNome(widget.material.tipo),
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              color: Colors.grey[600],
                              fontSize: isMobile ? 14 : 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Expanded(
                child: FutureBuilder<Uint8List?>(
                  future: _fileBytesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.azulClaro,
                              ),
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              'Carregando material...',
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                fontSize: isMobile ? 14 : 16,
                                color: AppColors.azulClaro,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error,
                              size: isMobile ? 48 : 64,
                              color: AppColors.vermelhoErro,
                            ),
                            SizedBox(height: isMobile ? 12 : 16),
                            Text(
                              'Erro ao carregar arquivo',
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                fontSize: isMobile ? 16 : 18,
                                color: AppColors.vermelhoErro,
                              ),
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: isMobile ? 12 : 14,
                              ),
                            ),
                            SizedBox(height: isMobile ? 16 : 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azulClaro,
                                foregroundColor: AppColors.branco,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 16 : 20,
                                  vertical: isMobile ? 12 : 16,
                                ),
                              ),
                              onPressed: () => setState(() {
                                _fileBytesFuture = MaterialService.getFileBytes(
                                  slug: widget.slug,
                                  topicoId: widget.topicoId,
                                  materialId: widget.material.id,
                                );
                              }),
                              child: Text(
                                'Tentar Novamente',
                                style: AppTextStyles.fonteUbuntuSans.copyWith(
                                  fontSize: isMobile ? 14 : 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final bytes = snapshot.data;
                    return _buildConteudoMaterial(context, bytes);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('=== DEBUG ERRO GLOBAL no BUILD: $e\nStack: $stackTrace ===');
      return Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bug_report, 
                size: isMobile ? 48 : 64, 
                color: AppColors.vermelhoErro
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Erro crítico',
                style: AppTextStyles.fonteUbuntuSans.copyWith(
                  fontSize: isMobile ? 16 : 18,
                  color: AppColors.vermelhoErro,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Recarregue a página',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: isMobile ? 12 : 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day}/${data.month}/${data.year} às ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
  }

  Color _getMaterialColor(String tipo) {
    switch (tipo) {
      case 'pdf':
        return AppColors.vermelho;
      case 'imagem':
        return AppColors.verdeConfirmacao;
      case 'link':
        return AppColors.azulClaro;
      case 'atividade':
        return AppColors.amarelo;
      default:
        return Colors.grey;
    }
  }

  IconData _getMaterialIconData(String tipo) {
    switch (tipo) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'imagem':
        return Icons.image;
      case 'link':
        return Icons.link;
      case 'atividade':
        return Icons.assignment;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _getTipoNome(String tipo) {
    switch (tipo) {
      case 'pdf':
        return 'Documento PDF';
      case 'imagem':
        return 'Imagem';
      case 'link':
        return 'Link Externo';
      case 'atividade':
        return 'Atividade';
      default:
        return 'Material';
    }
  }

  Widget _buildConteudoMaterial(BuildContext context, Uint8List? bytes) {
    print(
      '=== DEBUG Conteúdo: Tipo=${widget.material.tipo}, URL=${widget.material.url}, Bytes=${bytes?.length} ===',
    );

    switch (widget.material.tipo) {
      case 'imagem':
        return _buildImageContainer(bytes, widget.material.url);

      case 'pdf':
        print('=== DEBUG: Renderizando PDF - Bytes: ${bytes?.length} ===');
        if (bytes == null || bytes.isEmpty) {
          return _buildErrorWidget('PDF não disponível');
        }
        return FutureBuilder<bool>(
          future: _isPdfValid(bytes),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasData == true && snapshot.data!) {
              return _buildPdfWeb(bytes);
            } else {
              return _buildPdfFallback(bytes, 'PDF inválido ou corrompido');
            }
          },
        );

      case 'link':
        print('=== DEBUG: Renderizando link ===');
        return _buildLinkContainer(widget.material.url);

      case 'atividade':
        print('=== DEBUG: Renderizando atividade ===');
        return _buildAtividadeContainer(bytes);

      default:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Tipo de material não suportado: ${widget.material.tipo}',
                style: AppTextStyles.fonteUbuntuSans.copyWith(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildImageContainer(Uint8List? bytes, String? url) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    Widget imageWidget;
    if (url != null && url.isNotEmpty) {
      print('=== DEBUG: Carregando imagem de URL ===');
      imageWidget = Image.network(
        url,
        fit: BoxFit.contain,
        height: isMobile ? 
          MediaQuery.of(context).size.height * 0.3 : 
          MediaQuery.of(context).size.height * 0.4,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: AppColors.azulClaro),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('=== DEBUG ERRO imagem URL: $error ===');
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Erro ao carregar imagem',
                style: TextStyle(color: AppColors.vermelhoErro),
              ),
            ],
          );
        },
      );
    } else if (bytes != null) {
      print('=== DEBUG: Carregando imagem de bytes ===');
      imageWidget = Image.memory(
        bytes,
        fit: BoxFit.contain,
        height: isMobile ? 
          MediaQuery.of(context).size.height * 0.3 : 
          MediaQuery.of(context).size.height * 0.4,
        errorBuilder: (context, error, stackTrace) {
          print('=== DEBUG ERRO imagem memory: $error ===');
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Erro na imagem',
                style: TextStyle(color: AppColors.vermelhoErro),
              ),
            ],
          );
        },
      );
    } else {
      print('=== DEBUG: Sem imagem disponível ===');
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Imagem não disponível',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return Container(
      height: isMobile ? 
        MediaQuery.of(context).size.height * 0.6 : 
        MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Imagem: ${widget.material.titulo}',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isMobile)
                  IconButton(
                    icon: Icon(Icons.download, size: 20, color: AppColors.azulClaro),
                    onPressed: () => _downloadImage(bytes, url),
                    tooltip: 'Fazer download',
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 16.0 : 24.0),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageWidget,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: isMobile ? 12.0 : 16.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.azulClaro,
                side: BorderSide(color: AppColors.azulClaro),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 10 : 12,
                ),
              ),
              onPressed: () => _downloadImage(bytes, url),
              icon: Icon(
                Icons.download,
                color: AppColors.azulClaro,
                size: isMobile ? 18 : 20,
              ),
              label: Text(
                'Fazer Download',
                style: AppTextStyles.fonteUbuntuSans.copyWith(
                  fontSize: isMobile ? 14 : 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkContainer(String? url) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    if (url == null || url.isEmpty) {
      return _buildErrorWidget('URL não disponível');
    }

    final corIcone = _getMaterialColor(widget.material.tipo);

    return Container(
      height: isMobile ? 
        MediaQuery.of(context).size.height * 0.6 : 
        MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Link: ${widget.material.titulo}',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isMobile)
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.open_in_new, size: 20, color: AppColors.azulClaro),
                        onPressed: () => _openLinkInNewTab(url),
                        tooltip: 'Abrir em nova aba',
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, size: 20, color: AppColors.azulClaro),
                        onPressed: () => _copyLink(url),
                        tooltip: 'Copiar link',
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link, size: isMobile ? 48 : 64, color: corIcone),
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Link Externo',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: isMobile ? 18 : 20,
                      ),
                    ),
                    SizedBox(height: isMobile ? 12 : 16),
                    Container(
                      padding: EdgeInsets.all(isMobile ? 12 : 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        url,
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: isMobile ? 12 : 14,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 20 : 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulClaro,
                        foregroundColor: AppColors.branco,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 12 : 16,
                        ),
                      ),
                      onPressed: () => _openLinkInNewTab(url),
                      icon: Icon(
                        Icons.open_in_new, 
                        size: isMobile ? 18 : 20,
                        color: AppColors.branco
                      ),
                      label: Text(
                        'Abrir Link',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 10 : 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.azulClaro,
                        side: BorderSide(color: AppColors.azulClaro),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 10 : 12,
                        ),
                      ),
                      onPressed: () => _copyLink(url),
                      icon: Icon(
                        Icons.copy, 
                        size: isMobile ? 18 : 20,
                        color: AppColors.azulClaro
                      ),
                      label: Text(
                        'Copiar Link',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Link copiado para a área de transferência',
          style: AppTextStyles.fonteUbuntuSans,
        ),
        backgroundColor: AppColors.verdeConfirmacao,
      ),
    );
  }

  Widget _buildAtividadeContainer(Uint8List? bytes) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    bool isPastDue =
        widget.material.prazo != null &&
        widget.material.prazo!.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 10 : 12),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Atividade: ${widget.material.titulo}',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Título: ${widget.material.titulo}',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontSize: isMobile ? 16 : 18
                    ),
                  ),
                  if (widget.material.descricao != null) ...[
                    SizedBox(height: isMobile ? 12 : 16),
                    Text(
                      'Descrição:',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.material.descricao!,
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ],
                  if (widget.material.prazo != null) ...[
                    SizedBox(height: isMobile ? 12 : 16),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: isMobile ? 16 : 18,
                          color: isPastDue
                              ? AppColors.vermelhoErro
                              : AppColors.azulClaro,
                        ),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isPastDue
                                ? 'Prazo Expirado: ${_formatarData(widget.material.prazo!)}'
                                : 'Prazo: ${_formatarData(widget.material.prazo!)}',
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              fontSize: isMobile ? 14 : 16,
                              color: isPastDue
                                  ? AppColors.vermelhoErro
                                  : AppColors.azulClaro,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (widget.material.peso > 0) ...[
                    SizedBox(height: isMobile ? 8 : 12),
                    Row(
                      children: [
                        Icon(
                          Icons.assessment,
                          size: isMobile ? 16 : 18,
                          color: AppColors.azulClaro,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Peso: ${widget.material.peso}%',
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: isMobile ? 14 : 16,
                            color: AppColors.azulClaro,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (bytes != null && bytes.isNotEmpty) ...[
                    SizedBox(height: isMobile ? 16 : 24),
                    Text(
                      'Arquivo Anexado:',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: isMobile ? 8 : 12),
                    FutureBuilder<bool>(
                      future: _isPdfValid(bytes),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasData == true && snapshot.data!) {
                          return _buildPdfWeb(bytes);
                        } else {
                          return _buildPdfFallback(bytes);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfFallback(Uint8List bytes, [String? reason]) {
    final corIcone = _getMaterialColor(widget.material.tipo);
    final tipoDisplay = _getTipoNome(widget.material.tipo);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getMaterialIconData(widget.material.tipo),
            size: isMobile ? 48 : 64,
            color: corIcone,
          ),
          SizedBox(height: isMobile ? 12 : 16),
          Text(
            'Visualizador de $tipoDisplay',
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            'Use o botão abaixo para baixar o $tipoDisplay',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: isMobile ? 14 : 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (reason != null) ...[
            SizedBox(height: 8),
            Text(
              reason,
              style: TextStyle(color: Colors.red, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
          SizedBox(height: isMobile ? 20 : 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulClaro,
              foregroundColor: AppColors.branco,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 20,
                vertical: isMobile ? 12 : 16,
              ),
            ),
            onPressed: () => _downloadPdf(bytes),
            icon: Icon(Icons.download, color: AppColors.branco),
            label: Text(
              'Baixar $tipoDisplay',
              style: AppTextStyles.fonteUbuntuSans,
            ),
          ),
        ],
      ),
    );
  }
}