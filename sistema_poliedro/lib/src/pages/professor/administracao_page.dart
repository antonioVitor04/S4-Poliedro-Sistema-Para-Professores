import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:sistema_poliedro/src/pages/professor/notas.dart';
import 'dart:convert';
import 'package:sistema_poliedro/src/services/auth_service.dart'; // MUDANÇA: Importar AuthService
import '../../styles/cores.dart';
import '../../styles/fontes.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Modelo de dados
class Usuario {
  final String id;
  final String nome;
  final String email;
  final String? ra;
  final String tipo;
  final String? fotoUrl;

  Usuario({
    required this.id,
    required this.nome,
    required this.email,
    this.ra,
    required this.tipo,
    this.fotoUrl,
  });

  Usuario copyWith({
    String? id,
    String? nome,
    String? email,
    String? ra,
    String? tipo,
    String? fotoUrl,
  }) {
    return Usuario(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      email: email ?? this.email,
      ra: ra ?? this.ra,
      tipo: tipo ?? this.tipo,
      fotoUrl: fotoUrl ?? this.fotoUrl,
    );
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? json['_id']!,
      nome: json['nome']!,
      email: json['email']!,
      ra: json['ra'],
      tipo: json['tipo'] ?? 'aluno',
      fotoUrl: json['fotoUrl'],
    );
  }
}

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

class AdministracaoPage extends StatefulWidget {
  final bool isAdmin;

  const AdministracaoPage({super.key, required this.isAdmin});

  @override
  State<AdministracaoPage> createState() => _AdministracaoPageState();
}

