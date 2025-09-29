import 'package:flutter/material.dart';
import '../components/adaptive_navigation.dart';
import 'package:flutter/foundation.dart';
import '../styles/cores.dart';

class HomeAluno extends StatefulWidget {
  const HomeAluno({super.key});

  @override
  State<HomeAluno> createState() => _HomeAlunoState();
}

class _HomeAlunoState extends State<HomeAluno> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Center(child: Text("Perfil")),
    Center(child: Text("Disciplinas")),
    Center(child: Text("Notas")),
    Center(child: Text("Calendário")),
    Center(child: Text("Notificações")),
  ];

  final List<NavigationItem> _navItems = [
    NavigationItem(label: "Perfil", icon: Icons.person),
    NavigationItem(label: "Disciplinas", icon: Icons.my_library_books_rounded),
    NavigationItem(label: "Notas", icon: Icons.bar_chart),
    NavigationItem(label: "Calendário", icon: Icons.calendar_month_outlined),
    NavigationItem(label: "Notificações", icon: Icons.notifications),
  ];

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isDesktop = kIsWeb && width >= 600;

    return Scaffold(
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: AppColors.azulEscuro,
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {}, // Aqui você pode abrir um Drawer se quiser
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
              currentIndex: _selectedIndex,
              onTap: _onNavTap,
              items: _navItems,
              isDesktop: true,
            ),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: !isDesktop
          ? AdaptiveNavigation(
              currentIndex: _selectedIndex,
              onTap: _onNavTap,
              items: _navItems,
            )
          : null,
    );
  }
}
