import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      ra: json['ra'],
      tipo: json['tipo'],
      fotoUrl: json['fotoUrl'],
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
    _initializeData(); // MUDANÇA: Chamar método unificado
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
            'nome': result['nome'],
            'email': result['email'],
            if (isAluno) 'ra': result['ra'],
          };
          if (!isAluno && result.containsKey('tipo')) {
            // MUDANÇA: Adicionar tipo para update de professor
            body['tipo'] = result['tipo'];
          }
          final response = await http.put(
            Uri.parse(
              AuthService.baseUrl + apiBaseUrl + endpoint + '/' + usuario.id,
            ), // MUDANÇA: Usar baseUrl
            headers: headers,
            body: json.encode(body),
          );

          if (response.statusCode == 200) {
            final updatedData =
                json.decode(response.body)['aluno'] ??
                json.decode(response.body)['professor'];
            var updatedUser = Usuario.fromJson(updatedData);
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
            'nome': result['nome'],
            'email': result['email'],
            if (isAluno) 'ra': result['ra'],
          };
          if (!isAluno && result.containsKey('tipo')) {
            // MUDANÇA: Adicionar tipo para create de professor
            body['tipo'] = result['tipo'];
          }
          final response = await http.post(
            Uri.parse(
              AuthService.baseUrl + apiBaseUrl + endpoint,
            ), // MUDANÇA: Usar baseUrl
            headers: headers,
            body: json.encode(body),
          );

          if (response.statusCode == 201) {
            final newData =
                json.decode(response.body)['aluno'] ??
                json.decode(response.body)['professor'];
            var newUser = Usuario.fromJson(newData);
            newUser = _corrigirFotoUrl(newUser);
            setState(() {
              usuarios.add(newUser);
            });
            _showSuccess('Adicionado com sucesso!');
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
              onPressed: _carregarUsuarios,
            ),
          ],
        ),
        floatingActionButton: (widget.isAdmin || mostrarAlunos)
            ? positionedFab
            : null,
        body: Column(
          children: [
            // Header com estatísticas e filtros
            _buildHeader(primaryColor, usuariosFiltrados.length),

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
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor, int count) {
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
          if (widget.isAdmin) _buildToggleButtons(primaryColor),
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
            'Carregando dados...',
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
