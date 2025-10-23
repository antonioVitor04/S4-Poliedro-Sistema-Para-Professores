// main_aluno_page.dart
import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/pages/professor/administracao_page.dart';
import '../../components/adaptive_navigation.dart';
import '../../components/auth_guard.dart';
import '../../styles/cores.dart';
import 'disciplina/disciplinas_page.dart';
import 'disciplina/disciplina_detail_page.dart';

import 'calendario_professor_page.dart';
import 'notificacoes_professor_page.dart';
import '../perfil_page.dart';
import 'administracao_page.dart';

class HomeProfessor extends StatefulWidget {
  final String initialRoute;
  const HomeProfessor({super.key, this.initialRoute = '/disciplinas'});

  @override
  State<HomeProfessor> createState() => _HomeProfessorState();
}

class _HomeProfessorState extends State<HomeProfessor>
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
    NavigationItem(
      label: "Administração",
      icon: Icons.admin_panel_settings,
      route: '/administracao',
    ),
  ];

  //  FUNÇÃO PARA NAVEGAÇÃO INTERNA (AGORA PÚBLICA)
  void _navigateToDetail(String slug, String titulo) {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) =>
            DisciplinaDetailPageProfessor(slug: slug, titulo: titulo),
      ),
    );
  }

  //  MAP DE PÁGINAS COM CALLBACK
  Map<String, Widget> get _pages {
    return {
      '/disciplinas': DisciplinasPageProfessor(
        onNavigateToDetail: _navigateToDetail, //  PASSA A FUNÇÃO
      ),

      '/calendario': const CalendarioPageProfessor(),
      '/notificacoes': const NotificacoesPageProfessor(),
      '/administracao': AdministracaoPage(),
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
          Expanded(child: mainContent),
        ],
      );
    } else {
      // Para mobile, usa overlay full screen
      mainContent = Stack(
        children: [
          mainContent,
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
        body: mainContent,
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
