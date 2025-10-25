import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';
import 'package:sistema_poliedro/src/pages/professor/notas.dart';
import 'dart:convert';
import 'package:sistema_poliedro/src/services/auth_service.dart';
import '../../styles/cores.dart';
import '../../styles/fontes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../dialogs/administracao_dialogs.dart';
import '../../models/modelo_usuario.dart';
import '../../models/modelo_nota.dart';
import '../../models/modelo_disciplina.dart';
import '../../models/modelo_avaliacao.dart';

class AdministracaoPage extends StatefulWidget {
  const AdministracaoPage({super.key});

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
  bool mostrarNotas = false;
  List<Disciplina> disciplinas = [];
  bool carregandoNotas = false;
  late TextEditingController _searchNotasController;
  String _searchNotasQuery = '';
  String? selectedDisciplineId;
  String? token;
  String? userType;
  bool _mostrarAlerta = false;
  String _mensagemAlerta = '';
  bool _alertaSucesso = false;
  Timer? _timerAlerta;

  static const String apiBaseUrl = '/api';
  static const String cardsDisciplinasPath = '/cardsDisciplinas';
  static const String notasPath = '/notas';

  // GETTER SEGURO - verifica se userType foi carregado
  bool get isUserAdmin => userType != null && userType == 'admin';

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

