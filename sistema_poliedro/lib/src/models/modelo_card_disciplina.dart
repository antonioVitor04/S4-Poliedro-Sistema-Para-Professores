import 'package:sistema_poliedro/src/services/auth_service.dart';

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
  final List<dynamic> professores; // Pode ser String (ID) ou Map (objeto completo)
  final List<dynamic> alunos; // Pode ser String (ID) ou Map (objeto completo)
  final dynamic criadoPor; // Pode ser String (ID) ou Map (objeto completo)

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
    required this.professores,
    required this.alunos,
    required this.criadoPor,
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
      professores: json['professores'] ?? [],
      alunos: json['alunos'] ?? [],
      criadoPor: json['criadoPor'] ?? '',
    );
  }

  // Método para obter informações do criador formatadas
  String get infoCriador {
    if (criadoPor is String) {
      return 'Professor'; // Fallback se for apenas ID
    } else if (criadoPor is Map) {
      final nome = criadoPor['nome'] ?? 'Professor';
      final email = criadoPor['email'] ?? '';
      return email.isNotEmpty ? '$nome ($email)' : nome;
    }
    return 'Professor';
  }

  // Método para obter apenas o nome do criador
  String get nomeCriador {
    if (criadoPor is String) {
      return 'Professor';
    } else if (criadoPor is Map) {
      return criadoPor['nome'] ?? 'Professor';
    }
    return 'Professor';
  }

  // Método para obter apenas o email do criador
  String get emailCriador {
    if (criadoPor is String) {
      return '';
    } else if (criadoPor is Map) {
      return criadoPor['email'] ?? '';
    }
    return '';
  }

  // Método para obter o ID do criador
  String get idCriador {
    if (criadoPor is String) {
      return criadoPor;
    } else if (criadoPor is Map) {
      return criadoPor['_id'] ?? '';
    }
    return '';
  }

  // Método para verificar se o usuário atual é professor desta disciplina
  Future<bool> isProfessorDaDisciplina() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return false;
    
    // Verificar se é o criador
    if (idCriador == userId) return true;
    
    // Verificar se está na lista de professores
    final isProfessor = professores.any((professor) {
      if (professor is String) {
        return professor == userId;
      } else if (professor is Map) {
        return professor['_id'] == userId;
      }
      return false;
    });
    
    return isProfessor;
  }

  // Método para verificar se o usuário atual é aluno desta disciplina
  Future<bool> isAlunoDaDisciplina() async {
    final userId = await AuthService.getUserId();
    if (userId == null) return false;
    
    return alunos.any((aluno) {
      if (aluno is String) {
        return aluno == userId;
      } else if (aluno is Map) {
        return aluno['_id'] == userId;
      }
      return false;
    });
  }

  // Método para verificar se o usuário atual pode editar a disciplina
  Future<bool> podeEditar() async {
    if (await AuthService.isAdmin()) return true;
    if (!await AuthService.isProfessor()) return false;
    
    return await isProfessorDaDisciplina();
  }

  // Método para verificar se o usuário atual pode deletar a disciplina
  Future<bool> podeDeletar() async {
    if (await AuthService.isAdmin()) return true;
    if (!await AuthService.isProfessor()) return false;
    
    return await isProfessorDaDisciplina();
  }

  // Método para obter lista de IDs dos professores
  List<String> get professoresIds {
    return professores.map<String>((professor) {
      if (professor is String) {
        return professor;
      } else if (professor is Map) {
        return (professor['_id']?.toString() ?? '');
      }
      return '';
    }).where((id) => id.isNotEmpty).toList();
  }

  // Método para obter lista de IDs dos alunos
  List<String> get alunosIds {
    return alunos.map<String>((aluno) {
      if (aluno is String) {
        return aluno;
      } else if (aluno is Map) {
        return (aluno['_id']?.toString() ?? '');
      }
      return '';
    }).where((id) => id.isNotEmpty).toList();
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
  final String? contentType;
  final String? nomeOriginal;

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
    this.contentType,
    this.nomeOriginal,
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
      contentType: json['arquivo']?['contentType'],
      nomeOriginal: json['arquivo']?['nomeOriginal'],
    );
  }

  bool get hasArquivo => nomeOriginal != null && nomeOriginal!.isNotEmpty;
}