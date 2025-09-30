import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/login_page.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  const AuthGuard({Key? key, required this.child}) : super(key: key);

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _loading = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    setState(() {
      _loggedIn = token != null && token.isNotEmpty;
      _loading = false;
    });

    if (!_loggedIn && mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return widget.child;
  }
}