class _AdministracaoPageState extends State<AdministracaoPage>
    with TickerProviderStateMixin {
  // Variáveis para usuários
  List<Usuario> usuarios = [];
  bool mostrarAlunos = true;
  bool carregando = false;
  late TextEditingController _searchController;
  String _searchQuery = '';
  late AnimationController _fabAnimationController;
  Animation<double>? _fabScaleAnimation;
  // Nova variável para toggle entre usuários e notas
  bool mostrarNotas = false;
  // Variáveis para notas
  List<Disciplina> disciplinas = [];
  bool carregandoNotas = false;
  late TextEditingController _searchNotasController;
  String _searchNotasQuery = '';
  String? selectedDisciplineId; // NOVA: ID da disciplina selecionada
  String? token;
  static const String apiBaseUrl =
      '/api'; // MUDANÇA: Usar baseUrl do AuthService + este path
  static const String cardsDisciplinasPath = '/cardsDisciplinas';
  static const String notasPath = '/notas';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchNotasController = TextEditingController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();

    // Inicializar token primeiro, depois carregar dados
    _initializeToken().then((_) {
      if (mounted && token != null) {
        _carregarUsuarios();
      }
    });
  }

  Future<void> _initializeToken() async {
    try {
      // Obter token do AuthService
      final authToken = await AuthService.getToken();
      if (authToken != null && mounted) {
        setState(() {
          token = authToken;
        });
      } else if (mounted) {
        // Aguardar até que o contexto esteja pronto para mostrar erros
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showError('Token não encontrado. Faça login novamente.');
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showError('Erro ao carregar token: $e');
        });
      }
    }
  }

  Future<void> _initializeData() async {
    // NOVO: Método para inicializar tudo
    await _loadToken();
    if (token != null && mounted) {
      _carregarUsuarios();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchNotasController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final authToken = await AuthService.getToken();
    if (authToken == null && mounted) {
      _showError('Token não encontrado. Faça login novamente.');
      return;
    }

    if (mounted) {
      setState(() {
        token = authToken;
      });
    }
  }

  Map<String, String> _getImageHeaders() {
    if (token == null) return {};
    return {'Authorization': 'Bearer $token'};
  }

  Usuario _corrigirFotoUrl(Usuario user) {
    if (user.fotoUrl != null && user.fotoUrl!.contains('localhost')) {
      final String tipoEndpoint = user.tipo == 'aluno'
          ? 'alunos'
          : 'professores';
      final String imageEndpoint = '/$tipoEndpoint/image/${user.id}';
      final String correctedUrl =
          AuthService.baseUrl + apiBaseUrl + imageEndpoint;

      return user.copyWith(fotoUrl: correctedUrl);
    }
    return user;
  }

  Future<void> _carregarUsuarios() async {
    if (token == null) {
      _showError('Token não encontrado. Faça login novamente.');
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final headers =
          await AuthService.getAuthHeaders(); // MUDANÇA: Usar headers do AuthService
      String endpoint = mostrarAlunos ? '/alunos/list' : '/professores/list';
      final url = Uri.parse(
        AuthService.baseUrl + apiBaseUrl + endpoint,
      ); // MUDANÇA: Usar baseUrl do AuthService
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          usuarios = data.map<Usuario>((json) {
            final user = Usuario.fromJson(json);
            return _corrigirFotoUrl(user);
          }).toList();
          carregando = false;
        });
      } else {
        throw Exception(
          'Falha ao carregar: ${response.statusCode} - ${response.body}',
        ); // MUDANÇA: Incluir body no erro
      }
    } catch (e) {
      setState(() {
        carregando = false;
      });
      _showError('Erro ao carregar usuários: $e');
    }
  }

  // NOVOS MÉTODOS PARA NOTAS
  Future<void> _carregarNotasData() async {
    if (token == null) return;
    setState(() => carregandoNotas = true);
    try {
      await _carregarDisciplinas();
    } catch (e) {
      _showError('Erro ao carregar dados de notas: $e');
    } finally {
      if (mounted) setState(() => carregandoNotas = false);
    }
  }

  // MODIFIQUE o método _carregarDisciplinas para aceitar um parâmetro opcional:
  Future<void> _carregarDisciplinas({bool silent = false}) async {
    final headers = await AuthService.getAuthHeaders();
    final url = Uri.parse(
      AuthService.baseUrl + apiBaseUrl + cardsDisciplinasPath,
    );
    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseMap = json.decode(response.body);
      final List<dynamic> data = responseMap['data'] ?? [];

      final List<Disciplina> loadedDisciplinas = [];
      for (final Map<String, dynamic> discJson in data) {
        final disciplinaId = discJson['_id'] ?? discJson['id'];
        final notasUrl = Uri.parse(
          AuthService.baseUrl + apiBaseUrl + notasPath + '/$disciplinaId',
        );
        List<dynamic> notasData = [];
        try {
          final notasResponse = await http.get(notasUrl, headers: headers);

          if (notasResponse.statusCode == 200) {
            final notasMap = json.decode(notasResponse.body);
            notasData = notasMap['data'] ?? [];
          } else {
            debugPrint(
              '=== DEBUG: Falha ao carregar notas (status ${notasResponse.statusCode}), usando lista vazia ===',
            );
          }
        } catch (e) {
          debugPrint(
            '=== DEBUG: Erro ao carregar notas: $e, usando lista vazia ===',
          );
        }
        final disciplina = Disciplina.fromJson({
          ...discJson,
          'notas': notasData,
        });
        loadedDisciplinas.add(disciplina);
      }
      setState(() {
        disciplinas = loadedDisciplinas;
      });

      // SÓ MOSTRA ALERTA SE NÃO FOR SILENCIOSO
    } else {
      // SÓ MOSTRA ERRO SE NÃO FOR SILENCIOSO
      if (!silent) {
        throw Exception(
          'Falha ao carregar disciplinas: ${response.statusCode}',
        );
      }
    }
  }

  Future<void> _criarNota(Nota nota, {bool silent = false}) async {
    final headers = await AuthService.getAuthHeaders();
    final url = Uri.parse(AuthService.baseUrl + apiBaseUrl + notasPath);
    final response = await http.post(
      url,
      headers: headers,
      body: json.encode(nota.toJson()),
    );

    if (response.statusCode == 201) {
      if (!silent) {
        _showSuccess('Nota criada com sucesso!');
      }
      await _carregarDisciplinas(silent: true);
    } else {
      throw Exception(
        'Falha ao criar nota: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> _atualizarNota(
    String notaId,
    Nota notaAtualizada, {
    bool silent = false,
  }) async {
    final headers = await AuthService.getAuthHeaders();
    final url = Uri.parse(
      AuthService.baseUrl + apiBaseUrl + notasPath + '/$notaId',
    );
    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(notaAtualizada.toJson()),
    );

    if (response.statusCode == 200) {
      if (!silent) {
        _showSuccess('Nota atualizada com sucesso!');
      }
      await _carregarDisciplinas(silent: true);
    } else {
      throw Exception(
        'Falha ao atualizar nota: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> _deletarNota(String notaId, {bool silent = false}) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoção'),
        content: const Text('Deseja remover esta nota?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final headers = await AuthService.getAuthHeaders();
      final url = Uri.parse(
        AuthService.baseUrl + apiBaseUrl + notasPath + '/$notaId',
      );
      final response = await http.delete(url, headers: headers);

      if (response.statusCode == 200) {
        if (!silent) {
          _showSuccess('Nota removida com sucesso!');
        }
        await _carregarDisciplinas(silent: true);
      } else {
        throw Exception(
          'Falha ao remover nota: ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  Future<void> _showAddEditNotaDialog({
    required Disciplina disciplina,
    Nota? nota,
    Usuario? selectedAluno,
  }) async {
    final result = await showDialog<Nota?>(
      context: context,
      builder: (context) => NotaDialog(
        disciplina: disciplina,
        nota: nota,
        selectedAluno: selectedAluno,
      ),
    );
    if (result != null) {
      try {
        if (nota == null) {
          await _criarNota(result);
        } else {
          await _atualizarNota(nota.id, result);
        }
      } catch (e) {
        _showError('Erro ao salvar nota: $e');
      }
    }
  }

  Future<void> _addGlobalAvaliacao(Disciplina disciplina) async {
    final newAv = await showDialog<Avaliacao?>(
      context: context,
      builder: (context) => AddGlobalAvaliacaoDialog(disciplina: disciplina),
    );
    if (newAv != null) {
      bool hasError = false;
      String? errorMessage;

      try {
        // Primeiro, criar todas as notas/atualizações
        for (final aluno in disciplina.alunos) {
          Nota? existingNota = disciplina.notas.firstWhereOrNull(
            (n) => n.alunoId == aluno.id,
          );
          final avaliacoes = List<Avaliacao>.from(
            existingNota?.avaliacoes ?? [],
          );
          final existingAv = avaliacoes.firstWhereOrNull(
            (a) => a.nome == newAv.nome && a.tipo == newAv.tipo,
          );
          if (existingAv == null) {
            avaliacoes.add(newAv.copyWith(nota: 0.0));
          }
          final notaToSave =
              existingNota?.copyWith(avaliacoes: avaliacoes) ??
              Nota(
                id: '',
                disciplinaId: disciplina.id,
                alunoId: aluno.id,
                alunoNome: aluno.nome,
                alunoRa: aluno.ra,
                avaliacoes: avaliacoes,
              );
          if (existingNota == null) {
            await _criarNota(notaToSave, silent: true); // MODIFICADO
          } else {
            await _atualizarNota(
              existingNota.id,
              notaToSave,
              silent: true,
            ); // MODIFICADO
          }
        }

        // DEPOIS de todas as operações, recarregar e mostrar alerta UMA VEZ
        await _carregarDisciplinas(silent: true);
        _showSuccess(
          'Avaliação "${newAv.nome}" adicionada para todos os alunos com nota padrão 0!',
        );
      } catch (e) {
        hasError = true;
        errorMessage = e.toString();
      }

      if (hasError) {
        _showError('Erro ao adicionar avaliação: $errorMessage');
      }
    }
  }

  // NOVO MÉTODO: Gerenciar avaliações globais
  Future<void> _manageAvaliacoes(Disciplina disciplina) async {
    final Map<String, Avaliacao> uniqueAvs = <String, Avaliacao>{};
    for (final nota in disciplina.notas) {
      for (final av in nota.avaliacoes) {
        if (!uniqueAvs.containsKey(av.nome)) {
          uniqueAvs[av.nome] = av.copyWith();
        }
      }
    }
    final uniqueList = uniqueAvs.values.toList();

    await showDialog<void>(
      context: context,
      builder: (context) => ManageAvaliacoesDialog(
        disciplina: disciplina,
        uniqueAvaliacoes: uniqueList,
        onEdit: (oldNome, oldTipo, newAv) =>
            _updateGlobalAvaliacao(disciplina, oldNome, oldTipo, newAv),
        onDelete: (nome, tipo) =>
            _deleteGlobalAvaliacao(disciplina, nome, tipo),
      ),
    );
  }

  Future<void> _updateGlobalAvaliacao(
    Disciplina disciplina,
    String oldNome,
    String oldTipo,
    Avaliacao newAv,
  ) async {
    bool hasError = false;
    String? errorMessage;

    try {
      // Primeiro, fazer todas as atualizações
      for (final nota in disciplina.notas) {
        final avIndex = nota.avaliacoes.indexWhere(
          (a) => a.nome == oldNome && a.tipo == oldTipo,
        );
        if (avIndex != -1) {
          final updatedAv = nota.avaliacoes[avIndex].copyWith(
            nome: newAv.nome,
            tipo: newAv.tipo,
            peso: newAv.peso,
          );
          final updatedAvaliacoes = List<Avaliacao>.from(nota.avaliacoes);
          updatedAvaliacoes[avIndex] = updatedAv;
          final updatedNota = nota.copyWith(avaliacoes: updatedAvaliacoes);
          await _atualizarNota(nota.id, updatedNota, silent: true);
        }
      }

      // DEPOIS de todas as operações, recarregar e mostrar alerta UMA VEZ
      await _carregarDisciplinas(silent: true);
      _showSuccess('Avaliação atualizada com sucesso!');
    } catch (e) {
      hasError = true;
      errorMessage = e.toString();
    }

    if (hasError) {
      _showError('Erro ao atualizar avaliação: $errorMessage');
    }
  }

  Future<void> _deleteGlobalAvaliacao(
    Disciplina disciplina,
    String nome,
    String tipo,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoção'),
        content: Text('Deseja remover a avaliação "$nome" de todos os alunos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.vermelho,
            ),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    bool hasError = false;
    String? errorMessage;

    try {
      // Primeiro, fazer todas as remoções
      for (final nota in disciplina.notas) {
        final updatedAvaliacoes = nota.avaliacoes
            .where((a) => !(a.nome == nome && a.tipo == tipo))
            .toList();
        if (updatedAvaliacoes.length < nota.avaliacoes.length) {
          final updatedNota = nota.copyWith(avaliacoes: updatedAvaliacoes);
          await _atualizarNota(nota.id, updatedNota, silent: true);
        }
      }

      // DEPOIS de todas as operações, recarregar e mostrar alerta UMA VEZ
      await _carregarDisciplinas(silent: true);
      _showSuccess('Avaliação removida com sucesso!');
    } catch (e) {
      hasError = true;
      errorMessage = e.toString();
    }

    if (hasError) {
      _showError('Erro ao remover avaliação: $errorMessage');
    }
  }

  // NOVA FUNÇÃO: Enviar senha inicial via API
  Future<void> _sendInitialPassword(String email, String tipo) async {
    if (token == null) {
      _showError('Token não encontrado. Faça login novamente.');
      return;
    }

    try {
      final headers = await AuthService.getAuthHeaders();
      final url = Uri.parse(
        AuthService.baseUrl + apiBaseUrl + '/enviarEmail/enviar-senha-inicial',
      );
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode({'email': email, 'tipo': tipo}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Falha ao enviar senha inicial: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      // Não falha o processo de criação, apenas loga erro
      _showError(
        'Usuário criado, mas falha ao enviar senha: $e. Tente reenviar manualmente.',
      );
      rethrow; // Opcional: para capturar no caller se necessário
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.vermelhoErro,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _onSearchNotasChanged(String query) {
    setState(() {
      _searchNotasQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _clearSearchNotas() {
    setState(() {
      _searchNotasQuery = '';
      _searchNotasController.clear();
    });
  }

  List<Usuario> _getUsuariosFiltrados() {
    final listaSegura = usuarios;

    if (listaSegura.isEmpty) {
      return [];
    }

    var filtrados = listaSegura.where((usuario) {
      if (widget.isAdmin) {
        return mostrarAlunos
            ? usuario.tipo == 'aluno'
            : (usuario.tipo == 'professor' ||
                  usuario.tipo ==
                      'admin'); // CORREÇÃO: Incluir admins na lista de professores
      } else {
        return usuario.tipo == 'aluno';
      }
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filtrados = filtrados.where((usuario) {
        final query = _searchQuery.toLowerCase();
        return usuario.nome.toLowerCase().contains(query) ||
            usuario.email.toLowerCase().contains(query) ||
            (usuario.ra != null && usuario.ra!.toLowerCase().contains(query));
      }).toList();
    }

    return filtrados;
  }

  List<Disciplina> _getDisciplinasFiltradas() {
    var filtradas = disciplinas;
    if (_searchNotasQuery.isNotEmpty) {
      filtradas = disciplinas.where((d) {
        final query = _searchNotasQuery.toLowerCase();
        return d.titulo.toLowerCase().contains(query);
      }).toList();
    }
    return filtradas;
  }

  Future<void> _showUserDialog({Usuario? usuario}) async {
    final bool isEdit = usuario != null;
    final bool isAluno = usuario?.tipo == 'aluno' || mostrarAlunos;

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext dialogContext) => UserDialog(
        usuario: usuario,
        isEdit: isEdit,
        isAluno: isAluno,
        token: token,
      ),
    );

    if (result != null) {
      // MUDANÇA: Removido check de token aqui, pois headers são async
      try {
        final headers =
            await AuthService.getAuthHeaders(); // MUDANÇA: Usar headers do AuthService
        if (isEdit) {
          // Update
          String endpoint = usuario!.tipo == 'aluno'
              ? '/alunos'
              : '/professores';
          final body = <String, dynamic>{
            'nome': result['nome']!,
            'email': result['email']!,
            if (isAluno) 'ra': result['ra']!,
          };
          if (!isAluno && result.containsKey('tipo')) {
            // MUDANÇA: Adicionar tipo para update de professor
            body['tipo'] = result['tipo']!;
          }
          final url = Uri.parse(
            AuthService.baseUrl + apiBaseUrl + endpoint + '/' + usuario.id,
          ); // MUDANÇA: Usar baseUrl
          final response = await http.put(
            url,
            headers: headers,
            body: json.encode(body),
          );

          if (response.statusCode == 200) {
            final decodedBody = json.decode(response.body);
            final updatedData =
                decodedBody['aluno'] ?? decodedBody['professor'];
            var updatedUser = Usuario.fromJson(updatedData!);
            updatedUser = _corrigirFotoUrl(updatedUser);
            final index = usuarios.indexWhere((u) => u.id == usuario.id);
            if (index != -1) {
              setState(() {
                usuarios[index] = updatedUser;
              });
            }
            _showSuccess('${isEdit ? 'Editado' : 'Adicionado'} com sucesso!');
          } else {
            throw Exception(
              'Falha ao atualizar: ${response.statusCode} - ${response.body}',
            ); // MUDANÇA: Incluir body
          }
        } else {
          // Create
          String endpoint = isAluno
              ? '/alunos/register'
              : '/professores/register';
          final body = <String, dynamic>{
            'nome': result['nome']!,
            'email': result['email']!,
            if (isAluno) 'ra': result['ra']!,
          };
          if (!isAluno && result.containsKey('tipo')) {
            // MUDANÇÃO: Adicionar tipo para create de professor
            body['tipo'] = result['tipo']!;
          }
          final url = Uri.parse(
            AuthService.baseUrl + apiBaseUrl + endpoint,
          ); // MUDANÇA: Usar baseUrl
          final response = await http.post(
            url,
            headers: headers,
            body: json.encode(body),
          );

          if (response.statusCode == 201) {
            final decodedBody = json.decode(response.body);
            final newData = decodedBody['aluno'] ?? decodedBody['professor'];
            var newUser = Usuario.fromJson(newData!);
            newUser = _corrigirFotoUrl(newUser);
            setState(() {
              usuarios.add(newUser);
            });

            // NOVA IMPLEMENTAÇÃO: Enviar senha inicial após criação
            await _sendInitialPassword(
              result['email']!, // CORREÇÃO: Usar ! para non-null assertion após validação
              isAluno ? 'aluno' : 'professor',
            );

            _showSuccess(
              'Adicionado com sucesso! Senha inicial enviada por e-mail.',
            );
          } else {
            throw Exception(
              'Falha ao adicionar: ${response.statusCode} - ${response.body}',
            ); // MUDANÇA: Incluir body
          }
        }
      } catch (e) {
        _showError('Erro ao salvar: $e');
      }
    }
  }

  Future<void> _showDeleteDialog(Usuario usuario) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => DeleteDialog(usuario: usuario),
    );

    if (confirm == true) {
      // MUDANÇA: Removido check de token aqui
      try {
        final headers =
            await AuthService.getAuthHeaders(); // MUDANÇA: Usar headers do AuthService
        String endpoint = usuario.tipo == 'aluno' ? '/alunos' : '/professores';
        final url = Uri.parse(
          AuthService.baseUrl + apiBaseUrl + endpoint + '/' + usuario.id,
        ); // MUDANÇA: Usar baseUrl
        final response = await http.delete(url, headers: headers);

        if (response.statusCode == 200) {
          setState(() {
            usuarios.removeWhere((u) => u.id == usuario.id);
          });
          _showSuccess('${usuario.nome} excluído com sucesso!');
        } else {
          throw Exception(
            'Falha ao excluir: ${response.statusCode} - ${response.body}',
          ); // MUDANÇA: Incluir body
        }
      } catch (e) {
        _showError('Erro ao excluir: $e');
      }
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: AppColors.verdeConfirmacao,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _switchToUsuarios() {
    setState(() {
      mostrarNotas = false;
      mostrarAlunos = true;
      selectedDisciplineId = null; // Resetar seleção
    });
    _carregarUsuarios();
  }

  void _switchToNotas() {
    setState(() {
      mostrarNotas = true;
      selectedDisciplineId = null; // Resetar seleção ao entrar em notas
    });
    _carregarNotasData();
  }

  // NOVO MÉTODO: Selecionar disciplina
  void _selectDiscipline(Disciplina disciplina) {
    setState(() {
      selectedDisciplineId = disciplina.id;
    });
  }

  // NOVO MÉTODO: Voltar à lista de disciplinas
  void _backToDisciplines() {
    setState(() {
      selectedDisciplineId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppColors.azulClaro;

    final fabChild = FloatingActionButton.extended(
      onPressed: () => _showUserDialog(),
      backgroundColor: primaryColor,
      foregroundColor: AppColors.branco,
      elevation: 6,
      heroTag: 'add_user',
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add, size: 24, color: AppColors.branco),
          SizedBox(width: 8),
          Text(
            'Adicionar',
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.branco,
            ),
          ),
        ],
      ),
    );

    final positionedFab = _fabScaleAnimation != null
        ? ScaleTransition(scale: _fabScaleAnimation!, child: fabChild)
        : fabChild;

    return Theme(
      data: Theme.of(context).copyWith(
        primaryColor: AppColors
            .cinzaClaro, // Unificado para evitar conflito com roxo padrão
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.cinzaClaro,
          foregroundColor: Colors.black,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppColors.cinzaClaro, // Cor consistente com AppBar
            statusBarIconBrightness: Brightness.dark,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.cinzaClaro,
        appBar: AppBar(
          title: Text(
            "Painel de Administração - ${mostrarNotas ? 'Notas' : 'Usuários'}",
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.grey),
              onPressed: mostrarNotas ? _carregarNotasData : _carregarUsuarios,
            ),
          ],
        ),
        floatingActionButton:
            (!mostrarNotas && (widget.isAdmin || mostrarAlunos))
            ? positionedFab
            : null,
        body: mostrarNotas
            ? _buildNotasBody(primaryColor)
            : _buildUsuariosBody(primaryColor),
      ),
    );
  }

  Widget _buildUsuariosBody(Color primaryColor) {
    final usuariosFiltrados = _getUsuariosFiltrados();
    return Column(
      children: [
        // Header com estatísticas e filtros
        _buildUsuariosHeader(primaryColor, usuariosFiltrados.length),

        // Barra de busca
        _buildSearchBar(),

        // Tabela
        Expanded(
          child: carregando
              ? _buildLoadingState()
              : usuariosFiltrados.isEmpty
              ? _buildEmptyState()
              : _buildDataTable(usuariosFiltrados, primaryColor),
        ),
      ],
    );
  }

  Widget _buildNotasBody(Color primaryColor) {
    final disciplinasFiltradas = _getDisciplinasFiltradas();
    return Column(
      children: [
        // Header para notas
        _buildNotasHeader(primaryColor, disciplinasFiltradas.length),

        // Barra de busca para disciplinas
        _buildSearchNotasBar(),

        // Selecione disciplina ou mostre a tabela
        Expanded(
          child: carregandoNotas
              ? _buildLoadingState()
              : selectedDisciplineId == null
              ? _buildDisciplinesSelector(disciplinasFiltradas, primaryColor)
              : _buildSelectedDisciplineTable(primaryColor),
        ),
      ],
    );
  }

  // NOVO WIDGET: Seletor de disciplinas
  Widget _buildDisciplinesSelector(
    List<Disciplina> disciplinas,
    Color primaryColor,
  ) {
    if (disciplinas.isEmpty) {
      return _buildNotasEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: disciplinas.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final disciplina = disciplinas[index];
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: AppColors.branco,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _selectDiscipline(disciplina),
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.book, color: primaryColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disciplina.titulo,
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.preto,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${disciplina.alunos.length} alunos matriculados',
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // NOVO WIDGET: Tabela da disciplina selecionada
  Widget _buildSelectedDisciplineTable(Color primaryColor) {
    final selectedDiscipline = disciplinas.firstWhereOrNull(
      (d) => d.id == selectedDisciplineId,
    );
    if (selectedDiscipline == null) {
      return const Center(child: Text('Disciplina não encontrada'));
    }

    // NOVO: Calcular média da turma
    double calcularMediaTurma(Disciplina disciplina) {
      double somaMedias = 0.0;
      int alunosComNota = 0;

      for (final aluno in disciplina.alunos) {
        final nota = disciplina.notas.firstWhereOrNull(
          (n) => n.alunoId == aluno.id,
        );
        if (nota != null && nota.avaliacoes.isNotEmpty) {
          double mediaAluno = 0.0;
          double totalPeso = 0.0;

          for (final av in nota.avaliacoes) {
            if (av.nota != null && av.nota! > 0) {
              mediaAluno += (av.nota! * (av.peso ?? 1.0));
              totalPeso += (av.peso ?? 1.0);
            }
          }

          if (totalPeso > 0) {
            mediaAluno = mediaAluno / totalPeso;
            somaMedias += mediaAluno;
            alunosComNota++;
          }
        }
      }

      return alunosComNota > 0 ? somaMedias / alunosComNota : 0.0;
    }

    final mediaTurma = calcularMediaTurma(selectedDiscipline);

    return Column(
      children: [
        // Header com botão de voltar E MÉDIA DA TURMA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _backToDisciplines,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedDiscipline.titulo,
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // NOVO: Exibir média da turma
                    if (mediaTurma > 0)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: mediaTurma >= 6.0
                                  ? AppColors.verdeConfirmacao.withOpacity(0.1)
                                  : AppColors.vermelhoErro.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: mediaTurma >= 6.0
                                    ? AppColors.verdeConfirmacao
                                    : AppColors.vermelhoErro,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mediaTurma >= 6.0
                                      ? Icons.trending_up
                                      : Icons.trending_down,
                                  size: 14,
                                  color: mediaTurma >= 6.0
                                      ? AppColors.verdeConfirmacao
                                      : AppColors.vermelhoErro,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Média da Turma: ${mediaTurma.toStringAsFixed(1)}',
                                  style: AppTextStyles.fonteUbuntuSans.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: mediaTurma >= 6.0
                                        ? AppColors.verdeConfirmacao
                                        : AppColors.vermelhoErro,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Text(
                '${selectedDiscipline.alunos.length} alunos',
                style: AppTextStyles.fonteUbuntuSans.copyWith(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: NotasDataTable(
            key: ValueKey(selectedDiscipline.id),
            disciplina: selectedDiscipline,
            primaryColor: primaryColor,
            onAddGlobalAvaliacao: _addGlobalAvaliacao,
            onManageAvaliacoes: _manageAvaliacoes,
            onCreateNota: _criarNota,
            onUpdateNota: _atualizarNota,
            onReloadDisciplinas: _carregarDisciplinas,
            showSuccess: _showSuccess,
            showError: _showError,
            onMediaTurmaAtualizada: (novaMedia) {
              // Atualiza o estado para refletir a nova média
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsuariosHeader(Color primaryColor, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.branco, AppColors.cinzaClaro],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle principal: Usuários | Notas
          _buildMainToggleButtons(primaryColor),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  mostrarAlunos ? Icons.school : Icons.school_outlined,
                  color: primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isAdmin
                          ? (mostrarAlunos
                                ? 'Gerenciar Alunos'
                                : 'Gerenciar Professores')
                          : 'Gerenciar Alunos',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.preto,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $count ${mostrarAlunos ? 'alunos' : 'professores'}',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (widget.isAdmin && !mostrarNotas)
            _buildToggleButtons(primaryColor),
        ],
      ),
    );
  }

  Widget _buildNotasHeader(Color primaryColor, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.branco, AppColors.cinzaClaro],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle principal: Usuários | Notas
          _buildMainToggleButtons(primaryColor),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.grade, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gerenciar Notas',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.preto,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $count disciplinas',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggleButtons(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            text: 'Usuários',
            isActive: !mostrarNotas,
            primaryColor: primaryColor,
            onTap: _switchToUsuarios,
          ),
          const SizedBox(width: 4),
          _buildToggleButton(
            text: 'Notas',
            isActive: mostrarNotas,
            primaryColor: primaryColor,
            onTap: _switchToNotas,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppColors.preto.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            text: 'Alunos',
            isActive: mostrarAlunos,
            primaryColor: primaryColor,
            onTap: () {
              setState(() => mostrarAlunos = true);
              _carregarUsuarios();
            },
          ),
          const SizedBox(width: 4),
          _buildToggleButton(
            text: 'Professores',
            isActive: !mostrarAlunos,
            primaryColor: primaryColor,
            onTap: () {
              setState(() => mostrarAlunos = false);
              _carregarUsuarios();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isActive,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          style: AppTextStyles.fonteUbuntu.copyWith(
            color: isActive ? AppColors.branco : Colors.grey[600],
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.preto.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: AppTextStyles.fonteUbuntuSans,
          decoration: InputDecoration(
            hintText: 'Buscar por nome, email ou RA...',
            hintStyle: AppTextStyles.fonteUbuntuSans.copyWith(
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchNotasBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.preto.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchNotasController,
          onChanged: _onSearchNotasChanged,
          style: AppTextStyles.fonteUbuntuSans,
          decoration: InputDecoration(
            hintText: 'Buscar disciplinas por título...',
            hintStyle: AppTextStyles.fonteUbuntuSans.copyWith(
              color: Colors.grey[400],
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 20,
            ),
            suffixIcon: _searchNotasQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.grey),
                    onPressed: _clearSearchNotas,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.azulClaro),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${mostrarNotas ? 'Carregando' : 'Carregando dados...'}',
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_outline,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Nenhum ${mostrarAlunos ? 'aluno' : 'professor'} cadastrado'
                : 'Nenhum resultado encontrado',
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Clique no botão + para adicionar o primeiro'
                : 'Tente ajustar os termos da busca',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _searchQuery.isEmpty ? () => _showUserDialog() : null,
            icon: const Icon(Icons.add),
            label: Text(
              'Adicionar Primeiro',
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.azulClaro,
              foregroundColor: AppColors.branco,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotasEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grade_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchNotasQuery.isEmpty
                ? 'Nenhuma disciplina encontrada'
                : 'Nenhum resultado encontrado',
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchNotasQuery.isEmpty
                ? 'Adicione disciplinas para gerenciar notas'
                : 'Tente ajustar os termos da busca',
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<Usuario> usuarios, Color primaryColor) {
    final bool showRaColumn = mostrarAlunos || !widget.isAdmin;
    final Map<String, String> imageHeaders = _getImageHeaders();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.branco,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(), // Scroll mais suave
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: ClipRRect(
              // Adicionado para arredondar o topo das colunas
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                dividerThickness: 1,
                dataRowHeight: 80,
                headingTextStyle: AppTextStyles.fonteUbuntu.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF424242),
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
                dataTextStyle: AppTextStyles.fonteUbuntuSans.copyWith(
                  color: const Color(0xFF424242),
                  fontSize: 14,
                  height: 1.3,
                ),
                columns: [
                  const DataColumn(label: Text('Foto'), numeric: false),
                  const DataColumn(label: Text('Nome')),
                  if (showRaColumn) const DataColumn(label: Text('RA')),
                  const DataColumn(label: Text('Email')),
                  const DataColumn(label: Text('Ações')),
                ],
                rows: usuarios.map((usuario) {
                  return DataRow(
                    key: ValueKey(usuario.id),
                    cells: [
                      DataCell(
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: usuario.fotoUrl ?? '',
                            httpHeaders: imageHeaders,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                CircularProgressIndicator(),
                            errorWidget: (context, url, error) {
                              return CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              usuario.nome,
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              usuario.tipo == 'aluno'
                                  ? 'Aluno'
                                  : (usuario.tipo == 'admin'
                                        ? 'Administrador'
                                        : 'Professor'), // MUDANÇA: Distinguir admin
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showRaColumn)
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              usuario.ra ?? '-',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                color: AppColors.azulEscuro,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      DataCell(
                        SelectableText(
                          usuario.email,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      DataCell(
                        usuario.tipo == 'admin'
                            ? Text(
                                'Protegido',
                                style: AppTextStyles.fonteUbuntuSans.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ) // CORREÇÃO: Não mostrar ações para admins
                            : Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.edit,
                                    color: AppColors.azulClaro,
                                    tooltip: 'Editar',
                                    onTap: () =>
                                        _showUserDialog(usuario: usuario),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButton(
                                    icon: Icons.delete,
                                    color: AppColors.vermelho,
                                    tooltip: 'Excluir',
                                    onTap: () => _showDeleteDialog(usuario),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onTap,
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }
}

// Diálogo para adicionar avaliação global
class AddGlobalAvaliacaoDialog extends StatefulWidget {
  final Disciplina disciplina;

  const AddGlobalAvaliacaoDialog({super.key, required this.disciplina});

  @override
  State<AddGlobalAvaliacaoDialog> createState() =>
      _AddGlobalAvaliacaoDialogState();
}

class _AddGlobalAvaliacaoDialogState extends State<AddGlobalAvaliacaoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _pesoController = TextEditingController(text: '1.0');
  String _tipo = 'prova';

  @override
  void dispose() {
    _nomeController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.azulClaro;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
      backgroundColor: AppColors.branco,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_add,
                    color: primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nova Avaliação',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.preto,
                        ),
                      ),
                      Text(
                        'Disciplina: ${widget.disciplina.titulo}',
                        style: AppTextStyles.fonteUbuntuSans.copyWith(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome da Avaliação',
                      labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.title, color: primaryColor),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Nome obrigatório' : null,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: InputDecoration(
                      labelText: 'Tipo de Avaliação',
                      labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.category, color: primaryColor),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'prova',
                        child: Row(
                          children: [
                            Icon(Icons.quiz, color: primaryColor),
                            const SizedBox(width: 8),
                            Text('Prova', style: AppTextStyles.fonteUbuntu),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'atividade',
                        child: Row(
                          children: [
                            Icon(Icons.assignment, color: Colors.green),
                            const SizedBox(width: 8),
                            Text('Atividade', style: AppTextStyles.fonteUbuntu),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _tipo = value ?? 'prova'),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _pesoController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Peso da Avaliação',
                      labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[400]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.balance, color: primaryColor),
                      suffixText: 'pontos',
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      final num = double.tryParse(value ?? '');
                      if (num == null || num <= 0)
                        return 'Peso positivo obrigatório';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: Text(
                      'Cancelar',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final newAv = Avaliacao(
                          id: '',
                          nome: _nomeController.text,
                          tipo: _tipo,
                          peso: double.parse(_pesoController.text),
                          data: DateTime.now(),
                        );
                        Navigator.pop(context, newAv);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: AppColors.branco,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Criar para Todos os Alunos',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Diálogo para editar avaliação global
class EditAvaliacaoGlobalDialog extends StatefulWidget {
  final Avaliacao initialAv;

  const EditAvaliacaoGlobalDialog({super.key, required this.initialAv});

  @override
  State<EditAvaliacaoGlobalDialog> createState() =>
      _EditAvaliacaoGlobalDialogState();
}

class _EditAvaliacaoGlobalDialogState extends State<EditAvaliacaoGlobalDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _pesoController;
  late String _tipo;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.initialAv.nome);
    _pesoController = TextEditingController(
      text: widget.initialAv.peso?.toString() ?? '1.0',
    );
    _tipo = widget.initialAv.tipo;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.azulClaro;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Editar Avaliação',
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(
                  labelText: 'Nome da Avaliação',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.assignment),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Nome obrigatório' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _tipo,
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.category),
                ),
                items: ['prova', 'atividade']
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.capitalize()),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _tipo = value ?? 'prova'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pesoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Peso',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.balance),
                ),
                validator: (value) {
                  final num = double.tryParse(value ?? '');
                  if (num == null || num <= 0)
                    return 'Peso positivo obrigatório';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final newAv = Avaliacao(
                            id: '',
                            nome: _nomeController.text,
                            tipo: _tipo,
                            peso: double.parse(_pesoController.text),
                            data: widget.initialAv.data,
                          );
                          Navigator.pop(context, newAv);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      child: const Text(
                        'Salvar Alterações',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Diálogo para gerenciar avaliações
class ManageAvaliacoesDialog extends StatelessWidget {
  final Disciplina disciplina;
  final List<Avaliacao> uniqueAvaliacoes;
  final Future<void> Function(String, String, Avaliacao) onEdit;
  final Future<void> Function(String, String) onDelete;

  const ManageAvaliacoesDialog({
    super.key,
    required this.disciplina,
    required this.uniqueAvaliacoes,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.azulClaro;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 20,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.branco.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.settings,
                      color: AppColors.branco,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gerenciar Avaliações',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.branco,
                          ),
                        ),
                        Text(
                          disciplina.titulo,
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: 14,
                            color: AppColors.branco.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.branco,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: uniqueAvaliacoes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma avaliação encontrada',
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Adicione avaliações para gerenciá-las aqui',
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: uniqueAvaliacoes.length,
                      itemBuilder: (context, index) {
                        final av = uniqueAvaliacoes[index];
                        final color = av.tipo == 'atividade'
                            ? Colors.green
                            : primaryColor;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                av.tipo == 'atividade'
                                    ? Icons.assignment
                                    : Icons.quiz,
                                color: color,
                                size: 24,
                              ),
                            ),
                            title: Text(
                              av.nome,
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: color.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        av.tipo.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.orange.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        'Peso: ${av.peso?.toStringAsFixed(1) ?? '1.0'}',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: primaryColor),
                                  onPressed: () async {
                                    final newAv = await showDialog<Avaliacao?>(
                                      context: context,
                                      builder: (c) => EditAvaliacaoGlobalDialog(
                                        initialAv: av,
                                      ),
                                    );
                                    if (newAv != null) {
                                      await onEdit(av.nome, av.tipo, newAv);
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: AppColors.vermelho,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirmar Remoção'),
                                        content: Text(
                                          'Deseja remover a avaliação "${av.nome}" de TODOS os alunos?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppColors.vermelho,
                                            ),
                                            child: const Text(
                                              'Remover',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await onDelete(av.nome, av.tipo);
                                      if (context.mounted)
                                        Navigator.pop(context);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Diálogo para adicionar/editar nota
class NotaDialog extends StatefulWidget {
  final Disciplina disciplina;
  final Nota? nota;
  final Usuario? selectedAluno;

  const NotaDialog({
    super.key,
    required this.disciplina,
    this.nota,
    this.selectedAluno,
  });

  @override
  State<NotaDialog> createState() => _NotaDialogState();
}

class _NotaDialogState extends State<NotaDialog> {
  final _formKey = GlobalKey<FormState>();
  late Usuario _selectedAluno;
  List<Avaliacao> _avaliacoes = [];
  final _nomeController = TextEditingController();
  final _tipoController = TextEditingController();
  final _notaController = TextEditingController();
  final _pesoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final isEdit = widget.nota != null;
    if (isEdit) {
      final nota = widget.nota!;
      final aluno = widget.disciplina.alunos.firstWhereOrNull(
        (a) => a.id == nota.alunoId,
      );
      _selectedAluno =
          aluno ??
          Usuario(
            id: nota.alunoId,
            nome: nota.alunoNome,
            email: '',
            tipo: 'aluno',
            ra: nota.alunoRa,
          );
      _avaliacoes = List<Avaliacao>.from(nota.avaliacoes);
    } else {
      if (widget.selectedAluno == null) {
        throw ArgumentError('selectedAluno é obrigatório para criação');
      }
      _selectedAluno = widget.selectedAluno!;
      _avaliacoes = [];
    }
    _tipoController.text = 'prova'; // Default
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _tipoController.dispose();
    _notaController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  void _addAvaliacao() {
    if (_formKey.currentState!.validate()) {
      final novaAvaliacao = Avaliacao(
        id: '',
        nome: _nomeController.text,
        tipo: _tipoController.text,
        nota: double.tryParse(_notaController.text),
        peso: double.tryParse(_pesoController.text) ?? 1.0,
        data: DateTime.now(),
      );
      setState(() {
        _avaliacoes.add(novaAvaliacao);
      });
      // Limpar campos
      _nomeController.clear();
      _notaController.clear();
      _pesoController.clear();
    }
  }

  void _removeAvaliacao(int index) {
    setState(() {
      _avaliacoes.removeAt(index);
    });
  }

  Nota? _buildNota() {
    return Nota(
      id: widget.nota?.id ?? '',
      disciplinaId: widget.disciplina.id,
      alunoId: _selectedAluno.id,
      alunoNome: _selectedAluno.nome,
      alunoRa: _selectedAluno.ra,
      avaliacoes: _avaliacoes,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.nota != null;
    final primaryColor = AppColors.azulClaro;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 600.0 : screenWidth * 0.95;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 24,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.branco, AppColors.cinzaClaro],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.branco.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.grade, color: AppColors.branco, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${isEdit ? 'Editar' : 'Adicionar'} Nota',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.branco,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '${widget.disciplina.titulo} - ${_selectedAluno.nome}',
                          style: AppTextStyles.fonteUbuntuSans.copyWith(
                            fontSize: 14,
                            color: AppColors.branco.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.branco),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form para nova avaliação
                        Text(
                          'Adicionar Nova Avaliação',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nomeController,
                          style: AppTextStyles.fonteUbuntuSans,
                          decoration: InputDecoration(
                            labelText: 'Nome da Avaliação',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.assignment,
                              color: Colors.grey[500],
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o nome da avaliação';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: _tipoController.text.isEmpty
                              ? 'prova'
                              : _tipoController.text,
                          style: AppTextStyles.fonteUbuntuSans,
                          decoration: InputDecoration(
                            labelText: 'Tipo',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.category,
                              color: Colors.grey[500],
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: ['prova', 'atividade'].map((tipo) {
                            return DropdownMenuItem(
                              value: tipo,
                              child: Text(tipo.toUpperCase()),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) _tipoController.text = value;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _notaController,
                          style: AppTextStyles.fonteUbuntuSans,
                          decoration: InputDecoration(
                            labelText: 'Nota (0-10)',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.star,
                              color: Colors.grey[500],
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final num = double.tryParse(value ?? '');
                            if (num == null || num < 0 || num > 10)
                              return 'Nota deve estar entre 0 e 10';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _pesoController,
                          style: AppTextStyles.fonteUbuntuSans,
                          decoration: InputDecoration(
                            labelText: 'Peso (padrão 1)',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.balance,
                              color: Colors.grey[500],
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final num = double.tryParse(value ?? '');
                            if (num == null || num <= 0)
                              return 'Peso deve ser positivo';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _addAvaliacao,
                            icon: const Icon(Icons.add),
                            label: Text(
                              'Adicionar Avaliação',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: AppColors.branco,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Lista de avaliações atuais
                        Text(
                          'Avaliações Adicionadas (${_avaliacoes.length})',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_avaliacoes.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Nenhuma avaliação adicionada',
                                  style: AppTextStyles.fonteUbuntu.copyWith(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._avaliacoes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final av = entry.value;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  av.nome,
                                  style: AppTextStyles.fonteUbuntu.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${av.tipo.toUpperCase()}: ${av.nota ?? 'Não definida'}',
                                    ),
                                    Text('Peso: ${av.peso ?? 1.0}'),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: AppColors.vermelho,
                                  ),
                                  onPressed: () => _removeAvaliacao(index),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.preto.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancelar',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        final novaNota = _buildNota();
                        if (novaNota != null &&
                            (_avaliacoes.isNotEmpty || isEdit)) {
                          Navigator.pop(context, novaNota);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Adicione pelo menos uma avaliação',
                              ),
                              backgroundColor: AppColors.vermelhoErro,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: AppColors.branco,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isEdit ? 'Salvar Alterações' : 'Criar Nota',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Diálogo para adicionar/editar usuário (modificado para retornar dados via Navigator)
class UserDialog extends StatefulWidget {
  final Usuario? usuario;
  final bool isEdit;
  final bool isAluno;
  final String? token;

  const UserDialog({
    super.key,
    this.usuario,
    required this.isEdit,
    required this.isAluno,
    this.token,
  });

  @override
  State<UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<UserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _raController = TextEditingController();
  bool _isAdmin = false; // MUDANÇA: Campo para tipo admin (só para professores)

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.usuario != null) {
      _nomeController.text = widget.usuario!.nome;
      _emailController.text = widget.usuario!.email;
      _raController.text = widget.usuario!.ra ?? '';
      if (!widget.isAluno && widget.usuario!.tipo == 'admin') {
        // MUDANÇA: Inicializar admin para edit
        _isAdmin = true;
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _raController.dispose();
    super.dispose();
  }

  Map<String, String> _getImageHeaders() {
    if (widget.token == null) return {};
    return {'Authorization': 'Bearer ${widget.token}'};
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final userData = <String, String>{
        'nome': _nomeController.text,
        'email': _emailController.text,
        'ra': _raController.text,
      };
      if (!widget.isAluno) {
        // MUDANÇA: Adicionar tipo para professores
        userData['tipo'] = _isAdmin ? 'admin' : 'professor';
      }
      Navigator.of(context).pop(userData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 550.0 : screenWidth * 0.9;
    final primaryColor = AppColors.azulClaro;
    final Map<String, String> imageHeaders = _getImageHeaders();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 24,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.branco, AppColors.cinzaClaro],
          ),
        ),
        child: Column(
          children: [
            // Header do Dialog
            Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.branco.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isAluno ? Icons.school : Icons.school_outlined,
                      color: AppColors.branco,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.isEdit ? 'Editar' : 'Adicionar'} ${widget.isAluno ? 'Aluno' : 'Professor'}',
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.branco,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.isEdit)
                          Text(
                            widget.usuario!.nome,
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              fontSize: 14,
                              color: AppColors.branco.withOpacity(0.9),
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Body do Form
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.isEdit &&
                            widget.usuario!.fotoUrl != null) ...[
                          // CORREÇÃO: Usar CachedNetworkImage para melhor handling de erros e cache
                          Center(
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: widget.usuario!.fotoUrl!,
                                httpHeaders: imageHeaders,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator(),
                                errorWidget: (context, url, error) {
                                  return CircleAvatar(
                                    backgroundColor: Colors.grey[200],
                                    radius: 40,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Foto atual',
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        TextFormField(
                          controller: _nomeController,
                          style: AppTextStyles.fonteUbuntuSans,
                          decoration: InputDecoration(
                            labelText: 'Nome completo',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.person,
                              color: Colors.grey[500],
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailController,
                          style: AppTextStyles.fonteUbuntuSans,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                              color: Colors.grey[600],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: primaryColor,
                                width: 2,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.email,
                              color: Colors.grey[500],
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o email';
                            }
                            if (!value.contains('@')) {
                              return 'Por favor, insira um email válido';
                            }
                            return null;
                          },
                        ),
                        if (widget.isAluno) ...[
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _raController,
                            style: AppTextStyles.fonteUbuntuSans,
                            decoration: InputDecoration(
                              labelText: 'RA',
                              labelStyle: AppTextStyles.fonteUbuntu.copyWith(
                                color: Colors.grey[600],
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: primaryColor,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.badge,
                                color: Colors.grey[500],
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira o RA';
                              }
                              return null;
                            },
                          ),
                        ],
                        if (!widget.isAluno) ...[
                          // MUDANÇA: Adicionar toggle para admin em professores
                          const SizedBox(height: 20),
                          SwitchListTile(
                            title: Text(
                              'É Administrador?',
                              style: AppTextStyles.fonteUbuntu.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Administradores podem criar outros professores. (Administradores não podem ser editados ou excluídos.)',
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: _isAdmin,
                            onChanged: (value) {
                              setState(() {
                                _isAdmin = value;
                              });
                            },
                            activeColor: primaryColor,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Footer com botões
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.preto.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancelar',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: AppColors.branco,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        widget.isEdit ? 'Salvar Alterações' : 'Adicionar',
                        style: AppTextStyles.fonteUbuntu.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Diálogo de confirmação de exclusão (modificado para retornar bool via Navigator)
class DeleteDialog extends StatelessWidget {
  final Usuario usuario;

  const DeleteDialog({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 500 ? 400.0 : screenWidth * 0.85;
    final primaryColor = AppColors.azulClaro;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 24,
      child: Container(
        width: dialogWidth,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.branco,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.preto.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.vermelho.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 56,
                color: AppColors.vermelho,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Confirmar Exclusão',
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.preto,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tem certeza que deseja excluir ${usuario.nome}?',
              textAlign: TextAlign.center,
              style: AppTextStyles.fonteUbuntuSans.copyWith(
                fontSize: 18,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esta ação não pode ser desfeita.',
              textAlign: TextAlign.center,
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontSize: 14,
                color: AppColors.vermelhoErro,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'Cancelar',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vermelhoErro,
                      foregroundColor: AppColors.branco,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      'Excluir',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Extension para capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
