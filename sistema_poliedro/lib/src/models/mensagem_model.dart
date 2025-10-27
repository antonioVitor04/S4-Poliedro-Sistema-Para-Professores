// models/mensagem_model.dart
import 'dart:convert';

class Mensagem {
  final String id;
  final String data;
  final String remetente;
  final String materia;
  final String conteudo;
  final String disciplinaId;
  final String fotoProfessor;
  final bool isFotoBase64;

  bool isUnread;
  bool isFavorita;
  bool isSelected;

  Mensagem({
    required this.id,
    required this.data,
    required this.remetente,
    required this.materia,
    required this.conteudo,
    required this.disciplinaId,
    this.fotoProfessor = '',
    this.isFotoBase64 = false,
    this.isUnread = true,
    this.isFavorita = false,
    this.isSelected = false,
  });

  // Função para detectar Base64
  static bool _isBase64(String str) {
    if (str.isEmpty) return false;

    if (str.startsWith('data:image/')) {
      return true;
    }

    try {
      String cleanStr = str;
      if (str.contains(',')) {
        final parts = str.split(',');
        if (parts.length == 2) {
          cleanStr = parts[1];
        }
      }

      final regex = RegExp(r'^[a-zA-Z0-9+/]*={0,2}$');
      final isValid = regex.hasMatch(cleanStr);

      if (isValid && cleanStr.length >= 4) {
        try {
          base64.decode(cleanStr);
          return true;
        } catch (e) {
          return false;
        }
      }

      return isValid;
    } catch (e) {
      return false;
    }
  }

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    // Tratamento para disciplina
    String materia = 'Disciplina';
    String disciplinaId = '';

    if (json['disciplina'] != null) {
      if (json['disciplina'] is String) {
        disciplinaId = json['disciplina'];
        materia = 'Disciplina';
      } else if (json['disciplina'] is Map) {
        final disciplina = json['disciplina'] as Map<String, dynamic>;
        disciplinaId = disciplina['_id']?.toString() ?? '';
        materia =
            disciplina['titulo']?.toString() ??
            disciplina['nome']?.toString() ??
            'Disciplina';
      }
    }

    // Tratamento para professor
    String remetente = 'Professor';
    String fotoProfessor = '';
    bool isFotoBase64 = false;

    if (json['professor'] != null) {
      if (json['professor'] is String) {
        remetente = 'Professor';
      } else if (json['professor'] is Map) {
        final professor = json['professor'] as Map<String, dynamic>;
        remetente =
            professor['nome']?.toString() ??
            professor['nomeCompleto']?.toString() ??
            'Professor';
        fotoProfessor = professor['foto']?.toString() ?? '';

        if (fotoProfessor.isNotEmpty) {
          isFotoBase64 = _isBase64(fotoProfessor);
        }
      }
    }

    // Tratamento seguro para data
    String data = '';
    if (json['dataCriacao'] != null) {
      try {
        final dateTime = DateTime.parse(json['dataCriacao'].toString());
        data =
            '${dateTime.day.toString().padLeft(2, '0')}/'
            '${dateTime.month.toString().padLeft(2, '0')}/'
            '${dateTime.year}';
      } catch (e) {
        data = 'Data inválida';
      }
    }

    return Mensagem(
      id: json['_id']?.toString() ?? '',
      data: data,
      remetente: remetente,
      materia: materia,
      conteudo: json['mensagem']?.toString() ?? '',
      disciplinaId: disciplinaId,
      fotoProfessor: fotoProfessor,
      isFotoBase64: isFotoBase64,
      isUnread: json['lida'] == false,
      isFavorita: json['favorita'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'dataCriacao': data,
      'professor': {'nome': remetente},
      'disciplina': {'_id': disciplinaId, 'titulo': materia},
      'mensagem': conteudo,
      'lida': !isUnread,
      'favorita': isFavorita,
    };
  }
}
