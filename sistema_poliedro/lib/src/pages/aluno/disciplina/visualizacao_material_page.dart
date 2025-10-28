// pages/material/visualizacao_material_page.dart
import 'package:flutter/material.dart';
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:universal_html/html.dart' as html;
import '../../../services/permission_service.dart';
import '../../../services/material_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../styles/cores.dart';
import '../../../styles/fontes.dart';
import '../../../services/comentario_service.dart';
import '../../../models/modelo_comentario.dart';

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

  /// Controller do chat para badge/integração externa (se quiser usar fora)
  final CommentsController _chatController = CommentsController();

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
  Future<void> _downloadFileMobile(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      if (Platform.isAndroid) {
        await _downloadAndroid(bytes, fileName, mimeType);
      }
    } catch (e) {
      print('=== DEBUG ERRO download mobile: $e ===');
      _showError('Erro ao salvar arquivo: $e');
    }
  }

  // Método específico para Android - VERSÃO CORRIGIDA
  Future<void> _downloadAndroid(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      print('=== DEBUG: Iniciando download no Android ===');
      print('=== DEBUG: Nome do arquivo: $fileName ===');
      print('=== DEBUG: Tamanho: ${bytes.length} bytes ===');

      // SOLICITAÇÃO DE PERMISSÃO MELHORADA
      final hasPermission = await PermissionService.requestStoragePermissions();

      if (!hasPermission) {
        _showError(
          'Permissão de armazenamento necessária para salvar o arquivo',
        );
        return;
      }

      // Estratégia de fallback para diferentes versões do Android
      Directory? directory;

      // Tentar usar o diretório de downloads primeiro
      directory = await getDownloadsDirectory();

      // Se não conseguir, tentar diretório externo
      if (directory == null) {
        directory = await getExternalStorageDirectory();
      }

      // Se ainda não conseguir, usar diretório de documentos
      if (directory == null) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory != null) {
        // Criar subpasta "SistemaPoliedro" para organizar melhor
        final folder = Directory('${directory.path}/SistemaPoliedro');
        if (!await folder.exists()) {
          await folder.create(recursive: true);
        }

        final file = File('${folder.path}/$fileName');
        await file.writeAsBytes(bytes);

        print('=== DEBUG: Arquivo salvo em: ${file.path} ===');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Download concluído!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Arquivo salvo em: SistemaPoliedro/',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: AppColors.verdeConfirmacao,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Abrir',
              textColor: Colors.white,
              onPressed: () async {
                final result = await OpenFile.open(file.path);
                if (result.type != ResultType.done) {
                  _showFileLocationDialog(file.path);
                }
              },
            ),
          ),
        );

        // Tentar abrir o arquivo automaticamente
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          print(
            '=== DEBUG: Não foi possível abrir o arquivo automaticamente ===',
          );
          print('=== DEBUG: Resultado: $result ===');
        }
      } else {
        _showError('Não foi possível acessar o armazenamento do dispositivo');
      }
    } catch (e) {
      print('=== DEBUG ERRO Android download: $e ===');
      _showError('Erro ao salvar arquivo: $e');
    }
  }

  // Diálogo para mostrar local do arquivo
  void _showFileLocationDialog(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Download Concluído', style: AppTextStyles.fonteUbuntu),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'O arquivo foi salvo em:',
              style: AppTextStyles.fonteUbuntuSans,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                filePath,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Você pode abri-lo manualmente usando um app de arquivos.',
              style: AppTextStyles.fonteUbuntuSans.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: AppTextStyles.fonteUbuntuSans),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              OpenFile.open(filePath);
            },
            child: Text('Abrir Local', style: AppTextStyles.fonteUbuntuSans),
          ),
        ],
      ),
    );
  }

  // Diálogo para quando a permissão é negada permanentemente
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permissão Necessária', style: AppTextStyles.fonteUbuntu),
        content: Text(
          'Para salvar arquivos no seu dispositivo, é necessário conceder permissão de armazenamento. '
          'Você será redirecionado para as configurações do aplicativo.',
          style: AppTextStyles.fonteUbuntuSans,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: AppTextStyles.fonteUbuntuSans),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              PermissionService.openAppSettings();
            },
            child: Text(
              'Abrir Configurações',
              style: AppTextStyles.fonteUbuntuSans,
            ),
          ),
        ],
      ),
    );
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

      Future.delayed(const Duration(seconds: 1), () {
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
      html.window.open(pdfUrl, '_blank');
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

      Future.delayed(const Duration(seconds: 2), () {
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
              padding: const EdgeInsets.all(8),
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
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 20,
                          color: AppColors.azulClaro,
                        ),
                        onPressed: () => _openPdfInNewTab(bytes),
                        tooltip: 'Abrir em nova aba',
                      ),
                      IconButton(
                        icon: const Icon(
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
                    const SizedBox(height: 16),
                    Text(
                      '$tipoDisplay carregado com sucesso',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tamanho: ${(bytes.length / 1024).toStringAsFixed(1)} KB',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.azulClaro,
                        foregroundColor: AppColors.branco,
                      ),
                      onPressed: () => _openPdfInNewTab(bytes),
                      icon: const Icon(
                        Icons.open_in_new,
                        color: AppColors.branco,
                      ),
                      label: Text(
                        openText,
                        style: AppTextStyles.fonteUbuntuSans,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.azulClaro,
                        side: const BorderSide(color: AppColors.azulClaro),
                      ),
                      onPressed: () => _downloadPdf(bytes),
                      icon: const Icon(
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
                    icon: const Icon(
                      Icons.download,
                      size: 20,
                      color: AppColors.branco,
                    ),
                    label: Text(
                      'Baixar e Abrir',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        fontSize: isMobile ? 14 : 16,
                      ),
                    ),
                  ),
                  if (widget.material.tipo == 'atividade') ...[
                    SizedBox(height: isMobile ? 10 : 12),
                    Text(
                      'A atividade será salva e aberta automaticamente',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        color: Colors.grey,
                        fontSize: isMobile ? 12 : 14,
                      ),
                      textAlign: TextAlign.center,
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
      _downloadPdf(bytes);
    }
  }

  void _openLinkInNewTab(String url) {
    if (kIsWeb) {
      _openLinkInNewTabWeb(url);
    } else {
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
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.vermelhoErro,
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
          actions: const [],
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
                              color:
                                  widget.material.prazo!.isBefore(
                                    DateTime.now(),
                                  )
                                  ? AppColors.vermelhoErro
                                  : AppColors.vermelho,
                              size: isMobile ? 16 : 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.material.prazo!.isBefore(DateTime.now())
                                    ? 'Prazo Expirado: ${_formatarData(widget.material.prazo!)}'
                                    : 'Prazo: ${_formatarData(widget.material.prazo!)}',
                                style: AppTextStyles.fonteUbuntuSans.copyWith(
                                  color:
                                      widget.material.prazo!.isBefore(
                                        DateTime.now(),
                                      )
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
                            const Icon(
                              Icons.assessment,
                              color: AppColors.azulClaro,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
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
                          const SizedBox(width: 6),
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

              /// ====== LAYOUT RESPONSIVO COM O CHAT ======
              Expanded(
                child: LayoutBuilder(
                  builder: (context, cts) {
                    final isWide = cts.maxWidth >= 960;

                    if (!isWide) {
                      // Empilhado (material em cima, chat abaixo)
                      return Column(
                        children: [
                          Expanded(
                            flex: 6,
                            child: FutureBuilder<Uint8List?>(
                              future: _fileBytesFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppColors.azulClaro,
                                              ),
                                        ),
                                        SizedBox(height: isMobile ? 12 : 16),
                                        Text(
                                          'Carregando material...',
                                          style: AppTextStyles.fonteUbuntuSans
                                              .copyWith(
                                                fontSize: isMobile ? 14 : 16,
                                                color: AppColors.azulClaro,
                                              ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return _buildErrorWidget(
                                    'Erro ao carregar arquivo',
                                  );
                                }
                                final bytes = snapshot.data;
                                return _buildConteudoMaterial(context, bytes);
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 420,
                            child: CommentsPanel(
                              materialId: widget.material.id,
                              topicoId: widget.topicoId,
                              disciplinaId: widget.slug,
                              title: 'Comentários',
                              controller:
                                  _chatController, // <- controller plugado
                              showHeaderBadge:
                                  false, // badge só fora do painel se quiser
                            ),
                          ),
                        ],
                      );
                    }

                    // Duas colunas (material à esquerda, chat à direita)
                    return Row(
                      children: [
                        Expanded(
                          flex: 7,
                          child: FutureBuilder<Uint8List?>(
                            future: _fileBytesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.azulClaro,
                                            ),
                                      ),
                                      SizedBox(height: isMobile ? 12 : 16),
                                      Text(
                                        'Carregando material...',
                                        style: AppTextStyles.fonteUbuntuSans
                                            .copyWith(
                                              fontSize: isMobile ? 14 : 16,
                                              color: AppColors.azulClaro,
                                            ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              if (snapshot.hasError) {
                                return _buildErrorWidget(
                                  'Erro ao carregar arquivo',
                                );
                              }
                              final bytes = snapshot.data;
                              return _buildConteudoMaterial(context, bytes);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 360,
                          child: CommentsPanel(
                            materialId: widget.material.id,
                            topicoId: widget.topicoId,
                            disciplinaId: widget.slug,
                            title: 'Comentários',
                            controller: _chatController,
                          ),
                        ),
                      ],
                    );
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
              const Icon(
                Icons.bug_report,
                size: 64,
                color: AppColors.vermelhoErro,
              ),
              SizedBox(height: isMobile ? 12 : 16),
              Text(
                'Erro crítico',
                style: AppTextStyles.fonteUbuntuSans.copyWith(
                  fontSize: isMobile ? 16 : 18,
                  color: AppColors.vermelhoErro,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Recarregue a página',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
              return const Center(child: CircularProgressIndicator());
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
              const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
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
        height: isMobile
            ? MediaQuery.of(context).size.height * 0.3
            : MediaQuery.of(context).size.height * 0.4,
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
            children: const [
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
        height: isMobile
            ? MediaQuery.of(context).size.height * 0.3
            : MediaQuery.of(context).size.height * 0.4,
        errorBuilder: (context, error, stackTrace) {
          print('=== DEBUG ERRO imagem memory: $error ===');
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
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
          const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
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
      height: isMobile
          ? MediaQuery.of(context).size.height * 0.6
          : MediaQuery.of(context).size.height * 0.7,
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
                    icon: const Icon(
                      Icons.download,
                      size: 20,
                      color: AppColors.azulClaro,
                    ),
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
                side: const BorderSide(color: AppColors.azulClaro),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 20,
                  vertical: isMobile ? 10 : 12,
                ),
              ),
              onPressed: () => _downloadImage(bytes, url),
              icon: const Icon(
                Icons.download,
                color: AppColors.azulClaro,
                size: 20,
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
      height: isMobile
          ? MediaQuery.of(context).size.height * 0.6
          : MediaQuery.of(context).size.height * 0.7,
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
                        icon: const Icon(
                          Icons.open_in_new,
                          size: 20,
                          color: AppColors.azulClaro,
                        ),
                        onPressed: () => _openLinkInNewTab(url),
                        tooltip: 'Abrir em nova aba',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 20,
                          color: AppColors.azulClaro,
                        ),
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
                      icon: const Icon(
                        Icons.open_in_new,
                        size: 20,
                        color: AppColors.branco,
                      ),
                      label: Text(
                        'Abrir Link',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.azulClaro,
                        side: const BorderSide(color: AppColors.azulClaro),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 20,
                          vertical: isMobile ? 10 : 12,
                        ),
                      ),
                      onPressed: () => _copyLink(url),
                      icon: const Icon(
                        Icons.copy,
                        size: 20,
                        color: AppColors.azulClaro,
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
    final isPastDue =
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
                      fontSize: isMobile ? 16 : 18,
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
                    const SizedBox(height: 8),
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
                        const SizedBox(width: 6),
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
                        const Icon(
                          Icons.assessment,
                          size: 18,
                          color: AppColors.azulClaro,
                        ),
                        const SizedBox(width: 6),
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
                    const SizedBox(height: 8),
                    FutureBuilder<bool>(
                      future: _isPdfValid(bytes),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
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
            const SizedBox(height: 8),
            Text(
              reason,
              style: const TextStyle(color: Colors.red, fontSize: 12),
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
            icon: const Icon(Icons.download, color: AppColors.branco),
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

/// =======================
/// CONTROLLER DO COMENTÁRIOS (para badge e mensagens externas)
/// =======================
class CommentsController {
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
  bool _isActive = false;

  void Function(_Comment c)? _insertIncoming;

  void _attach(void Function(_Comment c) insertIncoming) {
    _insertIncoming = insertIncoming;
  }

  void setActive(bool active) {
    _isActive = active;
    if (active) markAllRead();
  }

  void markAllRead() {
    unreadCount.value = 0;
  }

  void addIncomingMessage({required String author, required String message}) {
    final c = _Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: author,
      message: message,
      createdAt: DateTime.now(),
      reactions: {},
    );
    _insertIncoming?.call(c);
    if (!_isActive) {
      unreadCount.value = unreadCount.value + 1;
    }
  }

  void dispose() {
    unreadCount.dispose();
  }
}

/// =======================
/// COMMENTS PANEL WIDGET
/// =======================

class CommentsPanel extends StatefulWidget {
  final String materialId;
  final String topicoId;
  final String disciplinaId;
  final String title;
  final CommentsController? controller;
  final bool showHeaderBadge;

  const CommentsPanel({
    super.key,
    required this.materialId,
    required this.topicoId,
    required this.disciplinaId,
    this.title = 'Comentários',
    this.controller,
    this.showHeaderBadge = true,
  });

  @override
  State<CommentsPanel> createState() => _CommentsPanelState();
}

class _CommentsPanelState extends State<CommentsPanel> {
  final TextEditingController _controllerText = TextEditingController();
  final ScrollController _listController = ScrollController();
  final ValueNotifier<bool> _isSending = ValueNotifier(false);

  List<Comentario> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(_insertIncomingFromController);
    widget.controller?.setActive(true);
    _fetchComments();
  }

  @override
  void dispose() {
    widget.controller?.setActive(false);
    _controllerText.dispose();
    _listController.dispose();
    _isSending.dispose();
    super.dispose();
  }

  Future<void> _fetchComments() async {
    try {
      setState(() => _loading = true);
      
      final response = await ComentarioService.buscarComentariosPorMaterial(
        widget.materialId,
      );

      if (response.success) {
        setState(() {
          _comments = response.data ?? [];
          _loading = false;
        });
        _jumpToEnd();
      } else {
        if (response.message != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${response.message}'),
              backgroundColor: AppColors.vermelhoErro,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        setState(() => _loading = false);
      }
    } catch (error) {
      print('Erro inesperado: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar comentários: $error'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _postComment(String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      _isSending.value = true;
      
      final response = await ComentarioService.criarComentario(
        materialId: widget.materialId,
        topicoId: widget.topicoId,
        disciplinaId: widget.disciplinaId,
        texto: text.trim(),
      );

      if (response.success && response.data != null) {
        setState(() => _comments.insert(0, response.data!));
        _controllerText.clear();
        _jumpToEnd();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comentário enviado com sucesso!'),
            backgroundColor: AppColors.verdeConfirmacao,
          ),
        );
      } else {
        if (response.message != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${response.message}'),
              backgroundColor: AppColors.vermelhoErro,
            ),
          );
        }
      }
    } catch (error) {
      print('Erro ao enviar comentário: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar comentário: $error'),
            backgroundColor: AppColors.vermelhoErro,
          ),
        );
      }
    } finally {
      _isSending.value = false;
    }
  }

  void _insertIncomingFromController(_Comment c) {
    final newComment = Comentario(
      id: c.id,
      materialId: widget.materialId,
      topicoId: widget.topicoId,
      disciplinaId: widget.disciplinaId,
      autor: {'nome': c.author},
      autorModel: 'Usuario',
      texto: c.message,
      respostas: [],
      dataCriacao: c.createdAt,
      editado: false,
    );
    setState(() => _comments.add(newComment));
    _jumpToEnd();
  }

  void _jumpToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_listController.hasClients) {
        _listController.animateTo(
          _listController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _trySend() {
    final text = _controllerText.text.trim();
    if (text.isEmpty) return;
    _postComment(text);
    widget.controller?.markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.branco,
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Recarregar',
                  onPressed: _loading ? null : _fetchComments,
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // Lista de comentários
          Expanded(
            child: Container(
              color: AppColors.branco,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulClaro),
                      ),
                    )
                  : _comments.isEmpty
                      ? const _EmptyComments()
                      : ListView.builder(
                          controller: _listController,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: _comments.length,
                          itemBuilder: (context, i) {
                            final comentario = _comments[i];
                            return _CommentBubble(comentario: comentario);
                          },
                        ),
            ),
          ),

          // Área de digitação
          Container(
            color: AppColors.branco,
            child: Column(
              children: [
                const Divider(height: 1, color: Colors.grey),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controllerText,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: 'Enviar um comentário...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.azulClaro),
                            ),
                          ),
                          onSubmitted: (_) => _trySend(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isSending,
                        builder: (_, sending, __) => ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.azulClaro,
                            foregroundColor: AppColors.branco,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          onPressed: sending ? null : _trySend,
                          child: sending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Enviar', style: AppTextStyles.fonteUbuntuSans),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyComments extends StatelessWidget {
  const _EmptyComments();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.branco,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.forum_outlined, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              Text(
                'É aqui que você pode deixar um comentário\n'
                'e ver o feedback do seu instrutor.',
                textAlign: TextAlign.center,
                style: AppTextStyles.fonteUbuntuSans.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Comment {
  final String id;
  final String author;
  final String message;
  final DateTime createdAt;
  final Map<String, int> reactions;

  _Comment({
    required this.id,
    required this.author,
    required this.message,
    required this.createdAt,
    required this.reactions,
  });
}

class _CommentBubble extends StatelessWidget {
  final Comentario comentario;

  const _CommentBubble({required this.comentario});

  @override
  Widget build(BuildContext context) {
    final autor = comentario.autor is Map ? comentario.autor['nome'] ?? 'Usuário' : 'Usuário';
    final initials = autor.isNotEmpty ? autor.trim().split(' ').map((e) => e[0]).take(2).join() : '?';

    return Container(
      color: AppColors.branco,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[200],
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          autor,
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(comentario.dataCriacao),
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comentario.texto,
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    // Mostrar respostas se houver
                    if (comentario.respostas.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...comentario.respostas.map((resposta) {
                        final respostaAutor = resposta.autor is Map ? resposta.autor['nome'] ?? 'Usuário' : 'Usuário';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.grey[300],
                                child: Text(
                                  respostaAutor.isNotEmpty ? respostaAutor.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        respostaAutor,
                                        style: AppTextStyles.fonteUbuntu.copyWith(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        resposta.texto,
                                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _ReactionChip extends StatelessWidget {
  final String emoji;
  final int count;
  final VoidCallback onTap;

  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = count > 0;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue[50] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppColors.azulClaro : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: AppTextStyles.fonteUbuntuSans.copyWith(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnreadPill extends StatelessWidget {
  final int count;
  const _UnreadPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}