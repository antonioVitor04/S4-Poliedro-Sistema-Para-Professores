// models/modelo_comentario.dart
class Comentario {
  final String id;
  final String materialId;
  final String topicoId;
  final String disciplinaId;
  final Map<String, dynamic> autor;
  final String autorModel;
  final String texto;
  final List<Comentario> respostas;
  final DateTime dataCriacao;
  final DateTime? dataEdicao;
  final bool editado;

  Comentario({
    required this.id,
    required this.materialId,
    required this.topicoId,
    required this.disciplinaId,
    required this.autor,
    required this.autorModel,
    required this.texto,
    required this.respostas,
    required this.dataCriacao,
    this.dataEdicao,
    required this.editado,
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    // Função auxiliar para parse de data
    DateTime parseData(dynamic data) {
      if (data == null) return DateTime.now();
      if (data is String) {
        try {
          return DateTime.parse(data).toLocal();
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Função auxiliar para parse do autor
    Map<String, dynamic> parseAutor(dynamic autorData) {
      if (autorData is Map) {
        return Map<String, dynamic>.from(autorData);
      } else if (autorData is String) {
        return {'_id': autorData, 'nome': 'Usuário'};
      }
      return {'nome': 'Usuário'};
    }

    // Função auxiliar para parse de respostas
    List<Comentario> parseRespostas(dynamic respostasData) {
      if (respostasData is List) {
        return respostasData.map((item) => Comentario.fromJson(item)).toList();
      }
      return [];
    }

    return Comentario(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      materialId: json['materialId']?.toString() ?? '',
      topicoId: json['topicoId']?.toString() ?? '',
      disciplinaId: json['disciplinaId']?.toString() ?? '',
      autor: parseAutor(json['autor']),
      autorModel: json['autorModel']?.toString() ?? 'Aluno',
      texto: json['texto']?.toString() ?? '',
      respostas: parseRespostas(json['respostas']),
      dataCriacao: parseData(json['dataCriacao']),
      dataEdicao: json['dataEdicao'] != null ? parseData(json['dataEdicao']) : null,
      editado: json['editado'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'materialId': materialId,
      'topicoId': topicoId,
      'disciplinaId': disciplinaId,
      'autor': autor,
      'autorModel': autorModel,
      'texto': texto,
      'respostas': respostas.map((resposta) => resposta.toJson()).toList(),
      'dataCriacao': dataCriacao.toIso8601String(),
      'dataEdicao': dataEdicao?.toIso8601String(),
      'editado': editado,
    };
  }
}