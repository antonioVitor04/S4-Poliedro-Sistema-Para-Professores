// pages/material/visualizacao_material_page.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:typed_data';
import 'dart:convert' as convert;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
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

  Widget _buildPdfWeb(Uint8List bytes) {
    if (kIsWeb) {
      return _buildPdfIframe(bytes);
    } else {
      return _buildPdfSyncfusion(bytes);
    }
  }

  Widget _buildPdfIframe(Uint8List bytes) {
    try {
      print('=== DEBUG: Criando alternativa para PDF ===');

      final base64Pdf = convert.base64Encode(bytes);
      final pdfDataUrl = 'data:application/pdf;base64,$base64Pdf';

      final corIcone = _getMaterialColor(
        widget.material.tipo,
      ); // Cor do ícone (vermelho para PDF)
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
                          color: AppColors.azulClaro, // Ícone vermelho para PDF
                        ),
                        onPressed: () => _openPdfInNewTab(bytes),
                        tooltip: 'Abrir em nova aba',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.download,
                          size: 20,
                          color: AppColors.azulClaro, // Ícone vermelho para PDF
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
                      color: corIcone, // Ícone vermelho para PDF
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
                        backgroundColor:
                            AppColors.azulClaro, // Botão azul claro
                        foregroundColor: AppColors.branco,
                      ),
                      onPressed: () => _openPdfInNewTab(bytes),
                      icon: Icon(
                        Icons.open_in_new,
                        color: AppColors.branco,
                      ), // Ícone vermelho
                      label: Text(
                        openText,
                        style: AppTextStyles.fonteUbuntuSans,
                      ),
                    ),
                    SizedBox(height: 12),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            AppColors.azulClaro, // Botão azul claro
                        side: BorderSide(color: AppColors.azulClaro),
                      ),
                      onPressed: () => _downloadPdf(bytes),
                      icon: Icon(
                        Icons.download,
                        color: AppColors.azulClaro,
                      ), // Ícone vermelho
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

  Widget _buildPdfSyncfusion(Uint8List bytes) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      child: SfPdfViewer.memory(
        bytes,
        key: Key('pdf_${widget.material.id}'),
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          print(
            '=== DEBUG PDF Syncfusion: Documento carregado com ${details.document.pages.count} páginas ===',
          );
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          print('=== DEBUG PDF Syncfusion: Falha - ${details.error} ===');
        },
      ),
    );
  }

  Widget _buildPdfFallback(Uint8List bytes, [String? reason]) {
    final corIcone = _getMaterialColor(
      widget.material.tipo,
    ); // Cor do ícone (vermelho para PDF)
    final tipoDisplay = _getTipoNome(widget.material.tipo);
    final downloadText = widget.material.tipo == 'atividade'
        ? 'Fazer Download da Atividade'
        : 'Fazer Download';
    final openText = widget.material.tipo == 'atividade'
        ? 'Abrir Atividade em Nova Aba'
        : 'Abrir em Nova Aba';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getMaterialIconData(widget.material.tipo),
            size: 64,
            color: corIcone, // Ícone vermelho para PDF
          ),
          SizedBox(height: 16),
          Text(
            'Visualizador de $tipoDisplay',
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Use os botões abaixo para visualizar o $tipoDisplay',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulClaro, // Botão azul claro
              foregroundColor: AppColors.branco,
            ),
            onPressed: () => _openPdfInNewTab(bytes),
            icon: Icon(Icons.open_in_new, color: AppColors.branco), // Ícone vermelho
            label: Text(openText, style: AppTextStyles.fonteUbuntuSans),
          ),
          SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.azulClaro, // Botão azul claro
              side: BorderSide(color: AppColors.azulClaro),
            ),
            onPressed: () => _downloadPdf(bytes),
            icon: Icon(Icons.download, color: AppColors.azulClaro), // Ícone vermelho
            label: Text(downloadText, style: AppTextStyles.fonteUbuntuSans),
          ),
        ],
      ),
    );
  }

  void _downloadPdf(Uint8List bytes) {
    if (kIsWeb) {
      try {
        final base64Pdf = convert.base64Encode(bytes);
        final anchor =
            html.AnchorElement(href: 'data:application/pdf;base64,$base64Pdf')
              ..download = '${_sanitizeFileName(widget.material.titulo)}.pdf'
              ..style.display = 'none';

        html.document.body?.append(anchor);
        anchor.click();
        anchor.remove();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download iniciado: ${widget.material.titulo}.pdf'),
            backgroundColor: AppColors.verdeConfirmacao,
          ),
        );
      } catch (e) {
        print('=== DEBUG ERRO download: $e ===');
        _showError('Erro ao fazer download');
      }
    }
  }

  void _downloadImage(Uint8List? bytes, String? url) {
    if (kIsWeb) {
      try {
        if (bytes != null) {
          final base64Image = convert.base64Encode(bytes);
          final anchor =
              html.AnchorElement(href: 'data:image/jpeg;base64,$base64Image')
                ..download = '${_sanitizeFileName(widget.material.titulo)}.jpg'
                ..style.display = 'none';

          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();
        } else if (url != null && url.isNotEmpty) {
          final anchor = html.AnchorElement(href: url)
            ..download = '${_sanitizeFileName(widget.material.titulo)}.jpg'
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
        print('=== DEBUG ERRO download imagem: $e ===');
        _showError('Erro ao fazer download da imagem');
      }
    }
  }

  void _openImageInNewTab(Uint8List? bytes, String? url) {
    if (kIsWeb) {
      try {
        String imageUrl;
        if (bytes != null) {
          final base64Image = convert.base64Encode(bytes);
          imageUrl = 'data:image/jpeg;base64,$base64Image';
        } else if (url != null && url.isNotEmpty) {
          imageUrl = url;
        } else {
          return;
        }

        final window = html.window.open(imageUrl, '_blank');
        if (window == null) {
          throw Exception('Popup bloqueado pelo navegador');
        }
      } catch (e) {
        print('=== DEBUG ERRO abrir imagem: $e ===');
        _showError('Erro ao abrir imagem em nova aba');
      }
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  void _openPdfInNewTab(Uint8List bytes) {
    if (kIsWeb) {
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
        try {
          final base64Pdf = convert.base64Encode(bytes);
          final pdfUrl = 'data:application/pdf;base64,$base64Pdf';
          final window = html.window.open(pdfUrl, '_blank');
          if (window == null) {
            throw Exception('Popup bloqueado pelo navegador');
          }
        } catch (e2) {
          print('=== DEBUG ERRO Data URL: $e2 ===');
          _showOpenPdfDialog(bytes);
        }
      }
    }
  }

  void _showOpenPdfDialog(Uint8List bytes) {
    // Use cor dinâmica baseada no tipo
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
              _forceOpenPdf(bytes);
            },
            child: Text('Abrir PDF', style: AppTextStyles.fonteUbuntuSans),
          ),
        ],
      ),
    );
  }

  void _forceOpenPdf(Uint8List bytes) {
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.fonteUbuntuSans),
        backgroundColor: AppColors.vermelhoErro,
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.vermelhoErro),
          SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: 18,
              color: AppColors.vermelhoErro,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Método principal de construção de conteúdo
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
            if (snapshot.hasData == true) {
              return _buildPdfWeb(bytes);
            } else {
              return _buildPdfFallback(bytes);
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
    Widget imageWidget;
    if (url != null && url.isNotEmpty) {
      print('=== DEBUG: Carregando imagem de URL ===');
      imageWidget = Image.network(
        url,
        fit: BoxFit.contain,
        height: MediaQuery.of(context).size.height * 0.4,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(color: AppColors.azulClaro),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('=== DEBUG ERRO imagem URL: $error ===');
          return Text(
            'Erro na imagem',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              color: AppColors.vermelhoErro,
            ),
          );
        },
      );
    } else if (bytes != null) {
      print('=== DEBUG: Carregando imagem de bytes ===');
      imageWidget = Image.memory(
        bytes,
        fit: BoxFit.contain,
        height: MediaQuery.of(context).size.height * 0.4,
        errorBuilder: (context, error, stackTrace) {
          print('=== DEBUG ERRO imagem memory: $error ===');
          return Text(
            'Erro na imagem de memória',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              color: AppColors.vermelhoErro,
            ),
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

    final corIcone = _getMaterialColor(
      widget.material.tipo,
    ); // Cor do ícone baseada no tipo

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
                  'Imagem: ${widget.material.titulo}',
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.download, size: 20, color: AppColors.azulClaro),
                      onPressed: () => _downloadImage(bytes, url),
                      tooltip: 'Fazer download',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
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
            padding: const EdgeInsets.only(bottom: 16.0),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.azulClaro, // Cor do botão
                side: BorderSide(color: AppColors.azulClaro),
              ),
              onPressed: () => _downloadImage(bytes, url),
              icon: Icon(
                Icons.download,
                color: AppColors.azulClaro,
              ), // Ícone com cor do material
              label: Text(
                'Fazer Download',
                style: AppTextStyles.fonteUbuntuSans,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkContainer(String? url) {
    if (url == null || url.isEmpty) {
      return Text(
        'URL não disponível',
        style: AppTextStyles.fonteUbuntuSans.copyWith(
          color: AppColors.vermelhoErro,
        ),
      );
    }

    final corIcone = _getMaterialColor(
      widget.material.tipo,
    ); // Cor do ícone (azul claro para links)

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
                  'Link: ${widget.material.titulo}',
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link, size: 64, color: corIcone),
                  SizedBox(height: 16),
                  Text(
                    'Link Externo',
                    style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 20),
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SelectableText(
                      url,
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.azulClaro, // Botão azul claro
                      foregroundColor: AppColors.branco,
                    ),
                    onPressed: () => _openLinkInNewTab(url),
                    icon: Icon(Icons.open_in_new, color: AppColors.branco),
                    label: Text(
                      'Abrir Link',
                      style: AppTextStyles.fonteUbuntuSans,
                    ),
                  ),
                  SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.azulClaro, // Botão azul claro
                      side: BorderSide(color: AppColors.azulClaro),
                    ),
                    onPressed: () => _copyLink(url),
                    icon: Icon(Icons.copy, color: AppColors.azulClaro),
                    label: Text(
                      'Copiar Link',
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
  }

  void _openLinkInNewTab(String url) {
    if (kIsWeb) {
      html.window.open(url, '_blank');
    }
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
            padding: EdgeInsets.all(8),
            color: Colors.grey[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Atividade: ${widget.material.titulo}',
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Título: ${widget.material.titulo}',
                      style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 18),
                    ),
                    if (widget.material.descricao != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Descrição: ${widget.material.descricao!}',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (widget.material.prazo != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: isPastDue
                                ? AppColors.vermelhoErro
                                : AppColors.azulClaro,
                          ),
                          SizedBox(width: 4),
                          Text(
                            isPastDue
                                ? 'Prazo Expirado: ${_formatarData(widget.material.prazo!)}'
                                : 'Prazo: ${_formatarData(widget.material.prazo!)}',
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              fontSize: 16,
                              color: isPastDue
                                  ? AppColors.vermelhoErro
                                  : AppColors.azulClaro,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (bytes != null && bytes.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Text(
                        'Arquivo Anexado:',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<bool>(
                        future: _isPdfValid(bytes),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasData == true) {
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
          ),
        ],
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        backgroundColor: AppColors.branco,
        appBar: AppBar(
          title: Text(
            widget.material.titulo,
            style: AppTextStyles.fonteUbuntu.copyWith(color: AppColors.branco),
          ),
          backgroundColor: AppColors.azulClaro,
          foregroundColor: AppColors.branco,
          actions: [],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tópico: ${widget.topicoTitulo}',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.material.titulo,
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.material.descricao != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          widget.material.descricao!,
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: 16,
                          ),
                        ),
                      ],
                      if (widget.material.prazo != null) ...[
                        const SizedBox(height: 12),
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
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
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
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.material.peso > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.assessment,
                              color: AppColors.azulClaro,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Peso: ${widget.material.peso}%',
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                color: AppColors.azulClaro,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _getMaterialIconData(widget.material.tipo),
                            color: _getMaterialColor(widget.material.tipo),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getTipoNome(widget.material.tipo),
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<Uint8List?>(
                  future: _fileBytesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.azulClaro,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Carregando material...',
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                fontSize: 16,
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
                              size: 64,
                              color: AppColors.vermelhoErro,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erro ao carregar arquivo: ${snapshot.error}',
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                fontSize: 16,
                                color: AppColors.vermelhoErro,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.azulClaro,
                                foregroundColor: AppColors.branco,
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
                                style: AppTextStyles.fonteUbuntuSans,
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
              Icon(Icons.bug_report, size: 64, color: AppColors.vermelhoErro),
              const SizedBox(height: 16),
              Text(
                'Erro crítico: $e',
                style: AppTextStyles.fonteUbuntuSans.copyWith(
                  fontSize: 18,
                  color: AppColors.vermelhoErro,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
