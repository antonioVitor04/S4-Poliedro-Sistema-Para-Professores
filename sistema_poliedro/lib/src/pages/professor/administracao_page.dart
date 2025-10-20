import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
      id: json['id']!,
      nome: json['nome']!,
      email: json['email']!,
      ra: json['ra'],
      tipo: json['tipo'] ?? 'unknown', // CORREÇÃO: Default para evitar null
      fotoUrl: json['fotoUrl'],
    );
  }
}

// NOVOS MODELOS para Notas
class Detalhe {
  final String? id;
  final String tipo;
  final String descricao;
  final double? nota;
  final double peso;

  Detalhe({
    this.id,
    required this.tipo,
    required this.descricao,
    this.nota,
    required this.peso,
  });

  factory Detalhe.fromJson(Map<String, dynamic> json) {
    return Detalhe(
      id: json['_id'],
      tipo: json['tipo'] ?? '',
      descricao: json['descricao'] ?? '',
      nota: json['nota']?.toDouble(),
      peso: (json['peso'] ?? 1.0).toDouble(),
    );
  }
}

class Disciplina {
  final String id;
  final String nome;
  final List<Detalhe> detalhes;
  final String alunoId;
  final String alunoNome;
  final double? mediaProvas;
  final double? mediaAtividades;
  final double? mediaFinal;

  Disciplina({
    required this.id,
    required this.nome,
    required this.detalhes,
    required this.alunoId,
    required this.alunoNome,
    this.mediaProvas,
    this.mediaAtividades,
    this.mediaFinal,
  });

  factory Disciplina.fromJson(Map<String, dynamic> json) {
    return Disciplina(
      id: json['_id'] ?? '',
      nome: json['nome'] ?? '',
      detalhes: (json['detalhes'] as List<dynamic>? ?? [])
          .map((d) => Detalhe.fromJson(d))
          .toList(),
      alunoId: json['alunoId']?['_id'] ?? json['alunoId'] ?? '',
      alunoNome: json['alunoId']?['nome'] ?? '',
      mediaProvas: json['mediaProvas']?.toDouble(),
      mediaAtividades: json['mediaAtividades']?.toDouble(),
      mediaFinal: json['mediaFinal']?.toDouble(),
    );
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
  List<Usuario> usuarios = [];
  List<Disciplina> disciplinas = [];
  Set<String>? uniqueNomes; // CORREÇÃO: Nullable para hot reload
  bool gerenciarUsuarios = true; // NOVO: Toggle principal Usuários vs Notas
  bool mostrarAlunos = true;
  bool carregando = false;
  late TextEditingController _searchController;
  String _searchQuery = '';
  late AnimationController _fabAnimationController;
  Animation<double>? _fabScaleAnimation;
  String? token;
  static const String apiBaseUrl =
      '/api'; // MUDANÇA: Usar baseUrl do AuthService + este path

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();
    uniqueNomes = <String>{}; // CORREÇÃO: Inicializar aqui para hot reload
    _initializeData(); // MUDANÇA: Chamar método unificado
  }

