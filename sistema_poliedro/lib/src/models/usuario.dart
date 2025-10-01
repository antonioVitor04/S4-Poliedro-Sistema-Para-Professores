enum TipoUsuario { aluno, professor }

class Usuario {
  final String id;
  final String nome;
  final String? email;
  final String? ra;
  final TipoUsuario tipo;
  final bool hasImage;

  Usuario({
    required this.id,
    required this.nome,
    this.email,
    this.ra,
    required this.tipo,
    required this.hasImage,
  });

  factory Usuario.fromJson(Map<String, dynamic> json, TipoUsuario tipo) {
    return Usuario(
      id: json['_id'] ?? json['id'] ?? '',
      nome: json['nome'] ?? '',
      email: json['email'],
      ra: json['ra'],
      tipo: tipo,
      hasImage: json['hasImage'] ?? false,
    );
  }

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? ra,
    TipoUsuario? tipo,
    bool? hasImage,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      ra: ra ?? this.ra,
      tipo: tipo ?? this.tipo,
      hasImage: hasImage ?? this.hasImage,
    );
  }
}
