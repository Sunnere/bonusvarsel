import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onSuccess;

  const LoginPage({super.key, this.onSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  int _failCount = 0;
  bool _showForgotPassword = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isLogin) {
        await AuthService.instance.signInWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      } else {
        await AuthService.instance.registerWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      }
      if (!mounted) return;
      _failCount = 0;
      _showForgotPassword = false;
      widget.onSuccess?.call();
      Navigator.of(context).pop();
    } on Exception catch (e) {
      final msg = e.toString()
        .replaceAll('Exception: ', '')
        .replaceAll('[firebase_auth/user-not-found]', 'Finner ikke brukeren. Sjekk e-postadressen.')
        .replaceAll('[firebase_auth/wrong-password]', 'Feil passord. Prøv igjen.')
        .replaceAll('[firebase_auth/invalid-credential]', 'Feil e-post eller passord.')
        .replaceAll('[firebase_auth/email-already-in-use]', 'E-postadressen er allerede i bruk.')
        .replaceAll('[firebase_auth/weak-password]', 'Passordet er for svakt. Bruk minst 6 tegn.')
        .replaceAll('[firebase_auth/invalid-email]', 'Ugyldig e-postadresse.')
        .replaceAll('[firebase_auth/network-request-failed]', 'Nettverksfeil. Sjekk internettforbindelsen.')
        .replaceAll('[firebase_auth/too-many-requests]', 'For mange forsøk. Vent litt og prøv igjen.');
      if (mounted) {
        FocusScope.of(context).unfocus();
        setState(() {
          _error = msg;
          if (_isLogin) {
            _failCount++;
            if (_failCount >= 1) _showForgotPassword = true;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Skriv inn e-postadressen din først.');
      return;
    }
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      setState(() {
        _error = null;
        _failCount = 0;
        _showForgotPassword = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tilbakestillingslenke sendt til $email'),
          backgroundColor: const Color(0xFF1C3A5E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 5),
        ),
      );
    } on Exception catch (e) {
      setState(() => _error = 'Klarte ikke sende e-post. Sjekk adressen og prøv igjen.');
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await AuthService.instance.signInWithGoogle();
      if (result == null) {
        setState(() { _loading = false; });
        return;
      }
      if (!mounted) return;
      _failCount = 0;
      _showForgotPassword = false;
      widget.onSuccess?.call();
      Navigator.of(context).pop();
    } on Exception catch (e) {
      final msg = e.toString()
        .replaceAll('Exception: ', '')
        .replaceAll('[firebase_auth/user-not-found]', 'Finner ikke brukeren. Sjekk e-postadressen.')
        .replaceAll('[firebase_auth/wrong-password]', 'Feil passord. Prøv igjen.')
        .replaceAll('[firebase_auth/invalid-credential]', 'Feil e-post eller passord.')
        .replaceAll('[firebase_auth/email-already-in-use]', 'E-postadressen er allerede i bruk.')
        .replaceAll('[firebase_auth/weak-password]', 'Passordet er for svakt. Bruk minst 6 tegn.')
        .replaceAll('[firebase_auth/invalid-email]', 'Ugyldig e-postadresse.')
        .replaceAll('[firebase_auth/network-request-failed]', 'Nettverksfeil. Sjekk internettforbindelsen.')
        .replaceAll('[firebase_auth/too-many-requests]', 'For mange forsøk. Vent litt og prøv igjen.');
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.instance.signInWithApple();
      if (!mounted) return;
      _failCount = 0;
      _showForgotPassword = false;
      widget.onSuccess?.call();
      Navigator.of(context).pop();
    } on Exception catch (e) {
      final msg = e.toString()
        .replaceAll('Exception: ', '')
        .replaceAll('Apple-innlogging avbrutt', '')
        .replaceAll('[firebase_auth/network-request-failed]', 'Nettverksfeil. Sjekk internettforbindelsen.')
        .replaceAll('[firebase_auth/too-many-requests]', 'For mange forsøk. Vent litt og prøv igjen.');
      if (msg.isNotEmpty) setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_isLogin ? 'Logg inn' : 'Opprett konto'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  ),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bonusvarsel',
                      style: TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin
                          ? 'Logg inn for å se dine kort og poeng'
                          : 'Opprett konto og start å samle poeng smartere',
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Apple Sign-In
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _signInWithApple,
                  icon: const Icon(Icons.apple, size: 22),
                  label: const Text(
                    'Fortsett med Apple',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Google Sign-In
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF334155)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata, size: 26),
                  label: const Text(
                    'Fortsett med Google',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFF334155))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'eller e-post',
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFF334155))),
                ],
              ),
              const SizedBox(height: 20),

              // E-post
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'E-post',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1A1D24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Passord
              TextField(
                controller: _passwordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Passord',
                  labelStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: const Color(0xFF1A1D24),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              if (_showForgotPassword && _isLogin) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.lock_reset, size: 16),
                    label: const Text('Send nytt passord på e-post'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF60A5FA),
                      side: const BorderSide(color: Color(0xFF60A5FA)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _loading ? null : _sendPasswordReset,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],

              const SizedBox(height: 20),

              // Submit
              SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2F80ED),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _loading ? null : _submitEmail,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Logg inn' : 'Opprett konto',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Bytt mellom login og register
              TextButton(
                onPressed: () => setState(() {
                  _isLogin = !_isLogin;
                  _error = null;
                }),
                child: Text(
                  _isLogin
                      ? 'Har ikke konto? Opprett her'
                      : 'Har allerede konto? Logg inn',
                  style: const TextStyle(color: Color(0xFF8DC3FF)),
                ),
              ),

              if (_isLogin)
                TextButton(
                  onPressed: () async {
                    if (_emailCtrl.text.isEmpty) {
                      setState(() => _error = 'Skriv inn e-post først');
                      return;
                    }
                    await AuthService.instance
                        .sendPasswordReset(_emailCtrl.text.trim());
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tilbakestillingslenke sendt til e-post'),
                      ),
                    );
                  },
                  child: const Text(
                    'Glemt passord?',
                    style: TextStyle(color: Colors.white38),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