  Future<void> _initializeData() async {
    // NOVO: Método para inicializar tudo
    await _loadToken();
    if (token != null && mounted) {
      if (gerenciarUsuarios) {
        _carregarUsuarios();
      } else {
        _carregarDisciplinas();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    token =
        await AuthService.getToken(); // MUDANÇA: Usar AuthService.getToken()

    if (token == null) {
      _showError('Faça login novamente.');
      if (mounted) {
        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        ); // Opcional: Redireciona para login se necessário
      }
      return;
    }

    if (mounted) setState(() {});
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
      final response = await http.get(
        Uri.parse(
          AuthService.baseUrl + apiBaseUrl + endpoint,
        ), // MUDANÇA: Usar baseUrl do AuthService
        headers: headers,
      );

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

  // NOVO: Carregar disciplinas/notas
  Future<void> _carregarDisciplinas() async {
    if (token == null) {
      _showError('Token não encontrado. Faça login novamente.');
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      final headers = await AuthService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(AuthService.baseUrl + apiBaseUrl + '/notas/disciplinas'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          disciplinas = data
              .map<Disciplina>((json) => Disciplina.fromJson(json))
              .toList();
          uniqueNomes = disciplinas.map((d) => d.nome).toSet();
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
      _showError('Erro ao carregar notas: $e');
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
      final response = await http.post(
        Uri.parse(
          AuthService.baseUrl +
              apiBaseUrl +
              '/enviarEmail/enviar-senha-inicial',
        ),
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

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  List<Usuario> _getUsuariosFiltrados() {
    final listaSegura = usuarios;

    if (listaSegura.isEmpty) {
      return [];
    }

    var filtrados = listaSegura.where((usuario) {
      final tipo = usuario.tipo ?? 'unknown'; // CORREÇÃO: Safe access
      if (widget.isAdmin) {
        return mostrarAlunos
            ? tipo == 'aluno'
            : (tipo == 'professor' ||
                  tipo ==
                      'admin'); // CORREÇÃO: Incluir admins na lista de professores
      } else {
        return tipo == 'aluno';
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

  int get _count {
    if (gerenciarUsuarios) {
      return _getUsuariosFiltrados().length;
    } else {
      return (uniqueNomes ?? <String>{}).length; // CORREÇÃO: Null-safe
    }
  }

  String get _title {
    if (gerenciarUsuarios) {
      return mostrarAlunos ? 'Gerenciar Alunos' : 'Gerenciar Professores';
    } else {
      return 'Gerenciar Notas';
    }
  }

  IconData get _icon {
    if (gerenciarUsuarios) {
      return mostrarAlunos ? Icons.school : Icons.school_outlined;
    } else {
      return Icons.grade;
    }
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
          final response = await http.put(
            Uri.parse(
              AuthService.baseUrl + apiBaseUrl + endpoint + '/' + usuario.id,
            ), // MUDANÇA: Usar baseUrl
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
            // MUDANÇA: Adicionar tipo para create de professor
            body['tipo'] = result['tipo']!;
          }
          final response = await http.post(
            Uri.parse(
              AuthService.baseUrl + apiBaseUrl + endpoint,
            ), // MUDANÇA: Usar baseUrl
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
        final response = await http.delete(
          Uri.parse(
            AuthService.baseUrl + apiBaseUrl + endpoint + '/' + usuario.id,
          ), // MUDANÇA: Usar baseUrl
          headers: headers,
        );

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

  // NOVO: Adicionar atividade para disciplina
  Future<void> _addActivity(
    String disciplinaNome,
    List<Disciplina> group,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) => ActivityDialog(),
    );

    if (result != null && mounted) {
      try {
        final headers = await AuthService.getAuthHeaders();
        for (var dis in group) {
          final body = {
            'tipo': result['tipo'],
            'descricao': result['descricao'],
            'nota': 0.0,
            'peso': result['peso'],
          };
          await http.put(
            Uri.parse(
              AuthService.baseUrl +
                  apiBaseUrl +
                  '/notas/disciplinas/${dis.id}/adicionar-nota',
            ),
            headers: headers,
            body: json.encode(body),
          );
        }
        await _carregarDisciplinas();
        _showSuccess(
          'Atividade "${result['descricao']}" adicionada para todos os alunos.',
        );
      } catch (e) {
        _showError('Erro ao adicionar atividade: $e');
      }
    }
  }

  // NOVO: Editar nota
  Future<void> _editNota(
    String disciplinaId,
    String descricao,
    String? notaId,
    double currentNota,
    double peso,
    String tipo,
  ) async {
    final result = await showDialog<double?>(
      context: context,
      builder: (BuildContext dialogContext) =>
          NotaDialog(current: currentNota, descricao: descricao),
    );

    if (result != null && mounted) {
      try {
        final headers = await AuthService.getAuthHeaders();
        if (notaId != null) {
          // Deletar antiga
          await http.delete(
            Uri.parse(
              AuthService.baseUrl +
                  apiBaseUrl +
                  '/notas/disciplinas/$disciplinaId/remover-nota/$notaId',
            ),
            headers: headers,
          );
        }
        // Adicionar/atualizar
        final body = {
          'tipo': tipo,
          'descricao': descricao,
          'nota': result,
          'peso': peso,
        };
        await http.put(
          Uri.parse(
            AuthService.baseUrl +
                apiBaseUrl +
                '/notas/disciplinas/$disciplinaId/adicionar-nota',
          ),
          headers: headers,
          body: json.encode(body),
        );
        await _carregarDisciplinas();
        _showSuccess('Nota atualizada para $result.');
      } catch (e) {
        _showError('Erro ao atualizar nota: $e');
      }
    }
  }

  Color _getMediaColor(double? media) {
    if (media == null) return Colors.grey;
    if (media >= 8.0) return Colors.green;
    if (media >= 6.0) return Colors.orange;
    return Colors.red;
  }

  Color? _getNotaColor(double? nota) {
    if (nota == null) return null;
    if (nota >= 8.0) return Colors.green;
    if (nota >= 6.0) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final usuariosFiltrados = _getUsuariosFiltrados();
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
            "Painel de Administração",
            style: AppTextStyles.fonteUbuntu.copyWith(
              // Removido backgroundColor desnecessário
              fontWeight: FontWeight.w700,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.grey),
              onPressed: gerenciarUsuarios
                  ? _carregarUsuarios
                  : _carregarDisciplinas,
            ),
          ],
        ),
        floatingActionButton:
            gerenciarUsuarios && (widget.isAdmin || mostrarAlunos)
            ? positionedFab
            : null,
        body: Column(
          children: [
            // Header com estatísticas e filtros
            _buildHeader(primaryColor),

            // Barra de busca (apenas para usuários)
            if (gerenciarUsuarios) _buildSearchBar(),

            // Conteúdo
            Expanded(
              child: carregando
                  ? _buildLoadingState()
                  : gerenciarUsuarios
                  ? (usuariosFiltrados.isEmpty
                        ? _buildEmptyState()
                        : _buildDataTable(usuariosFiltrados, primaryColor))
                  : ((uniqueNomes ?? <String>{}).isEmpty && disciplinas.isEmpty
                        ? _buildEmptyNotas()
                        : _buildGradesContent(primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_icon, color: primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isAdmin && !gerenciarUsuarios
                          ? _title
                          : (gerenciarUsuarios
                                ? (widget.isAdmin
                                      ? 'Gerenciar Usuários'
                                      : 'Gerenciar Alunos')
                                : _title),
                      style: AppTextStyles.fonteUbuntu.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.preto,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $_count ${gerenciarUsuarios ? (mostrarAlunos ? 'alunos' : 'professores') : 'disciplinas'}',
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
          if (gerenciarUsuarios && widget.isAdmin)
            _buildToggleButtons(primaryColor),
          if (widget.isAdmin) ...[
            const SizedBox(height: 16),
            _buildMainToggle(primaryColor),
          ],
        ],
      ),
    );
  }

  // Toggle sub para Alunos/Professores (mantido)
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
              setState(() {
                mostrarAlunos = true;
                carregando = true;
              });
              _carregarUsuarios();
            },
          ),
          const SizedBox(width: 4),
          _buildToggleButton(
            text: 'Professores',
            isActive: !mostrarAlunos,
            primaryColor: primaryColor,
            onTap: () {
              setState(() {
                mostrarAlunos = false;
                carregando = true;
              });
              _carregarUsuarios();
            },
          ),
        ],
      ),
    );
  }

  // NOVO: Toggle principal para Usuários/Notas
  Widget _buildMainToggle(Color primaryColor) {
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
            isActive: gerenciarUsuarios,
            primaryColor: primaryColor,
            onTap: () {
              setState(() {
                gerenciarUsuarios = true;
                mostrarAlunos = true;
                carregando = true;
              });
              _carregarUsuarios();
            },
          ),
          const SizedBox(width: 4),
          _buildToggleButton(
            text: 'Notas',
            isActive: !gerenciarUsuarios,
            primaryColor: primaryColor,
            onTap: () {
              setState(() {
                gerenciarUsuarios = false;
                carregando = true;
              });
              _carregarDisciplinas();
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
            gerenciarUsuarios
                ? 'Carregando usuários...'
                : 'Carregando notas...',
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

  // NOVO: Empty state para notas
  Widget _buildEmptyNotas() {
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
              Icons.grade_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma nota cadastrada',
            style: AppTextStyles.fonteUbuntu.copyWith(
              fontSize: 20,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione disciplinas e notas para os alunos',
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

  // NOVO: Conteúdo para notas
  Widget _buildGradesContent(Color primaryColor) {
    final currentUniqueNomes = uniqueNomes ?? <String>{}; // CORREÇÃO: Null-safe
    final Map<String, List<Disciplina>> groups = {};
    for (var d in disciplinas) {
      groups.putIfAbsent(d.nome, () => []).add(d);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 24),
      itemBuilder: (context, index) {
        final entry = groups.entries.elementAt(index);
        final nome = entry.key;
        final group = entry.value;

        // Unique descrições
        final Set<String> uniqueDescs = <String>{};
        for (var dis in group) {
          for (var det in dis.detalhes) {
            uniqueDescs.add(det.descricao);
          }
        }
        final List<String> columns = uniqueDescs.toList()..sort();

        return _buildDisciplineCard(nome, group, columns, primaryColor);
      },
    );
  }

  Widget _buildDisciplineCard(
    String nome,
    List<Disciplina> group,
    List<String> columns,
    Color primaryColor,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Header da disciplina
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  nome,
                  style: AppTextStyles.fonteUbuntu.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addActivity(nome, group),
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    'Atividade / Prova',
                    style: AppTextStyles.fonteUbuntu.copyWith(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: AppColors.branco,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tabela
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
              dataRowHeight: 60,
              headingTextStyle: AppTextStyles.fonteUbuntu.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF424242),
                fontSize: 14,
              ),
              dataTextStyle: AppTextStyles.fonteUbuntuSans.copyWith(
                color: const Color(0xFF424242),
                fontSize: 14,
              ),
              columns: [
                const DataColumn(label: Text('Aluno')),
                ...columns.map(
                  (c) =>
                      DataColumn(label: Text(c, textAlign: TextAlign.center)),
                ),
                const DataColumn(label: Text('Média')),
              ],
              rows: group.map((dis) {
                return DataRow(
                  cells: [
                    DataCell(Text(dis.alunoNome)),
                    ...columns.map((col) {
                      Detalhe? det;
                      try {
                        det = dis.detalhes.firstWhere(
                          (d) => d.descricao == col,
                        );
                      } catch (_) {
                        det = null;
                      }
                      final String value = det?.nota != null
                          ? det!.nota!.toStringAsFixed(1)
                          : '–';
                      final Color? textColor = _getNotaColor(det?.nota);
                      return DataCell(
                        GestureDetector(
                          onTap: () => _editNota(
                            dis.id,
                            col,
                            det?.id,
                            det?.nota ?? 0.0,
                            det?.peso ?? 1.0,
                            det?.tipo ??
                                (col.toLowerCase().contains('prova')
                                    ? 'prova'
                                    : 'atividade'),
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              value,
                              style: TextStyle(color: textColor),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      );
                    }),
                    DataCell(
                      Text(
                        dis.mediaFinal?.toStringAsFixed(1) ?? '–',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getMediaColor(dis.mediaFinal),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Tabela de usuários (mantida)
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

// NOVO: Diálogo para adicionar atividade
class ActivityDialog extends StatefulWidget {
  const ActivityDialog({super.key});

  @override
  State<ActivityDialog> createState() => _ActivityDialogState();
}

class _ActivityDialogState extends State<ActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _pesoController = TextEditingController(text: '1.0');
  bool _isProva = true;

  @override
  void dispose() {
    _descricaoController.dispose();
    _pesoController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final peso = double.tryParse(_pesoController.text) ?? 1.0;
      Navigator.of(context).pop({
        'tipo': _isProva ? 'prova' : 'atividade',
        'descricao': _descricaoController.text,
        'peso': peso,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.azulClaro;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Adicionar Atividade / Prova',
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Tipo: Prova'),
                    value: _isProva,
                    onChanged: (value) => setState(() => _isProva = value),
                    activeColor: primaryColor,
                  ),
                  TextFormField(
                    controller: _descricaoController,
                    decoration: InputDecoration(
                      labelText: 'Descrição (ex: Prova 1)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.description),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Descrição obrigatória' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _pesoController,
                    decoration: InputDecoration(
                      labelText: 'Peso (padrão 1.0)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.balance),
                    ),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final peso = double.tryParse(value ?? '');
                      if (peso == null || peso <= 0)
                        return 'Peso válido obrigatório';
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// NOVO: Diálogo para editar nota
class NotaDialog extends StatefulWidget {
  final double current;
  final String descricao;

  const NotaDialog({super.key, required this.current, required this.descricao});

  @override
  State<NotaDialog> createState() => _NotaDialogState();
}

class _NotaDialogState extends State<NotaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _notaController.text = widget.current.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _notaController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final nota = double.tryParse(_notaController.text) ?? 0.0;
      Navigator.of(context).pop(nota);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = AppColors.azulClaro;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nota para ${widget.descricao}',
              style: AppTextStyles.fonteUbuntu.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _notaController,
                decoration: InputDecoration(
                  labelText: 'Nota (0-10)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(Icons.star),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  final nota = double.tryParse(value ?? '');
                  if (nota == null || nota < 0 || nota > 10)
                    return 'Nota entre 0 e 10';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
