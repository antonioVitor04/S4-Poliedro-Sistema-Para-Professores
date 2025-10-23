enum TipoUsuario { aluno, professor }

class Usuario {
  final String id;
  final String nome;
  final String email;
  final String? ra;
  final String tipo;
  final String? fotoUrl;
  final bool hasImage;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.ra,
    required this.tipo,
    this.fotoUrl,
    this.hasImage = false,
  });

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? ra,
    String? tipo,
    String? fotoUrl,
    bool? hasImage,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      ra: ra ?? this.ra,
      tipo: tipo ?? this.tipo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      hasImage: hasImage ?? this.hasImage,
    );
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? json['_id'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      ra: json['ra'],
      tipo: json['tipo'] ?? 'aluno', // O tipo vem do JSON
      fotoUrl: json['fotoUrl'],
      hasImage: json['hasImage'] ?? json['fotoUrl'] != null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      if (ra != null) 'ra': ra,
      'tipo': tipo,
      if (fotoUrl != null) 'fotoUrl': fotoUrl,
      'hasImage': hasImage,
    };
  }

  // Método auxiliar para converter para TipoUsuario enum
  TipoUsuario get tipoUsuario {
    switch (tipo.toLowerCase()) {
      case 'professor':
      case 'admin':
        return TipoUsuario.professor;
      default:
        return TipoUsuario.aluno;
    }
  }
}
