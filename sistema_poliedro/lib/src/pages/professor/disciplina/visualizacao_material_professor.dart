// pages/material/visualizacao_material_page.dart
import 'dart:async'; // <-- para o timer do alerta
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math; // <-- para calcular altura dinâmica no mobile
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../services/permission_service.dart';
import '../../../services/material_service.dart';
import '../../../services/comentario_service.dart';
import '../../../services/auth_service.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../models/modelo_comentario.dart';
import '../../../models/modelo_usuario.dart'; // Import da classe Usuario
import 'package:http/http.dart' as http; // Import para http
import '../../../styles/cores.dart';
import '../../../styles/fontes.dart';
import '../../../components/alerta.dart'; // <-- seu AlertaWidget

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

// --- MOBILE TABS: Material | Comentários ---
enum _MobileView { material, comentarios }

_MobileView _mobileView = _MobileView.material;

class _VisualizacaoMaterialPageState extends State<VisualizacaoMaterialPage> {
  late Future<Uint8List?> _fileBytesFuture;
  final CommentsController _chatController = CommentsController();

  // --- estado do alerta padronizado ---
  String? _alertaMensagem;
  bool _alertaSucesso = false;
  Timer? _alertaTimer;

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

  Widget _buildMobileTopButtons() {
    final primary = AppColors.azulClaro;
    final isComentarios = _mobileView == _MobileView.comentarios;
    final isMaterial = _mobileView == _MobileView.material;

    Widget buildPill({
      required String text,
      required bool active,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: active ? primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primary.withOpacity(active ? 0.0 : 0.3),
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                text,
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: active ? AppColors.branco : Colors.grey[700],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          buildPill(
            text: 'Material',
            active: isMaterial,
            onTap: () {
              if (!isMaterial) {
                setState(() {
                  _mobileView = _MobileView.material;
                  _chatController.setActive(false); // saindo dos comentários
                });
              }
            },
          ),
          const SizedBox(width: 6),
          buildPill(
            text: 'Comentários',
            active: isComentarios,
            onTap: () {
              if (!isComentarios) {
                setState(() {
                  _mobileView = _MobileView.comentarios;
                  _chatController.setActive(true); // entrando em comentários
                  _chatController.markAllRead();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  // =======================
  // ALERTA PADRONIZADO
  // =======================
  void _mostrarAlerta(String mensagem, bool sucesso) {
    _alertaTimer?.cancel();
    setState(() {
      _alertaMensagem = mensagem;
      _alertaSucesso = sucesso;
    });
    _alertaTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _alertaMensagem = null);
    });
  }

  Widget _buildAlertaOverlay() {
    if (_alertaMensagem == null) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: true,
      child: AlertaWidget(mensagem: _alertaMensagem!, sucesso: _alertaSucesso),
    );
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

  // Método universal para download
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
      _mostrarAlerta('Erro ao salvar arquivo: $e', false);
    }
  }

  // Método específico para Android
  Future<void> _downloadAndroid(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    try {
      print('=== DEBUG: Iniciando download no Android ===');
      print('=== DEBUG: Nome do arquivo: $fileName ===');
      print('=== DEBUG: Tamanho: ${bytes.length} bytes ===');

      final hasPermission = await PermissionService.requestStoragePermissions();
      if (!hasPermission) {
        _mostrarAlerta(
          'Permissão de armazenamento necessária para salvar o arquivo',
          false,
        );
        return;
      }

      Directory? directory = await getDownloadsDirectory();
      if (directory == null) directory = await getExternalStorageDirectory();
      if (directory == null)
        directory = await getApplicationDocumentsDirectory();

      if (directory != null) {
        final folder = Directory('${directory.path}/SistemaPoliedro');
        if (!await folder.exists()) {
          await folder.create(recursive: true);
        }

        final file = File('${folder.path}/$fileName');
        await file.writeAsBytes(bytes);

        print('=== DEBUG: Arquivo salvo em: ${file.path} ===');

        _mostrarAlerta('Download concluído! Salvo em: SistemaPoliedro/', true);

        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done) {
          print(
            '=== DEBUG: Não foi possível abrir o arquivo automaticamente ===',
          );
        }
      } else {
        _mostrarAlerta(
          'Não foi possível acessar o armazenamento do dispositivo',
          false,
        );
      }
    } catch (e) {
      print('=== DEBUG ERRO Android download: $e ===');
      _mostrarAlerta('Erro ao salvar arquivo: $e', false);
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

  // Métodos para Web
  void _downloadPdfWeb(Uint8List bytes, String fileName) {
    if (!kIsWeb) return;
    try {
      final base64Pdf = base64.encode(bytes);
      final anchor =
          html.AnchorElement(href: 'data:application/pdf;base64,$base64Pdf')
            ..download = fileName
            ..style.display = 'none';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
      _mostrarAlerta('Download iniciado: $fileName', true);
    } catch (e) {
      print('=== DEBUG ERRO download web: $e ===');
      _mostrarAlerta('Erro ao fazer download', false);
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
    } catch (e) {
      print('=== DEBUG ERRO Blob URL: $e ===');
      _tryAlternativePdfOpenWeb(bytes);
    }
  }

  void _tryAlternativePdfOpenWeb(Uint8List bytes) {
    if (!kIsWeb) return;
    try {
      final base64Pdf = base64.encode(bytes);
      final pdfUrl = 'data:application/pdf;base64,$base64Pdf';
      html.window.open(pdfUrl, '_blank');
    } catch (e2) {
      print('=== DEBUG ERRO Data URL: $e2 ===');
      _showOpenPdfDialogWeb(bytes);
    }
  }

  void _showOpenPdfDialogWeb(Uint8List bytes) {
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
              backgroundColor: _getMaterialColor(widget.material.tipo),
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
      final base64Pdf = base64.encode(bytes);
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
      _mostrarAlerta(
        'Não foi possível abrir o PDF. Faça o download e abra manualmente.',
        false,
      );
    }
  }

  // Métodos principais que chamam as versões web/mobile
  void _downloadPdf(Uint8List bytes) {
    final fileName = '${_sanitizeFileName(widget.material.titulo)}.pdf';
    if (kIsWeb) {
      _downloadPdfWeb(bytes, fileName);
    } else {
      _downloadFileMobile(bytes, fileName, 'application/pdf');
    }
  }

  void _openPdfInNewTab(Uint8List bytes) {
    if (kIsWeb) {
      _openPdfInNewTabWeb(bytes);
    } else {
      _downloadPdf(bytes);
    }
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  void _showError(String message) {
    _mostrarAlerta(message, false);
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
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do material
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
                                  widget.material.prazo!.isBefore(
                                        DateTime.now(),
                                      )
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

                // Conteúdo principal com layout responsivo
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 960;

                      if (!isWide) {
                        // Layout com abas (Material | Comentários) para mobile
                        return Column(
                          children: [
                            _buildMobileTopButtons(),
                            const SizedBox(height: 12),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                switchInCurve: Curves.easeIn,
                                switchOutCurve: Curves.easeOut,
                                child: _mobileView == _MobileView.material
                                    ? FutureBuilder<Uint8List?>(
                                        key: const ValueKey('mobile-material'),
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
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(AppColors.azulClaro),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Carregando material...',
                                                    style: AppTextStyles
                                                        .fonteUbuntuSans
                                                        .copyWith(
                                                          fontSize: 14,
                                                          color: AppColors
                                                              .azulClaro,
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
                                          return _buildConteudoMaterial(
                                            context,
                                            bytes,
                                          );
                                        },
                                      )
                                    : CommentsPanel(
                                        key: const ValueKey(
                                          'mobile-comentarios',
                                        ),
                                        materialId: widget.material.id,
                                        topicoId: widget.topicoId,
                                        disciplinaId: widget.slug,
                                        title: 'Comentários',
                                        controller: _chatController,
                                        showHeaderBadge:
                                            false, // header simplificado no mobile
                                        onAlert: _mostrarAlerta,
                                      ),
                              ),
                            ),
                          ],
                        );
                      }

                      // Layout em colunas para telas maiores
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
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 360,
                            child: CommentsPanel(
                              materialId: widget.material.id,
                              topicoId: widget.topicoId,
                              disciplinaId: widget.slug,
                              title: 'Comentários',
                              controller: _chatController,
                              onAlert: _mostrarAlerta,
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
          _buildAlertaOverlay(), // <-- overlay no topo direito
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

  Widget _buildConteudoMaterial(BuildContext context, Uint8List? bytes) {
    switch (widget.material.tipo) {
      case 'imagem':
        return _buildImageContainer(bytes, widget.material.url);
      case 'pdf':
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
        return _buildLinkContainer(widget.material.url);
      case 'atividade':
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
      imageWidget = Image.memory(
        bytes,
        fit: BoxFit.contain,
        height: isMobile
            ? MediaQuery.of(context).size.height * 0.3
            : MediaQuery.of(context).size.height * 0.4,
        errorBuilder: (context, error, stackTrace) {
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
      // sem height fixo (pai controla com Expanded)
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

  void _downloadImage(Uint8List? bytes, String? url) {
    final fileName = '${_sanitizeFileName(widget.material.titulo)}.jpg';
    if (kIsWeb) {
      _downloadImageWeb(bytes, url, fileName);
    } else if (bytes != null) {
      _downloadFileMobile(bytes, fileName, 'image/jpeg');
    } else {
      _mostrarAlerta('Imagem não disponível para download', false);
    }
  }

  void _downloadImageWeb(Uint8List? bytes, String? url, String fileName) {
    if (!kIsWeb) return;
    try {
      if (bytes != null) {
        final base64Image = base64.encode(bytes);
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
      _mostrarAlerta('Download iniciado: ${widget.material.titulo}', true);
    } catch (e) {
      print('=== DEBUG ERRO download imagem web: $e ===');
      _mostrarAlerta('Erro ao fazer download da imagem', false);
    }
  }

  Widget _buildLinkContainer(String? url) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (url == null || url.isEmpty) {
      return _buildErrorWidget('URL não disponível');
    }

    final corIcone = _getMaterialColor(widget.material.tipo);

    return Container(
      // sem height fixo
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

  void _openLinkInNewTab(String url) {
    if (kIsWeb) {
      _openLinkInNewTabWeb(url);
    } else {
      _mostrarAlerta('Funcionalidade disponível apenas na versão web', false);
    }
  }

  void _openLinkInNewTabWeb(String url) {
    if (!kIsWeb) return;
    html.window.open(url, '_blank');
  }

  void _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    _mostrarAlerta('Link copiado para a área de transferência', true);
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

  Widget _buildPdfWeb(Uint8List bytes) {
    if (kIsWeb) {
      return _buildPdfIframe(bytes);
    } else {
      return _buildPdfMobile(bytes);
    }
  }

  // =========================
  // PDF (WEB) — RESPONSIVO
  // =========================
  Widget _buildPdfIframe(Uint8List bytes) {
    try {
      final base64Pdf = base64.encode(bytes);
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
                  Expanded(
                    child: Text(
                      '$tipoDisplay: ${widget.material.titulo}',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
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
                        textAlign: TextAlign.center,
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
            ),
          ],
        ),
      );
    } catch (e) {
      print('=== DEBUG ERRO alternativa PDF: $e ===');
      return _buildPdfFallback(bytes, 'Erro: $e');
    }
  }

  // Alias para chamadas antigas com i minúsculo (evita erro de método não encontrado)
  Widget _buildPdfiframe(Uint8List bytes) => _buildPdfIframe(bytes);

  // =========================
  // PDF (MOBILE) — RESPONSIVO
  // =========================
  Widget _buildPdfMobile(Uint8List bytes) {
    final corIcone = _getMaterialColor(widget.material.tipo);
    final tipoDisplay = _getTipoNome(widget.material.tipo);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
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
              children: [
                Expanded(
                  child: Text(
                    '$tipoDisplay: ${widget.material.titulo}',
                    style: AppTextStyles.fonteUbuntu.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 14 : 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
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

  @override
  void dispose() {
    _alertaTimer?.cancel();
    super.dispose();
  }
}

/// =======================
/// CONTROLLER DO COMENTÁRIOS
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

  final void Function(String mensagem, bool sucesso)? onAlert;

  const CommentsPanel({
    super.key,
    required this.materialId,
    required this.topicoId,
    required this.disciplinaId,
    this.title = 'Comentários',
    this.controller,
    this.showHeaderBadge = true,
    this.onAlert,
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
  String? _currentUserId;
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(_insertIncomingFromController);
    widget.controller?.setActive(true);
    _loadCurrentUser();
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

  Future<void> _loadCurrentUser() async {
    try {
      _currentUserId = await AuthService.getUserId();
      _currentUserRole = await AuthService.getUserType();
    } catch (e) {
      print('Erro ao carregar usuário atual: $e');
    }
  }

  bool _canEditComment(Comentario comentario) {
    if (_currentUserId == null) return false;
    final autorId = comentario.autor is Map
        ? comentario.autor['_id']?.toString()
        : comentario.autor.toString();
    return autorId == _currentUserId;
  }

  bool _canDeleteComment(Comentario comentario) {
    if (_currentUserId == null) return false;
    final autorId = comentario.autor is Map
        ? comentario.autor['_id']?.toString()
        : comentario.autor.toString();

    if (_currentUserRole == 'aluno') {
      return autorId == _currentUserId;
    } else if (_currentUserRole == 'professor' || _currentUserRole == 'admin') {
      return true;
    }
    return false;
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
          widget.onAlert?.call('Erro: ${response.message}', false);
        }
        setState(() => _loading = false);
      }
    } catch (error) {
      print('Erro inesperado: $error');
      if (mounted) {
        widget.onAlert?.call('Erro ao carregar comentários: $error', false);
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
        slug: widget.disciplinaId,
        texto: text.trim(),
      );

      if (response.success && response.data != null) {
        setState(() => _comments.insert(0, response.data!));
        _controllerText.clear();
        _jumpToEnd();
        widget.onAlert?.call('Comentário enviado com sucesso!', true);
      } else {
        if (response.message != null && mounted) {
          widget.onAlert?.call('Erro: ${response.message}', false);
        }
      }
    } catch (error) {
      print('Erro ao enviar comentário: $error');
      if (mounted) {
        widget.onAlert?.call('Erro ao enviar comentário: $error', false);
      }
    } finally {
      _isSending.value = false;
    }
  }

  Future<void> _handleDeleteComment(Comentario comentario) async {
    try {
      final response = await ComentarioService.excluirComentario(
        comentarioId: comentario.id,
      );

      if (response.success && mounted) {
        setState(() {
          _comments.removeWhere((c) => c.id == comentario.id);
        });
        widget.onAlert?.call('Comentário excluído com sucesso!', true);
      } else if (mounted) {
        widget.onAlert?.call('Erro: ${response.message}', false);
      }
    } catch (error) {
      if (mounted) {
        widget.onAlert?.call('Erro ao excluir comentário: $error', false);
      }
    }
  }

  Future<void> _handleEditComment() async {
    await _fetchComments();
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: AppColors.branco,
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: Colors.grey,
                ),
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

          Expanded(
            child: Container(
              color: AppColors.branco,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.azulClaro,
                        ),
                      ),
                    )
                  : _comments.isEmpty
                  ? const _EmptyComments()
                  : ListView.builder(
                      controller: _listController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      itemCount: _comments.length,
                      itemBuilder: (context, i) {
                        final comentario = _comments[i];
                        return _CommentBubble(
                          comentario: comentario,
                          onEdit: _handleEditComment,
                          onDelete: () => _handleDeleteComment(comentario),
                          canEdit: _canEditComment(comentario),
                          canDelete: _canDeleteComment(comentario),
                          onAlert: widget.onAlert,
                        );
                      },
                    ),
            ),
          ),

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
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),

                            // borda "genérica" / fallback
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF2CA3AC), // turquesa
                                width: 1.5,
                              ),
                            ),

                            // borda quando o campo está habilitado mas não focado
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF2CA3AC), // turquesa
                                width: 1.5,
                              ),
                            ),

