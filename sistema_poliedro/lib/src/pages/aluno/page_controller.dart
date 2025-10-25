// main_aluno_page.dart
import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/services/auth_service.dart';
import '../../components/adaptive_navigation.dart';
import '../../components/auth_guard.dart';
import '../../styles/cores.dart';
import 'disciplina/disciplinas_page.dart';
import 'disciplina/disciplina_detail_page.dart';
import 'notas_aluno_page.dart';
import 'calendario_aluno_page.dart';
import 'notificacoes_aluno_page.dart';
import '../perfil_page.dart';

class MainAlunoPage extends StatefulWidget {
  final String initialRoute;
  const MainAlunoPage({super.key, this.initialRoute = '/disciplinas'});

  @override
  State<MainAlunoPage> createState() => _MainAlunoPageState();
}

class _MainAlunoPageState extends State<MainAlunoPage>
    with SingleTickerProviderStateMixin {
  late String _currentRoute;
  String _previousRoute = '/disciplinas';
  bool _isProfileOpen = false;
  String? _token;
  bool _isLoading = true;

  late AnimationController _profileController;
  late Animation<double> _profileAnimation;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  final List<NavigationItem> _navItems = [
    NavigationItem(label: "Perfil", icon: Icons.person, route: '/perfil'),
    NavigationItem(
      label: "Disciplinas",
      icon: Icons.my_library_books_rounded,
      route: '/disciplinas',
    ),
    NavigationItem(label: "Notas", icon: Icons.bar_chart, route: '/notas'),
    NavigationItem(
      label: "Calendário",
      icon: Icons.calendar_month_outlined,
      route: '/calendario',
    ),
    NavigationItem(
      label: "Notificações",
      icon: Icons.notifications,
      route: '/notificacoes',
    ),
  ];

  // FUNÇÃO PARA NAVEGAÇÃO INTERNA
  void _navigateToDetail(String slug, String titulo) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => DisciplinaDetailPage(slug: slug, titulo: titulo),
      ),
    );
  }

  Future<void> _loadToken() async {
    final token = await AuthService.getToken();
    setState(() {
      _token = token;
      _isLoading = false;
    });
  }

  // MAP DE PÁGINAS COM CALLBACK
  Map<String, Widget> get _pages {
    return {
      '/disciplinas': DisciplinasPage(onNavigateToDetail: _navigateToDetail),
      '/notas': NotasPage(token: _token ?? ''),
      '/calendario': const CalendarioPageAluno(),
      '/notificacoes': const NotificacoesPage(),
    };
  }

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;
    _loadToken(); // Carrega o token ao inicializar

    _profileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _profileAnimation = CurvedAnimation(
      parent: _profileController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  void _onNavTap(String route) {
    setState(() {
      if (route == '/perfil') {
        // APENAS ABRE/FECHA O MENU LATERAL, NÃO MUDA A ROTA
        _isProfileOpen = !_isProfileOpen;
        if (_isProfileOpen) {
          _profileController.forward();
        } else {
          _profileController.reverse();
        }
      } else {
        // PARA OUTRAS ROTAS, MUDA A PÁGINA E FECHA O PERFIL
        _currentRoute = route;
        if (_isProfileOpen) {
          _isProfileOpen = false;
          _profileController.reverse();
        }

        // VOLTAR PARA A ROTA PRINCIPAL AO TROCAR DE PÁGINA
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      }
    });
  }

  Widget _buildWebLayout() {
    return Row(
      children: [
        AdaptiveNavigation(
          currentRoute: _currentRoute,
          items: _navItems,
          isWeb: true,
          onTap: _onNavTap,
          profileSelected: _isProfileOpen,
        ),
        // Profile panel animado entre sidebar e conteúdo
        AnimatedBuilder(
          animation: _profileAnimation,
          builder: (context, child) {
            return Container(
              width: _profileAnimation.value * 300,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    offset: const Offset(2, 0),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: Container(
                      width: 300,
                      height: MediaQuery.of(context).size.height,
                      color: const Color(0xFFFEF7FF),
                      child: _isProfileOpen
                          ? PerfilPage()
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Navigator(
                  key: _navigatorKey,
                  onGenerateRoute: (settings) {
                    return MaterialPageRoute(
                      builder: (context) =>
                          _pages[_currentRoute] ?? _pages['/disciplinas']!,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Navigator(
                key: _navigatorKey,
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) =>
                        _pages[_currentRoute] ?? _pages['/disciplinas']!,
                  );
                },
              ),
        if (_isProfileOpen)
          Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            color: const Color(0xFFFEF7FF),
            child: PerfilPage(),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width >= 600;

    return AuthGuard(
      child: Scaffold(
        backgroundColor: AppColors.branco,
        appBar: !isWeb
            ? AppBar(
                backgroundColor: AppColors.azulEscuro,
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _onNavTap('/perfil'),
                  color: AppColors.branco,
                ),
                title: Image.asset(
                  'assets/images/logo.png',
                  width: 50,
                  height: 50,
                ),
                centerTitle: true,
              )
            : null,
        body: isWeb ? _buildWebLayout() : _buildMobileLayout(),
        bottomNavigationBar: !isWeb
            ? AdaptiveNavigation(
                currentRoute: _currentRoute,
                items: _navItems,
                onTap: _onNavTap,
              )
            : null,
      ),
    );
  }
}
