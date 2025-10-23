import './modelo_avaliacao.dart';

// NOVO MODELO PARA NOTAS
class Nota {
  final String id;
  final String disciplinaId;
  final String alunoId;
  final String alunoNome;
  final String? alunoRa;
  final List<Avaliacao> avaliacoes;

  Nota({
    required this.id,
    required this.disciplinaId,
    required this.alunoId,
    required this.alunoNome,
    this.alunoRa,
    required this.avaliacoes,
  });

  Nota copyWith({
    String? id,
    String? disciplinaId,
    String? alunoId,
    String? alunoNome,
    String? alunoRa,
    List<Avaliacao>? avaliacoes,
  }) {
    return Nota(
      id: id ?? this.id,
      disciplinaId: disciplinaId ?? this.disciplinaId,
      alunoId: alunoId ?? this.alunoId,
      alunoNome: alunoNome ?? this.alunoNome,
      alunoRa: alunoRa ?? this.alunoRa,
      avaliacoes: avaliacoes ?? this.avaliacoes,
    );
  }

  factory Nota.fromJson(Map<String, dynamic> json) {
    return Nota(
      id: json['_id'] ?? json['id']!,
      disciplinaId: json['disciplina'] ?? '',
      alunoId: json['aluno'] ?? '',
      alunoNome: json['alunoNome'] ?? '',
      alunoRa: json['alunoRa'],
      avaliacoes: (json['avaliacoes'] as List<dynamic>? ?? [])
          .map<Avaliacao>((a) => Avaliacao.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'disciplina': disciplinaId,
      'aluno': alunoId,
      'avaliacoes': avaliacoes.map((a) => a.toJson()).toList(),
    };
  }
}