                            // borda quando o campo está focado
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF2CA3AC), // turquesa
                                width: 2,
                              ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          onPressed: sending ? null : _trySend,
                          child: sending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Enviar',
                                  style: AppTextStyles.fonteUbuntuSans,
                                ),
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

class _CommentBubble extends StatefulWidget {
  final Comentario comentario;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool canDelete;
  final void Function(String mensagem, bool sucesso)? onAlert;

  const _CommentBubble({
    required this.comentario,
    this.onEdit,
    this.onDelete,
    required this.canEdit,
    required this.canDelete,
    this.onAlert,
  });

  @override
  State<_CommentBubble> createState() => __CommentBubbleState();
}

class __CommentBubbleState extends State<_CommentBubble> {
  bool _isEditing = false;
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editController.text = widget.comentario.texto;
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _editFocusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editController.text = widget.comentario.texto;
    });
  }

  Future<void> _saveEditing() async {
    if (_editController.text.trim().isEmpty) return;

    try {
      final response = await ComentarioService.editarComentario(
        comentarioId: widget.comentario.id,
        texto: _editController.text.trim(),
      );

      if (response.success && mounted) {
        setState(() {
          _isEditing = false;
        });
        widget.onEdit?.call();
        widget.onAlert?.call('Comentário editado com sucesso!', true);
      } else if (mounted) {
        widget.onAlert?.call('Erro: ${response.message}', false);
      }
    } catch (error) {
      if (mounted) {
        widget.onAlert?.call('Erro ao editar comentário: $error', false);
      }
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.branco,
        surfaceTintColor: Colors.transparent,
        title: const Text('Excluir Comentário'),
        content: const Text('Tem certeza que deseja excluir este comentário?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: ButtonStyle(
              foregroundColor: const MaterialStatePropertyAll(
                Color(0xFF1E64D6),
              ),
              overlayColor: MaterialStatePropertyAll(
                const Color(0xFF1E64D6).withOpacity(0.08),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF1E64D6)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onDelete?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.vermelhoErro,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final autor = widget.comentario.autor['nome']?.toString() ?? 'Usuário';
    final fotoUrl = widget.comentario.autor['fotoUrl']?.toString();
    final initials = autor.isNotEmpty
        ? autor.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';

    return Container(
      color: AppColors.branco,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserAvatar(fotoUrl, initials, autor, widget.comentario.autor),
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
                    _buildCommentHeader(autor),
                    const SizedBox(height: 6),
                    _buildCommentContent(),
                    if (widget.comentario.respostas.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...widget.comentario.respostas.map((resposta) {
                        return _buildRespostaBubble(resposta);
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

  Widget _buildUserAvatar(
    String? fotoUrl,
    String initials,
    String autor,
    Map<String, dynamic> autorData,
  ) {
    final autorId = autorData['_id']?.toString() ?? autorData['id']?.toString();

    String autorTipo = 'aluno';
    if (autorData['tipo'] != null) {
      autorTipo = autorData['tipo'].toString();
    } else {
      autorTipo = autorData['ra'] != null ? 'aluno' : 'professor';
    }

   

    final String tipoEndpoint = autorTipo == 'aluno' ? 'alunos' : 'professores';
    final String urlFinal =
        '${AuthService.baseUrl}/api/$tipoEndpoint/image/$autorId';


    return FutureBuilder<Map<String, String>>(
      future: _getImageHeaders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingAvatar();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildAvatarFallback(initials, autor);
        }

        final headers = snapshot.data!;

        return ClipOval(
          child: CachedNetworkImage(
            imageUrl: urlFinal,
            httpHeaders: headers,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildLoadingAvatar(),
            errorWidget: (context, url, error) {
              print('=== IMAGE LOAD ERROR: $error ===');
              print('=== TENTANDO THE URL ALTERNATIVA ===');
              final String altUrlFinal =
                  '${AuthService.baseUrl}/api/$tipoEndpoint/$autorId/foto';
              print('=== URL Alternativa: $altUrlFinal ===');

              return CachedNetworkImage(
                imageUrl: altUrlFinal,
                httpHeaders: headers,
                width: 32,
                height: 32,
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildLoadingAvatar(),
                errorWidget: (context, url, error2) {
                  print('=== FALHA NA URL ALTERNATIVA TAMBÉM: $error2 ===');
                  return _buildAvatarFallback(initials, autor);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getImageHeaders() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return {};
      return {'Authorization': 'Bearer $token'};
    } catch (e) {
      print('=== ERRO ao obter token: $e ===');
      return {};
    }
  }

  Widget _buildLoadingAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulClaro),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String initials, String autor) {
    return CircleAvatar(
      backgroundColor: _getColorFromName(autor),
      radius: 16,
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getColorFromName(String name) {
    if (name.isEmpty) return AppColors.azulClaro;

    final colors = [
      AppColors.azulClaro,
      AppColors.vermelho,
      AppColors.verdeConfirmacao,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.indigo,
      Colors.brown,
      Colors.pink,
    ];

    final index = name.codeUnits.reduce((a, b) => a + b) % colors.length;
    return colors[index];
  }

  Usuario _corrigirFotoUrl(Usuario user) {
    if (user.fotoUrl == null || user.fotoUrl!.isEmpty) {
      final String tipoEndpoint = user.tipo == 'aluno'
          ? 'alunos'
          : 'professores';
      final String imageEndpoint = '/$tipoEndpoint/image/${user.id}';
      final String correctedUrl = AuthService.baseUrl + '/api' + imageEndpoint;
      print('=== DEBUG: Gerando URL para imagem: $correctedUrl ===');
      return user.copyWith(fotoUrl: correctedUrl);
    }

    if (user.fotoUrl!.contains('localhost')) {
      final String tipoEndpoint = user.tipo == 'aluno'
          ? 'alunos'
          : 'professores';
      final String imageEndpoint = '/$tipoEndpoint/image/${user.id}';
      final String correctedUrl = AuthService.baseUrl + '/api' + imageEndpoint;
      print('=== DEBUG: Corrigindo URL localhost: $correctedUrl ===');
      return user.copyWith(fotoUrl: correctedUrl);
    }

    if (user.fotoUrl!.startsWith('http')) {
      print('=== DEBUG: URL já é válida: ${user.fotoUrl} ===');
      return user;
    }

    final String tipoEndpoint = user.tipo == 'aluno' ? 'alunos' : 'professores';
    final String imageEndpoint = '/$tipoEndpoint/image/${user.id}';
    final String correctedUrl = AuthService.baseUrl + '/api' + imageEndpoint;
    print('=== DEBUG: Fallback - gerando URL: $correctedUrl ===');
    return user.copyWith(fotoUrl: correctedUrl);
  }

  Widget _buildCommentHeader(String autor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                autor,
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatTimestamp(widget.comentario.dataCriacao),
                style: AppTextStyles.fonteUbuntuSans.copyWith(
                  color: Colors.grey[600],
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        if (widget.canEdit || widget.canDelete)
          PopupMenuButton<String>(
            color: AppColors.branco,
            surfaceTintColor: Colors.transparent,
            icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
            itemBuilder: (context) => [
              if (widget.canEdit)
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
              if (widget.canDelete)
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 16,
                        color: AppColors.vermelhoErro,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Excluir',
                        style: TextStyle(color: AppColors.vermelhoErro),
                      ),
                    ],
                  ),
                ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _startEditing();
                  break;
                case 'delete':
                  _confirmDelete();
                  break;
              }
            },
          ),
      ],
    );
  }

  Widget _buildCommentContent() {
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _editController,
            focusNode: _editFocusNode,
            maxLines: null,
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: 14,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.all(8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2CA3AC),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2CA3AC),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(
                  color: Color(0xFF2CA3AC),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cancelEditing,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: const BorderSide(color: Colors.grey),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveEditing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azulClaro,
                    foregroundColor: AppColors.branco,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                  child: const Text('Salvar', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.comentario.texto,
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          if (widget.comentario.editado) ...[
            const SizedBox(height: 4),
            Text(
              'editado',
              style: AppTextStyles.fonteUbuntuSans.copyWith(
                color: Colors.grey[500],
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );
    }
  }

  Widget _buildRespostaBubble(Comentario resposta) {
    final respostaAutor = resposta.autor['nome']?.toString() ?? 'Usuário';
    final respostaFotoUrl = resposta.autor['fotoUrl']?.toString();
    final respostaIniciais = respostaAutor.isNotEmpty
        ? respostaAutor.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUserAvatar(
            respostaFotoUrl,
            respostaIniciais,
            respostaAutor,
            resposta.autor,
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
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} h';
    if (diff.inDays < 7) return '${diff.inDays} d';

    return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
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
