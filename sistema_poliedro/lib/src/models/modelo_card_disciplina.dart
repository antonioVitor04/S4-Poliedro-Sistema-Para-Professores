// models/card_disciplina.dart
class CardDisciplina {
  final String id;
  final String imagem;
  final String icone;
  final String titulo;
  final String slug;
  final String url;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TopicoDisciplina> topicos;

  CardDisciplina({
    required this.id,
    required this.imagem,
    required this.icone,
    required this.titulo,
    required this.slug,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
    required this.topicos,
  });

  factory CardDisciplina.fromJson(Map<String, dynamic> json) {
    return CardDisciplina(
      id: json['_id'] ?? '',
      imagem: json['imagem'] ?? '',
      icone: json['icone'] ?? '',
      titulo: json['titulo'] ?? '',
      slug: json['slug'] ?? '',
      url: json['url'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      topicos: (json['topicos'] as List? ?? [])
          .map((topico) => TopicoDisciplina.fromJson(topico))
          .toList(),
    );
  }
}

class TopicoDisciplina {
  final String id;
  final String titulo;
  final String descricao;
  final int ordem;
  final List<MaterialDisciplina> materiais;
  final DateTime dataCriacao;

  TopicoDisciplina({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.ordem,
    required this.materiais,
    required this.dataCriacao,
  });

  factory TopicoDisciplina.fromJson(Map<String, dynamic> json) {
    return TopicoDisciplina(
      id: json['_id'] ?? json['id'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      ordem: json['ordem'] ?? 0,
      materiais: (json['materiais'] as List? ?? [])
          .map((material) => MaterialDisciplina.fromJson(material))
          .toList(),
      dataCriacao: json['dataCriacao'] != null 
          ? DateTime.parse(json['dataCriacao']) 
          : DateTime.now(),
    );
  }
}

class MaterialDisciplina {
  final String id;
  final String tipo;
  final String titulo;
  final String? descricao;
  final String? url;
  final double peso;
  final DateTime? prazo;
  final DateTime dataCriacao;
  final int ordem;

  MaterialDisciplina({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.descricao,
    this.url,
    required this.peso,
    this.prazo,
    required this.dataCriacao,
    required this.ordem,
  });

  factory MaterialDisciplina.fromJson(Map<String, dynamic> json) {
    return MaterialDisciplina(
      id: json['_id'] ?? json['id'] ?? '',
      tipo: json['tipo'] ?? '',
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'],
      url: json['url'],
      peso: (json['peso'] as num?)?.toDouble() ?? 0.0,
      prazo: json['prazo'] != null ? DateTime.parse(json['prazo']) : null,
      dataCriacao: DateTime.parse(json['dataCriacao']),
      ordem: json['ordem'] ?? 0,
    );
  }
}