    _initializeTokenAndUserType().then((_) {
      if (mounted && token != null) {
        _carregarUsuarios();
      }
    });
  }

  @override
  void dispose() {
    _timerAlerta?.cancel();
    super.dispose();
  }

  // MÉTODOS PARA CONTROLE DE ALERTAS
  void _mostrarAlertaCustom(String mensagem, bool sucesso) {
    // Cancela alerta anterior se existir
    _timerAlerta?.cancel();

    setState(() {
      _mostrarAlerta = true;
      _mensagemAlerta = mensagem;
      _alertaSucesso = sucesso;
    });

    // Configura timer para esconder o alerta após 3 segundos
    _timerAlerta = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _mostrarAlerta = false;
        });
      }
    });
  }

  void _esconderAlerta() {
    _timerAlerta?.cancel();
    if (mounted) {
      setState(() {
        _mostrarAlerta = false;
      });
    }
  }

  // SUBSTITUA OS MÉTODOS EXISTENTES _showSuccess E _showError
  void _showSuccess(String message) {
    _mostrarAlertaCustom(message, true);
  }

  void _showError(String message) {
    _mostrarAlertaCustom(message, false);
  }

  Future<void> _initializeTokenAndUserType() async {
    try {
      // Obter token do AuthService
      final authToken = await AuthService.getToken();
      if (authToken != null && mounted) {
        setState(() {
          token = authToken;
        });

        // Obter tipo do usuário
        final tipo = await AuthService.getUserType();
        if (mounted) {
          setState(() {
            userType = tipo;
          });
        }

        // Debug do token
        if (authToken != null) {
          try {
            final parts = authToken.split('.');
            if (parts.length == 3) {
              String payload = parts[1];
              while (payload.length % 4 != 0) {
                payload += '=';
              }
              final decoded = utf8.decode(base64.decode(payload));
              print('Payload do token na Administracao: $decoded');
            }
          } catch (e) {
            print('Erro ao decodificar token na Administracao: $e');
          }
        }
      } else if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showError('Token não encontrado. Faça login novamente.');
        });
      }
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showError('Erro ao carregar dados do usuário: $e');
        });
      }
    }
  }

  Future<void> _initializeData() async {
    await _loadToken();
    if (token != null && mounted) {
      _carregarUsuarios();
    }
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
      final headers = await AuthService.getAuthHeaders();

      // Todos os usuários podem carregar tanto alunos quanto professores
      String endpoint = mostrarAlunos ? '/alunos/list' : '/professores/list';

      final url = Uri.parse(AuthService.baseUrl + apiBaseUrl + endpoint);
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
        );
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
    } else {
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
      await _carregarDisciplinas(silent: true);
    } else {
      throw Exception(
        'Falha ao criar nota: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> _deletarNota({
    required String notaId,
    String? alunoNome,
    bool silent = false,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Confirmar Remoção'),
        content: Text(
          alunoNome != null
              ? 'Deseja remover a nota do aluno $alunoNome?'
              : 'Deseja remover esta nota?',
        ),
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

    if (confirm == true) {
      try {
        final headers = await AuthService.getAuthHeaders();
        final url = Uri.parse(
          AuthService.baseUrl + apiBaseUrl + notasPath + '/$notaId',
        );
        final response = await http.delete(url, headers: headers);

        if (response.statusCode == 200) {
          if (mounted) {
            await _carregarDisciplinas(silent: true);

            if (!silent && mounted) {
              _showSuccess(
                alunoNome != null
                    ? 'Nota do aluno $alunoNome removida com sucesso!'
                    : 'Nota removida com sucesso!',
              );
            }
          }
        } else {
          throw Exception(
            'Falha ao remover nota: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao remover nota: $e');
        }
      }
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
      await _carregarDisciplinas(silent: true);
    } else {
      throw Exception(
        'Falha ao atualizar nota: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> _addGlobalAvaliacao(Disciplina disciplina) async {
    final newAv = await showDialog<Avaliacao?>(
      context: context,
      builder: (context) => AddGlobalAvaliacaoDialog(disciplina: disciplina),
    );

    if (newAv != null) {
      setState(() => carregandoNotas = true);

      try {
        int successCount = 0;
        int errorCount = 0;

        // Executar todas as operações primeiro
        for (final aluno in disciplina.alunos) {
          try {
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
              await _criarNota(notaToSave, silent: true);
            } else {
              await _atualizarNota(existingNota.id, notaToSave, silent: true);
            }

            successCount++;
          } catch (e) {
            errorCount++;
            debugPrint('Erro ao processar aluno ${aluno.nome}: $e');
          }
        }

        // Recarregar os dados
        await _carregarDisciplinas(silent: true);

        // Mostrar apenas UM alerta com o resumo
        if (mounted) {
          if (errorCount == 0) {
            _showSuccess(
              'Avaliação "${newAv.nome}" adicionada com sucesso para todos os $successCount alunos!',
            );
          } else {
            _showSuccess(
              'Avaliação "${newAv.nome}" adicionada para $successCount alunos. '
              '$errorCount alunos não puderam ser processados.',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          _showError('Erro ao adicionar avaliação global: $e');
        }
      } finally {
        if (mounted) setState(() => carregandoNotas = false);
      }
    }
  }

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
        onEdit: (oldNome, oldTipo, newAv) async {
          final updatedAv = await showDialog<Avaliacao?>(
            context: context,
            builder: (c) => EditAvaliacaoGlobalDialog(initialAv: newAv),
          );
          if (updatedAv != null) {
            await _updateGlobalAvaliacao(
              disciplina,
              oldNome,
              oldTipo,
              updatedAv,
            );
          }
        },
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
    setState(() => carregandoNotas = true);

    try {
      int successCount = 0;
      int errorCount = 0;

      for (final nota in disciplina.notas) {
        try {
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
            successCount++;
          }
        } catch (e) {
          errorCount++;
          debugPrint('Erro ao atualizar nota do aluno ${nota.alunoNome}: $e');
        }
      }

      await _carregarDisciplinas(silent: true);

      if (mounted) {
        if (errorCount == 0) {
          _showSuccess(
            'Avaliação atualizada com sucesso para $successCount alunos!',
          );
        } else {
          _showSuccess(
            'Avaliação atualizada para $successCount alunos. '
            '$errorCount alunos não puderam ser processados.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao atualizar avaliação: $e');
      }
    } finally {
      if (mounted) setState(() => carregandoNotas = false);
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
        backgroundColor: Colors.white,
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

    setState(() => carregandoNotas = true);

    try {
      int successCount = 0;
      int errorCount = 0;

      for (final nota in disciplina.notas) {
        try {
          final updatedAvaliacoes = nota.avaliacoes
              .where((a) => !(a.nome == nome && a.tipo == tipo))
              .toList();
          if (updatedAvaliacoes.length < nota.avaliacoes.length) {
            final updatedNota = nota.copyWith(avaliacoes: updatedAvaliacoes);
            await _atualizarNota(nota.id, updatedNota, silent: true);
            successCount++;
          }
        } catch (e) {
          errorCount++;
          debugPrint(
            'Erro ao remover avaliação do aluno ${nota.alunoNome}: $e',
          );
        }
      }

      await _carregarDisciplinas(silent: true);

      if (mounted) {
        if (errorCount == 0) {
          _showSuccess(
            'Avaliação removida com sucesso de $successCount alunos!',
          );
        } else {
          _showSuccess(
            'Avaliação removida de $successCount alunos. '
            '$errorCount alunos não puderam ser processados.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Erro ao remover avaliação: $e');
      }
    } finally {
      if (mounted) setState(() => carregandoNotas = false);
    }
  }

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
      _showError(
        'Usuário criado, mas falha ao enviar senha: $e. Tente reenviar manualmente.',
      );
      rethrow;
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

    // Todos os usuários podem ver tanto alunos quanto professores
    var filtrados = listaSegura.where((usuario) {
      return true; // Permite ver tudo
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

  void _showUserDialog({Usuario? usuario}) async {
    final bool isEdit = usuario != null;
    final bool isAluno = usuario?.tipo == 'aluno' || mostrarAlunos;

    // BLOQUEIA CRIAÇÃO DE PROFESSORES POR NÃO-ADMINS
    if (!isEdit && !isAluno && !isUserAdmin) {
      _showError('Apenas administradores podem adicionar professores.');
      return;
    }

    // BLOQUEIA EDIÇÃO DE PROFESSORES POR NÃO-ADMINS
    if (isEdit && usuario!.tipo == 'professor' && !isUserAdmin) {
      _showError('Apenas administradores podem editar professores.');
      return;
    }

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
      try {
        final headers = await AuthService.getAuthHeaders();
        if (isEdit) {
          String endpoint = usuario!.tipo == 'aluno'
              ? '/alunos'
              : '/professores';
          final body = <String, dynamic>{
            'nome': result['nome']!,
            'email': result['email']!,
            if (isAluno) 'ra': result['ra']!,
          };
          if (!isAluno && result.containsKey('tipo')) {
            body['tipo'] = result['tipo']!;
          }
          final url = Uri.parse(
            AuthService.baseUrl + apiBaseUrl + endpoint + '/' + usuario.id,
          );
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
            );
          }
        } else {
          String endpoint = isAluno
              ? '/alunos/register'
              : '/professores/register';
          final body = <String, dynamic>{
            'nome': result['nome']!,
            'email': result['email']!,
            if (isAluno) 'ra': result['ra']!,
          };
          if (!isAluno && result.containsKey('tipo')) {
            body['tipo'] = result['tipo']!;
          }
          final url = Uri.parse(AuthService.baseUrl + apiBaseUrl + endpoint);
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

            await _sendInitialPassword(
              result['email']!,
              isAluno ? 'aluno' : 'professor',
            );

            _showSuccess(
              'Adicionado com sucesso! Senha inicial enviada por e-mail.',
            );
          } else {
            throw Exception(
              'Falha ao adicionar: ${response.statusCode} - ${response.body}',
            );
          }
        }
      } catch (e) {
        _showError('Erro ao salvar: $e');
      }
    }
  }

  Future<void> _showDeleteDialog(Usuario usuario) async {
    // BLOQUEIA EXCLUSÃO DE PROFESSORES POR NÃO-ADMINS
    if (usuario.tipo == 'professor' && !isUserAdmin) {
      _showError('Apenas administradores podem excluir professores.');
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => DeleteDialog(usuario: usuario),
    );

    if (confirm == true) {
      try {
        final headers = await AuthService.getAuthHeaders();
        String endpoint = usuario.tipo == 'aluno' ? '/alunos' : '/professores';
        final url = Uri.parse(
          AuthService.baseUrl + apiBaseUrl + endpoint + '/' + usuario.id,
        );
        final response = await http.delete(url, headers: headers);

        if (response.statusCode == 200) {
          setState(() {
            usuarios.removeWhere((u) => u.id == usuario.id);
          });
          _showSuccess('${usuario.nome} excluído com sucesso!');
        } else {
          throw Exception(
            'Falha ao excluir: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        _showError('Erro ao excluir: $e');
      }
    }
  }

  void _switchToUsuarios() {
    setState(() {
      mostrarNotas = false;
      selectedDisciplineId = null;
    });
    _carregarUsuarios();
  }

  void _switchToNotas() {
    setState(() {
      mostrarNotas = true;
      selectedDisciplineId = null;
    });
    _carregarNotasData();
  }

  void _selectDiscipline(Disciplina disciplina) {
    setState(() {
      selectedDisciplineId = disciplina.id;
    });
  }

  void _backToDisciplines() {
    setState(() {
      selectedDisciplineId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = AppColors.azulClaro;
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet = MediaQuery.of(context).size.width < 900;

    if (userType == null) {
      return Scaffold(
        backgroundColor: AppColors.cinzaClaro,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.azulClaro,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Carregando...',
                style: AppTextStyles.fonteUbuntu.copyWith(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        Theme(
          data: Theme.of(context).copyWith(
            primaryColor: AppColors.cinzaClaro,
            appBarTheme: AppBarTheme(
              backgroundColor: AppColors.cinzaClaro,
              foregroundColor: Colors.black,
              elevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: AppColors.cinzaClaro,
                statusBarIconBrightness: Brightness.dark,
              ),
            ),
          ),
          child: Scaffold(
            backgroundColor: AppColors.cinzaClaro,
            body: mostrarNotas
                ? _buildNotasBody(primaryColor, isMobile, isTablet)
                : _buildUsuariosBody(primaryColor, isMobile, isTablet),
          ),
        ),

        // SISTEMA DE ALERTAS NO CANTO SUPERIOR DIREITO
        if (_mostrarAlerta)
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: EdgeInsets.all(isMobile ? 12 : 16),
                  padding: EdgeInsets.all(isMobile ? 16 : 20),
                  decoration: BoxDecoration(
                    color: _alertaSucesso
                        ? AppColors.verdeConfirmacao
                        : AppColors.vermelhoErro,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        _alertaSucesso ? Icons.check_circle : Icons.error,
                        color: Colors.white,
                        size: isMobile ? 20 : 24,
                      ),
                      SizedBox(width: isMobile ? 12 : 16),
                      Expanded(
                        child: Text(
                          _mensagemAlerta,
                          style: AppTextStyles.fonteUbuntu.copyWith(
                            color: Colors.white,
                            fontSize: isMobile ? 14 : 16,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 12),
                      GestureDetector(
                        onTap: _esconderAlerta,
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: isMobile ? 18 : 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUsuariosBody(Color primaryColor, bool isMobile, bool isTablet) {
    final usuariosFiltrados = _getUsuariosFiltrados();
    return Column(
      children: [
        _buildUsuariosHeader(primaryColor, usuariosFiltrados.length, isMobile),
        _buildSearchBar(isMobile),
        Expanded(
          child: carregando
              ? _buildLoadingState()
              : usuariosFiltrados.isEmpty
              ? _buildEmptyState(isMobile)
              : isMobile
              ? _buildMobileUserList(usuariosFiltrados, primaryColor)
              : _buildDataTable(usuariosFiltrados, primaryColor, isTablet),
        ),
      ],
    );
  }

  // LISTA MOBILE PARA USUÁRIOS
  Widget _buildMobileUserList(List<Usuario> usuarios, Color primaryColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: usuarios.length,
      itemBuilder: (context, index) {
        final usuario = usuarios[index];
        final bool isProfessorEditingProfessor =
            !isUserAdmin && !mostrarAlunos && usuario.tipo == 'professor';

        return Card(
          color: AppColors.branco,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: usuario.fotoUrl ?? '',
                        httpHeaders: _getImageHeaders(),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        placeholder: (context, url) =>
                            CircularProgressIndicator(
                              color: AppColors.azulClaro,
                            ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(Icons.person, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario.nome,
                            style: AppTextStyles.fonteUbuntu.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            usuario.tipo == 'aluno'
                                ? 'Aluno'
                                : (usuario.tipo == 'admin'
                                      ? 'Administrador'
                                      : 'Professor'),
                            style: AppTextStyles.fonteUbuntuSans.copyWith(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (mostrarAlunos && usuario.ra != null) ...[
                  _buildInfoRow('RA:', usuario.ra!),
                  const SizedBox(height: 8),
                ],
                _buildInfoRow('Email:', usuario.email),
                const SizedBox(height: 12),
                if (usuario.tipo != 'admin' && !isProfessorEditingProfessor)
                  Row(
                    children: [
                      Expanded(
                        child: _buildMobileActionButton(
                          icon: Icons.edit,
                          text: 'Editar',
                          color: AppColors.azulClaro,
                          onTap: () => _showUserDialog(usuario: usuario),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildMobileActionButton(
                          icon: Icons.delete,
                          text: 'Excluir',
                          color: AppColors.vermelho,
                          onTap: () => _showDeleteDialog(usuario),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    'Protegido',
                    style: AppTextStyles.fonteUbuntuSans.copyWith(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.fonteUbuntuSans.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.fonteUbuntuSans.copyWith(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        text,
        style: AppTextStyles.fonteUbuntuSans.copyWith(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.3)),
        padding: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildNotasBody(Color primaryColor, bool isMobile, bool isTablet) {
    final disciplinasFiltradas = _getDisciplinasFiltradas();
    return Column(
      children: [
        _buildNotasHeader(primaryColor, disciplinasFiltradas.length, isMobile),
        _buildSearchNotasBar(isMobile),
        Expanded(
          child: carregandoNotas
              ? _buildLoadingState()
              : selectedDisciplineId == null
              ? _buildDisciplinesSelector(
                  disciplinasFiltradas,
                  primaryColor,
                  isMobile,
                )
              : _buildSelectedDisciplineTable(primaryColor, isMobile, isTablet),
        ),
      ],
    );
  }

  Widget _buildDisciplinesSelector(
    List<Disciplina> disciplinas,
    Color primaryColor,
    bool isMobile,
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

  Widget _buildSelectedDisciplineTable(
    Color primaryColor,
    bool isMobile,
    bool isTablet,
  ) {
    final selectedDiscipline = disciplinas.firstWhereOrNull(
      (d) => d.id == selectedDisciplineId,
    );
    if (selectedDiscipline == null) {
      return const Center(child: Text('Disciplina não encontrada'));
    }

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
          bool temAlgumaNota = false;

          for (final av in nota.avaliacoes) {
            // CORREÇÃO: Considera notas zero também
            if (av.nota != null) {
              mediaAluno += (av.nota! * (av.peso ?? 1.0));
              totalPeso += (av.peso ?? 1.0);
              temAlgumaNota = true;
            }
          }

          // CORREÇÃO: Calcula a média mesmo se houver notas zero
          if (totalPeso > 0 && temAlgumaNota) {
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
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUsuariosHeader(Color primaryColor, int count, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.all(24),
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
          _buildMainToggleButtons(primaryColor, isMobile),

          SizedBox(height: isMobile ? 16 : 24),
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
                  size: isMobile ? 24 : 28,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isUserAdmin
                          ? (mostrarAlunos
                                ? 'Gerenciar Alunos'
                                : 'Gerenciar Professores')
                          : (mostrarAlunos
                                ? 'Gerenciar Alunos'
                                : 'Visualizar Professores'),
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.preto,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      'Total: $count ${mostrarAlunos ? 'alunos' : 'professores'}',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!mostrarNotas &&
                  (isUserAdmin || (mostrarAlunos && !isUserAdmin)))
                if (isMobile)
                  FloatingActionButton(
                    onPressed: () => _showUserDialog(),
                    backgroundColor: primaryColor,
                    child: Icon(Icons.add, color: AppColors.branco),
                    mini: true,
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _showUserDialog(),
                    icon: Icon(Icons.add, size: 20, color: AppColors.branco),
                    label: Text(
                      'Adicionar',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.branco,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: AppColors.branco,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                  ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.grey),
                onPressed: mostrarNotas
                    ? _carregarNotasData
                    : _carregarUsuarios,
              ),
            ],
          ),
          if (!mostrarNotas) ...[
            SizedBox(height: isMobile ? 16 : 24),
            _buildToggleButtons(primaryColor, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildNotasHeader(Color primaryColor, int count, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: isMobile ? const EdgeInsets.all(16) : const EdgeInsets.all(24),
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
          _buildMainToggleButtons(primaryColor, isMobile),
          SizedBox(height: isMobile ? 16 : 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.grade,
                  color: primaryColor,
                  size: isMobile ? 24 : 28,
                ),
              ),
              SizedBox(width: isMobile ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gerenciar Notas',
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: isMobile ? 22 : 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.preto,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $count disciplinas',
                      style: AppTextStyles.fonteUbuntuSans.copyWith(
                        fontSize: isMobile ? 14 : 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: Colors.grey),
                onPressed: mostrarNotas
                    ? _carregarNotasData
                    : _carregarUsuarios,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggleButtons(Color primaryColor, bool isMobile) {
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
            isMobile: isMobile,
          ),
          const SizedBox(width: 4),
          _buildToggleButton(
            text: 'Notas',
            isActive: mostrarNotas,
            primaryColor: primaryColor,
            onTap: _switchToNotas,
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButtons(Color primaryColor, bool isMobile) {
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
            isMobile: isMobile,
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
            isMobile: isMobile,
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
    required bool isMobile,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 8 : 12,
        ),
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
            fontSize: isMobile ? 12 : 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isMobile) {
    return Padding(
      padding: isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
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
          style: AppTextStyles.fonteUbuntuSans.copyWith(
            fontSize: isMobile ? 14 : 16,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar por nome, email ou RA...',
            hintStyle: AppTextStyles.fonteUbuntuSans.copyWith(
              color: Colors.grey[400],
              fontSize: isMobile ? 14 : 16,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 16 : 20,
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

  Widget _buildSearchNotasBar(bool isMobile) {
    return Padding(
      padding: isMobile ? const EdgeInsets.all(12) : const EdgeInsets.all(16),
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
          style: AppTextStyles.fonteUbuntuSans.copyWith(
            fontSize: isMobile ? 14 : 16,
          ),
          decoration: InputDecoration(
            hintText: 'Buscar disciplinas por título...',
            hintStyle: AppTextStyles.fonteUbuntuSans.copyWith(
              color: Colors.grey[400],
              fontSize: isMobile ? 14 : 16,
            ),
            prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 16 : 20,
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

  Widget _buildEmptyState(bool isMobile) {
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

  Widget _buildDataTable(
    List<Usuario> usuarios,
    Color primaryColor,
    bool isTablet,
  ) {
    final bool showRaColumn = mostrarAlunos;
    final Map<String, String> imageHeaders = _getImageHeaders();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: AppColors.branco,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width - 32,
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                dividerThickness: 1,
                dataRowHeight: isTablet ? 70 : 80,
                headingTextStyle: AppTextStyles.fonteUbuntu.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF424242),
                  fontSize: isTablet ? 12 : 14,
                  letterSpacing: 0.5,
                ),
                dataTextStyle: AppTextStyles.fonteUbuntuSans.copyWith(
                  color: const Color(0xFF424242),
                  fontSize: isTablet ? 12 : 14,
                  height: 1.3,
                ),
                columns: [
                  const DataColumn(label: Text('Foto')),
                  const DataColumn(label: Text('Nome')),
                  if (showRaColumn) const DataColumn(label: Text('RA')),
                  const DataColumn(label: Text('Email')),
                  const DataColumn(label: Text('Ações')),
                ],
                rows: usuarios.map((usuario) {
                  final bool isProfessorEditingProfessor =
                      !isUserAdmin &&
                      !mostrarAlunos &&
                      usuario.tipo == 'professor';

                  return DataRow(
                    key: ValueKey(usuario.id),
                    cells: [
                      DataCell(
                        ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: usuario.fotoUrl ?? '',
                            httpHeaders: imageHeaders,
                            width: isTablet ? 40 : 50,
                            height: isTablet ? 40 : 50,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                CircularProgressIndicator(
                                  color: AppColors.azulClaro,
                                ),
                            errorWidget: (context, url, error) {
                              return CircleAvatar(
                                backgroundColor: Colors.grey[200],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                  size: isTablet ? 20 : 24,
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
                                fontSize: isTablet ? 13 : 15,
                              ),
                            ),
                            Text(
                              usuario.tipo == 'aluno'
                                  ? 'Aluno'
                                  : (usuario.tipo == 'admin'
                                        ? 'Administrador'
                                        : 'Professor'),
                              style: AppTextStyles.fonteUbuntuSans.copyWith(
                                color: primaryColor,
                                fontSize: isTablet ? 10 : 12,
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
                              horizontal: 12,
                              vertical: 6,
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
                                fontSize: isTablet ? 11 : 13,
                              ),
                            ),
                          ),
                        ),
                      DataCell(
                        SelectableText(
                          usuario.email,
                          style: TextStyle(fontSize: isTablet ? 11 : 13),
                        ),
                      ),
                      DataCell(
                        usuario.tipo == 'admin' || isProfessorEditingProfessor
                            ? Text(
                                'Protegido',
                                style: AppTextStyles.fonteUbuntuSans.copyWith(
                                  color: Colors.grey[600],
                                  fontSize: isTablet ? 10 : 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            : Row(
                                children: [
                                  _buildActionButton(
                                    icon: Icons.edit,
                                    color: AppColors.azulClaro,
                                    tooltip: 'Editar',
                                    onTap: () =>
                                        _showUserDialog(usuario: usuario),
                                    isTablet: isTablet,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildActionButton(
                                    icon: Icons.delete,
                                    color: AppColors.vermelho,
                                    tooltip: 'Excluir',
                                    onTap: () => _showDeleteDialog(usuario),
                                    isTablet: isTablet,
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
    required bool isTablet,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, size: isTablet ? 18 : 20, color: color),
        onPressed: onTap,
        tooltip: tooltip,
        padding: const EdgeInsets.all(8),
        constraints: BoxConstraints(
          minWidth: isTablet ? 36 : 40,
          minHeight: isTablet ? 36 : 40,
        ),
      ),
    );
  }
}
