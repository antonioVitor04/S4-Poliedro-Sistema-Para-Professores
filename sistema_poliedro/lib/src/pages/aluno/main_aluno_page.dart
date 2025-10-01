// main_aluno_page.dart
import 'package:flutter/material.dart';
import '../../components/adaptive_navigation.dart';
import '../../components/auth_guard.dart';
import '../../styles/cores.dart';
import 'disciplina/disciplinas_aluno_page.dart';
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

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 600;

    return AuthGuard(
      child: Scaffold(
        backgroundColor: AppColors.branco,
        appBar: !isDesktop
            ? AppBar(
                backgroundColor: AppColors.azulEscuro,
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {},
                ),
                title: Image.asset(
                  'assets/images/logo.png',
                  width: 50,
                  height: 50,
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () {},
                  ),
                ],
              )
            : null,
        body: Row(
          children: [
            if (isDesktop)
              AdaptiveNavigation(
                currentRoute: _currentRoute,
                items: _navItems,
                isDesktop: true,
                onTap: _onNavTap,
                profileSelected: _isProfileOpen,
              ),
            if (isDesktop)
              AnimatedBuilder(
                animation: _profileAnimation,
                builder: (context, child) {
                  return Stack(
                    children: [
                      Container(
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
                      ),
                      Positioned(
                        right: 0,
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
                  );
                },
              ),

            Expanded(
              child: Navigator(
                key: _navigatorKey,
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) =>
                        _pages[_currentRoute] ?? _pages[_previousRoute]!,
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: !isDesktop
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
