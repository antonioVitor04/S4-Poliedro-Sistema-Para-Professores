import './modelo_usuario.dart';
import './modelo_nota.dart';

// NOVO MODELO PARA DISCIPLINAS (para gerenciar notas)
class Disciplina {
  final String id;
  final String titulo;
  final List<Nota> notas; // Lista de notas populadas com alunos
  final List<Usuario> alunos; // Lista de alunos matriculados

  Disciplina({
    required this.id,
    required this.titulo,
    required this.notas,
    required this.alunos,
  });

  factory Disciplina.fromJson(Map<String, dynamic> json) {
    return Disciplina(
      id: json['_id'] ?? json['id']!,
      titulo: json['titulo']!,
      alunos: (json['alunos'] as List<dynamic>? ?? [])
          .map<Usuario>((a) => Usuario.fromJson(a))
          .toList(),
      notas: (json['notas'] as List<dynamic>? ?? [])
          .map<Nota>((n) => Nota.fromJson(n))
          .toList(),
    );
  }
}
