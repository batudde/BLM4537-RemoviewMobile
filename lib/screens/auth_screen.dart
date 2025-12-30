import 'package:flutter/material.dart';
import 'package:remoview_mobile/services/auth_service.dart';
import 'package:remoview_mobile/services/token_store.dart';
import 'package:remoview_mobile/screens/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final pass = _pass.text.trim();

    if (!email.contains('@') || pass.length < 3) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email/şifre geçersiz.')));
      return;
    }

    setState(() => _loading = true);

    try {
      if (_isLogin) {
        final token = await _auth.login(email: email, password: pass);

        // token + email kaydet (profilde lazım)
        await TokenStore().saveToken(token);
        await TokenStore().saveEmail(email);

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Giriş başarılı ✅')));

        // ✅ Eğer bu AuthScreen bir yerden "push" ile açıldıysa pop et (FilmDetail vb.)
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context, true);
        } else {
          // ✅ Logout sonrası gibi: stack boş -> direkt Home'a git
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const RemoviewHomePage()),
            (_) => false,
          );
        }
      } else {
        await _auth.register(email: email, password: pass);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kayıt başarılı. Şimdi giriş yap ✅')),
        );

        setState(() => _isLogin = true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Auth hata: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Giriş Yap' : 'Kayıt Ol')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Şifre'),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(
                      _loading ? '...' : (_isLogin ? 'Giriş Yap' : 'Kayıt Ol'),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? 'Hesabın yok mu? Kayıt ol'
                        : 'Hesabın var mı? Giriş yap',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
