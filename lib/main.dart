import 'package:flutter/material.dart';
import 'package:remoview_mobile/screens/home_screen.dart';
import 'package:remoview_mobile/screens/auth_screen.dart';
import 'package:remoview_mobile/services/token_store.dart';

void main() {
  runApp(const RemoviewApp());
}

class RemoviewApp extends StatelessWidget {
  const RemoviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Remoview Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C4DFF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0F1115),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F1115),
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF171A21),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late Future<String?> _tokenFuture;

  @override
  void initState() {
    super.initState();
    _tokenFuture = TokenStore().getToken();
  }

  Future<void> _recheck() async {
    setState(() {
      _tokenFuture = TokenStore().getToken();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _tokenFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snap.data;
        final authed = token != null && token.isNotEmpty;

        if (authed) {
          return const RemoviewHomePage();
        }

        return AuthScreenWrapper(onDone: _recheck);
      },
    );
  }
}

// AuthScreen kapanınca gate yeniden token kontrol etsin diye wrapper
class AuthScreenWrapper extends StatelessWidget {
  final VoidCallback onDone;
  const AuthScreenWrapper({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      onGenerateRoute: (_) =>
          MaterialPageRoute(builder: (_) => const AuthScreen()),
      observers: [_PopObserver(onDone)],
    );
  }
}

class _PopObserver extends NavigatorObserver {
  final VoidCallback onDone;
  _PopObserver(this.onDone);

  @override
  void didPop(Route route, Route? previousRoute) {
    onDone();
    super.didPop(route, previousRoute);
  }
}
