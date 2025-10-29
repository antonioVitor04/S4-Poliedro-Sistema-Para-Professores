// main_aluno_page.dart
import 'dart:async'; // << NOVO
import 'package:flutter/material.dart';
import 'package:sistema_poliedro/src/services/auth_service.dart';
import '../../components/adaptive_navigation.dart';
import '../../components/auth_guard.dart';
import '../../styles/cores.dart';
import 'disciplina/disciplinas_page.dart';
import 'disciplina/disciplina_detail_page.dart';
import 'notas_aluno_page.dart';
import 'calendario_aluno_page.dart';
import 'notificacoes_aluno_page.dart'; // mantém a página
import '../perfil_page.dart';

// contador global + sino com badge
import 'notificacoes_aluno_page.dart' show notificationsUnreadCount;
import '../../components/bell_with_badge.dart';

// também vamos precisar do service de notificações para buscar a lista
import '../../services/notificacoes_service.dart';

class MainAlunoPage extends StatefulWidget {
  final String initialRoute;
  const MainAlunoPage({super.key, this.initialRoute = '/disciplinas'});

  @override
  State<MainAlunoPage> createState() => _MainAlunoPageState();
}

class _MainAlunoPageState extends State<MainAlunoPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver { // << NOVO
  late String _currentRoute;
  String _previousRoute = '/disciplinas'; // << USADO AGORA NO TOGGLE DO PERFIL
  bool _isProfileOpen = false;
  String? _token;
  bool _isLoading = true;

  late AnimationController _profileController;
  late Animation<double> _profileAnimation;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  // late para injetar os ícones com badge no initState
  late List<NavigationItem> _navItems;

  // << NOVO: timer de atualização do contador
  Timer? _notifTimer;

  // Navegação interna para detalhes de disciplina
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
    WidgetsBinding.instance.addObserver(this); // << NOVO
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

    // Itens de navegação (ícone de notificações = seu ícone antigo + badge)
    _navItems = [
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
        icon: Icons.notifications, // fallback
        route: '/notificacoes',
        // Sidebar não selecionada (fundo teal) => ícone BRANCO
        iconWidget: ValueListenableBuilder<int>(
          valueListenable: notificationsUnreadCount,
          builder: (_, c, __) => BellWithBadge(
            count: c,
            bellColor: Colors.white,
            iconData: Icons.notifications,
            size: 32,
          ),
        ),
        // Selecionado (fundo branco) => ícone PRETO
        activeIconWidget: ValueListenableBuilder<int>(
          valueListenable: notificationsUnreadCount,
          builder: (_, c, __) => BellWithBadge(
            count: c,
            bellColor: Colors.black,
            iconData: Icons.notifications,
            size: 32,
          ),
        ),
      ),
    ];

    // << NOVO: primeira atualização imediata do badge + polling periódico
    _refreshUnread();
    _notifTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _refreshUnread());
  }

  // << NOVO: atualiza contador sem abrir a página
  Future<void> _refreshUnread() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;
      ApiService.setToken(token);

      // Se você tiver um endpoint "count" mais leve, troque por ele.
      // Ex.: final count = await ApiService.fetchUnreadCount();
      //      notificationsUnreadCount.value = count;

      final list = await ApiService.fetchNotificacoes(null);
      final int unread = list.where((m) => m.isUnread).length;
      if (notificationsUnreadCount.value != unread) {
        notificationsUnreadCount.value = unread;
      }
    } catch (_) {
      // silencioso: não queremos quebrar a UI se falhar
    }
  }

  // << NOVO: atualiza ao voltar do background
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshUnread();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // << NOVO
    _notifTimer?.cancel(); // << NOVO
    _profileController.dispose();
    super.dispose();
  }

  void _onNavTap(String route) {
    setState(() {
      if (route == '/perfil') {
        // CORRIGIDO: LÓGICA IGUAL À DO PROFESSOR - SALVA ANTERIOR E MUDA CURRENT
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
        // painel de perfil animado
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