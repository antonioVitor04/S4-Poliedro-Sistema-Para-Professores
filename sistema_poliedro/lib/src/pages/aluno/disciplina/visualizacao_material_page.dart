// pages/material/visualizacao_material_page.dart
import 'package:flutter/material.dart';
import '../../../models/modelo_card_disciplina.dart';
import '../../../styles/cores.dart';
import '../../../styles/fontes.dart';

class VisualizacaoMaterialPage extends StatelessWidget {
  final MaterialDisciplina material;
  final String topicoTitulo;

  const VisualizacaoMaterialPage({
    super.key,
    required this.material,
    required this.topicoTitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(material.titulo),
        backgroundColor: AppColors.azulClaro,
        foregroundColor: Colors.white,
        actions: [
          if (material.tipo == 'imagem' || material.tipo == 'pdf')
            IconButton(
              onPressed: () => _baixarMaterial(context), // Passar context aqui
              icon: const Icon(Icons.download),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações do material
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tópico: $topicoTitulo',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      material.titulo,
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (material.descricao != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        material.descricao!,
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: 16,
                        ),
                      ),
                    ],
                    if (material.prazo != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Prazo: ${_formatarData(material.prazo!)}',
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (material.peso > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.assessment,
                            color: Colors.blue,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Peso: ${material.peso}%',
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              color: Colors.blue,
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
                          _getMaterialIconData(material.tipo),
                          color: _getMaterialColor(material.tipo),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTipoNome(material.tipo),
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

            // Conteúdo do material
            Expanded(
              child: _buildConteudoMaterial(
                context,
              ), // Passar context aqui também
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConteudoMaterial(BuildContext context) {
    // Receber context como parâmetro
    switch (material.tipo) {
      case 'imagem':
        return Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: material.url != null && material.url!.isNotEmpty
                ? Image.network(
                    material.url!,
                    fit: BoxFit.contain,
                    // No loadingBuilder da imagem:
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.azulClaro,
                          ), // AZUL
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red),
                            SizedBox(height: 16),
                            Text('Erro ao carregar imagem'),
                          ],
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('Imagem não disponível'),
                      ],
                    ),
                  ),
          ),
        );

      case 'pdf':
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Visualizador PDF',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('O visualizador de PDF será implementado em breve'),
              SizedBox(height: 8),
              Text('Use o botão de download para baixar o arquivo'),
            ],
          ),
        );

      case 'link':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.link, size: 64, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                'Link Externo',
                style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 16),
              if (material.url != null && material.url!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SelectableText(
                    material.url!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Aqui você pode implementar a abertura do link
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Abrindo: ${material.url}'),
                        backgroundColor: AppColors.azulClaro,
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir Link'),
                ),
              ] else ...[
                const Text('URL não disponível'),
              ],
            ],
          ),
        );

      case 'atividade':
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.assignment, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                'Atividade',
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (material.descricao != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    material.descricao!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (material.peso > 0)
                Text(
                  'Peso: ${material.peso}%',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Implementar submissão da atividade
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sistema de submissão em desenvolvimento'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text('Enviar Resposta'),
              ),
            ],
          ),
        );

      default:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Tipo de material não suportado'),
            ],
          ),
        );
    }
  }

  void _baixarMaterial(BuildContext context) {
    // Receber context como parâmetro
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Iniciando download de ${material.titulo}'),
        backgroundColor: AppColors.azulClaro,
      ),
    );
  }

  String _formatarData(DateTime data) {
    return '${data.day}/${data.month}/${data.year} às ${data.hour}:${data.minute.toString().padLeft(2, '0')}';
  }

  Color _getMaterialColor(String tipo) {
    switch (tipo) {
      case 'pdf':
        return Colors.red;
      case 'imagem':
        return Colors.green;
      case 'link':
        return Colors.blue;
      case 'atividade':
        return Colors.orange;
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
}
