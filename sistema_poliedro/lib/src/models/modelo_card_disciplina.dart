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

  CardDisciplina({
    required this.id,
    required this.imagem,
    required this.icone,
    required this.titulo,
    required this.slug,
    required this.url,
    required this.createdAt,
    required this.updatedAt,
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
    );
  }
}