// main_aluno_page.dart
import 'package:flutter/material.dart';
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

  // 🔥 FUNÇÃO PARA NAVEGAÇÃO INTERNA (AGORA PÚBLICA)
  void _navigateToDetail(String slug, String titulo) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => DisciplinaDetailPage(slug: slug, titulo: titulo),
      ),
    );
  }

  // 🔥 MAP DE PÁGINAS COM CALLBACK
  Map<String, Widget> get _pages {
    return {
      '/disciplinas': DisciplinasPage(
        onNavigateToDetail: _navigateToDetail, // 🔥 PASSA A FUNÇÃO
      ),
      '/notas': const NotasPage(),
      '/calendario': const CalendarioPage(),
      '/notificacoes': const NotificacoesPage(),
    };
  }

  @override
  void initState() {
    super.initState();
    _currentRoute = widget.initialRoute;

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
        if (!_isProfileOpen) {
          _previousRoute = _currentRoute;
          _currentRoute = '/perfil';
          _isProfileOpen = true;
          _profileController.forward();
        } else {
          _isProfileOpen = false;
          _currentRoute = _previousRoute;
          _profileController.reverse();
        }
      } else {
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

  Widget _buildProfileOverlay() {
    final bool isWeb = MediaQuery.of(context).size.width >= 600;
    return AnimatedBuilder(
      animation: _profileAnimation,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final profileWidth = isWeb ? 300.0 : screenWidth;
        return Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: Container(
            width: profileWidth,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF7FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: const Offset(
                    -2,
                    0,
                  ), // Sombra para a esquerda no mobile/web
                  blurRadius: 6,
                ),
              ],
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(
                      1.0,
                      0.0,
                    ), // Começa fora da tela à direita
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _profileController,
                      curve: Curves.easeInOut,
                    ),
                  ),
              child: _isProfileOpen ? PerfilPage() : const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isWeb = MediaQuery.of(context).size.width >= 600;

    Widget mainContent = Navigator(
      key: _navigatorKey,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) =>
              _pages[_currentRoute] ?? _pages[_previousRoute]!,
        );
      },
    );

    if (isWeb) {
      mainContent = Row(
        children: [
          AdaptiveNavigation(
            currentRoute: _currentRoute,
            items: _navItems,
            isWeb: true,
            onTap: _onNavTap,
            profileSelected: _isProfileOpen,
          ),
          Expanded(child: mainContent),
        ],
      );
    }

    return AuthGuard(
      child: Scaffold(
        backgroundColor: AppColors.branco,
        appBar: !isWeb
            ? AppBar(
                backgroundColor: AppColors.azulEscuro,
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => _onNavTap('/perfil'), // Agora abre o perfil
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
        body: Stack(
          children: [mainContent, if (_isProfileOpen) _buildProfileOverlay()],
        ),
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
