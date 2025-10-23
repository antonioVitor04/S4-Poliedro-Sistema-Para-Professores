// Submodelo para Avaliações (provas/atividades)
class Avaliacao {
  final String id;
  final String nome;
  final String tipo; // Added: tipo from backend schema
  final double? nota;
  final double? peso;
  final DateTime? data;

  Avaliacao({
    required this.id,
    required this.nome,
    required this.tipo,
    this.nota,
    this.peso,
    this.data,
  });

  Avaliacao copyWith({
    String? id,
    String? nome,
    String? tipo,
    double? nota,
    double? peso,
    DateTime? data,
  }) {
    return Avaliacao(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      nota: nota ?? this.nota,
      peso: peso ?? this.peso,
      data: data ?? this.data,
    );
  }

  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      id: json['_id'] ?? json['id'] ?? '',
      nome: json['nome'] ?? '',
      tipo: json['tipo'] ?? '',
      nota: (json['nota'] as num?)?.toDouble(),
      peso: (json['peso'] as num?)?.toDouble(),
      data: json['data'] != null ? DateTime.parse(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nome': nome,
      'tipo': tipo,
      'nota': nota,
      'peso': peso,
      if (data != null) 'data': data!.toIso8601String(),
    };
  }
}
