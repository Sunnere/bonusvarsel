import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bonusvarsel_dev_hub_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/onboarding_service.dart';
import '../services/entitlement_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _versionTaps = 0;
  final _codeController = TextEditingController();
  bool _trialActive = false;
  bool _trialExpired = false;
  String _currentPlan = 'free';
  bool _codeError = false;

  static const _eliteCode = 'ELITE2026';
  static const _trialKey = 'trial_start_date';

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final trialStart = prefs.getString(_trialKey);
    final plan = EntitlementService.instance.plan;

    if (trialStart != null) {
      final start = DateTime.parse(trialStart);
      final diff = DateTime.now().difference(start).inDays;
      if (diff < 7) {
        setState(() { _trialActive = true; _trialExpired = false; });
      } else {
        setState(() { _trialActive = false; _trialExpired = true; });
        if (plan == 'premium' && prefs.getBool('is_trial') == true) {
          await EntitlementService.instance.clear();
        }
      }
    }
    setState(() => _currentPlan = plan);
  }


  Widget _statusRow(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(
          color: Color(0xFFC8D8E8), fontSize: 12)),
      ]),
    );
  }

  Future<void> _startTrial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_trialKey, DateTime.now().toIso8601String());
    await prefs.setBool('is_trial', true);
    await EntitlementService.instance.unlock('premium_monthly');
    setState(() { _trialActive = true; _currentPlan = 'premium'; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎉 Premium aktivert i 7 dager! Velkommen!')),
      );
    }
  }

  Future<void> _redeemCode() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code == _eliteCode) {
      await EntitlementService.instance.unlock('elite_monthly');
      setState(() { _currentPlan = 'elite'; _codeError = false; });
      _codeController.clear();
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF152B4A),
            title: const Text('🏆 Elite aktivert!',
              style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w800)),
            content: const Text(
              'Takk for at du tester Bonusvarsel!\n\nDu har nå Elite-tilgang med 10 favoritter, VIP-varsler og SkyTeam-bonus.\n\nVi setter stor pris på tilbakemeldingen din! 🙏',
              style: TextStyle(color: Color(0xFFC8D8E8), height: 1.5)),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD4AF37)),
                onPressed: () => Navigator.pop(context),
                child: const Text('Takk!', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        );
      }
    } else {
      setState(() => _codeError = true);
    }
  }

  @override

  void _showEmailLogin(BuildContext context) {
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F2340),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24,
          MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Logg inn / Sign in',
            style: TextStyle(color: Color(0xFFF8F6F0),
              fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: Color(0xFFF8F6F0)),
            decoration: const InputDecoration(
              labelText: 'E-post / Email',
              labelStyle: TextStyle(color: Color(0xFF8BA5C0)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3D6490))),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF60A5FA))),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: passCtrl,
            obscureText: true,
            style: const TextStyle(color: Color(0xFFF8F6F0)),
            decoration: const InputDecoration(
              labelText: 'Passord / Password',
              labelStyle: TextStyle(color: Color(0xFF8BA5C0)),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3D6490))),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF60A5FA))),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB)),
              onPressed: () async {
                try {
                  await AuthService.instance.signInWithEmail(
                    emailCtrl.text.trim(), passCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Feil: $e')));
                  }
                }
              },
              child: const Text('Logg inn / Sign in'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF60A5FA),
                side: const BorderSide(color: Color(0xFF60A5FA)),
              ),
              onPressed: () async {
                try {
                  await AuthService.instance.registerWithEmail(
                    emailCtrl.text.trim(), passCtrl.text.trim());
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Feil: $e')));
                  }
                }
              },
              child: const Text('Lag bruker / Create account'),
            ),
          ),
        ]),
      ),
    );
  }

  Future<void> _resetOnboarding() async {
    await OnboardingService.reset();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Onboarding nullstilt — restart appen for å se den på nytt')),
      );
    }
  }

  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final isPaid = _currentPlan != 'free';

    return Scaffold(
      appBar: AppBar(title: const Text('Innstillinger')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [


          // ── ABONNEMENT STATUS ─────────────────────────────────────
          if (isPaid)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _currentPlan == 'elite'
                    ? [const Color(0xFF1A1040), const Color(0xFF110A28)]
                    : [const Color(0xFF0A1F14), const Color(0xFF0F2340)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _currentPlan == 'elite'
                    ? const Color(0xFFD4AF37).withOpacity(0.6)
                    : const Color(0xFF34D399).withOpacity(0.5),
                  width: 1.5),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(_currentPlan == 'elite' ? '🏆' : '⭐',
                    style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      _currentPlan == 'elite' ? 'Elite-medlem' : 'Premium-medlem',
                      style: TextStyle(
                        color: _currentPlan == 'elite'
                          ? const Color(0xFFD4AF37)
                          : const Color(0xFF34D399),
                        fontSize: 18, fontWeight: FontWeight.w900)),
                    Text(
                      _currentPlan == 'elite' ? '89 kr/mnd' : '49 kr/mnd',
                      style: const TextStyle(
                        color: Color(0xFFC8D8E8), fontSize: 13)),
                  ]),
                ]),
                const SizedBox(height: 12),
                ..._currentPlan == 'elite' ? [
                  _statusRow('✅', 'Alt i Premium'),
                  _statusRow('✅', '10 Trumf Netthandel-favoritter'),
                  _statusRow('✅', '10 SAS Shopping-favoritter'),
                  _statusRow('✅', 'SAS Bonusreiser-oversikt'),
                  _statusRow('✅', 'SkyTeam-flyselskaper'),
                  _statusRow('✅', 'VIP-varsler'),
                ] : [
                  _statusRow('✅', 'Alt i Gratis'),
                  _statusRow('✅', '5 Trumf Netthandel-favoritter'),
                  _statusRow('✅', '5 SAS Shopping-favoritter'),
                  _statusRow('✅', 'SAS fly-tilbudsvarsler'),
                  _statusRow('✅', 'AI-slagplan'),
                ],
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/premium'),
                  child: Text(
                    _currentPlan == 'elite'
                      ? 'Se alle fordeler →'
                      : 'Oppgrader til Elite →',
                    style: TextStyle(
                      color: _currentPlan == 'elite'
                        ? const Color(0xFFD4AF37)
                        : const Color(0xFF34D399),
                      fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ]),
            ),

          // ── VELKOMST / TRIAL ─────────────────────────────────────
          if (!isPaid && !_trialExpired)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C3860), Color(0xFF0F2340)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.4)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('🎉 Takk for at du lastet ned!',
                  style: TextStyle(color: Color(0xFF60A5FA), fontSize: 13,
                    fontWeight: FontWeight.w800, letterSpacing: 0.05)),
                const SizedBox(height: 8),
                const Text('Prøv Premium gratis i 7 dager',
                  style: TextStyle(color: Color(0xFFF8F6F0), fontSize: 20,
                    fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text(
                  '5 favorittbutikker, personlige varsler og AI-rådgiver — helt gratis i en uke.',
                  style: TextStyle(color: Color(0xFFC8D8E8), fontSize: 13, height: 1.5)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF60A5FA),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: _startTrial,
                    child: const Text('✨ Start gratis prøveperiode',
                      style: TextStyle(color: Color(0xFF0F2340), fontSize: 15,
                        fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Ingen betaling. Ingen kortinfo. Bare prøv!',
                  style: TextStyle(color: Color(0xFF8BA5C0), fontSize: 11),
                  textAlign: TextAlign.center),
              ]),
            ),

          // ── AKTIV TRIAL ──────────────────────────────────────────
          if (_trialActive)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C3860),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF34D399).withOpacity(0.4)),
              ),
              child: const Row(children: [
                Text('✅', style: TextStyle(fontSize: 22)),
                SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Premium aktiv — prøveperiode',
                    style: TextStyle(color: Color(0xFF34D399), fontSize: 14,
                      fontWeight: FontWeight.w800)),
                  Text('Du har 7 dager gratis Premium-tilgang.',
                    style: TextStyle(color: Color(0xFFC8D8E8), fontSize: 12)),
                ])),
              ]),
            ),

          // ── UTLØPT TRIAL ─────────────────────────────────────────
          if (_trialExpired && !isPaid)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C3860),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.4)),
              ),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('⏰ Prøveperioden er over',
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 14,
                    fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Oppgrader til Premium (49 kr/mnd) for å beholde tilgangen.',
                  style: TextStyle(color: Color(0xFFC8D8E8), fontSize: 12, height: 1.4)),
              ]),
            ),

          // ── ELITE KODE ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF152B4A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF2E5080)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🎟️ Har du en kode?',
                style: TextStyle(color: Color(0xFFF8F6F0), fontSize: 14,
                  fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Kom med tilbakemelding og få Elite til Premium-pris!',
                style: TextStyle(color: Color(0xFFC8D8E8), fontSize: 12, height: 1.4)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Skriv inn kode...',
                      errorText: _codeError ? 'Ugyldig kode' : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: _redeemCode,
                  child: const Text('Løs inn',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                ),
              ]),
            ]),
          ),

          // ── AI SPRÅKBOBLE ────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C3860),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF3D6490)),
            ),
            child: Row(children: [
              const Text('🇳🇴🇬🇧', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI på norsk og engelsk',
                    style: TextStyle(color: Color(0xFFF8F6F0),
                      fontSize: 14, fontWeight: FontWeight.w700)),
                  Text('Trykk på flagget i AI-chat for å bytte språk',
                    style: TextStyle(color: Color(0xFFC8D8E8), fontSize: 12)),
                ],
              )),
              Icon(Icons.chat_bubble_outline, color: Color(0xFF60A5FA), size: 20),
            ]),
          ),

          // ── FAQ ──────────────────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Text('Ofte stilte spørsmål',
              style: TextStyle(color: Color(0xFFF8F6F0),
                fontSize: 18, fontWeight: FontWeight.w900)),
          ),
          ...[
            ('🛒 Hvordan bli Trumf-medlem? / How to join Trumf?',
              'Last ned Trumf-appen og registrer bankkortet ditt. Du får 1% bonus automatisk på KIWI, MENY, SPAR og Joker.\n\nDownload the Trumf app and register your bank card. You earn 1% bonus automatically at NorgesGruppen stores.'),
            ('✈️ Hvordan bli SAS EuroBonus-medlem? / How to join SAS EuroBonus?',
              'Gå til sas.no og opprett en gratis EuroBonus-konto. Du får et unikt EuroBonus-nummer som du bruker til å samle poeng på fly, hotell og netthandel.\n\nGo to sas.com and create a free EuroBonus account. You get a unique member number to collect points on flights, hotels and online shopping.'),
            ('🔔 Hvordan fungerer varsler? / How do alerts work?',
              'Gå til Varsler-siden og velg favorittbutikkene dine. Du får push-varsel når de har ekstra bonus.\n\nPremium: 5 favoritter. Elite: 10 favoritter og VIP-varsler.\n\nGo to the Alerts page and select your favourite stores. You get a push notification when they have extra bonus.'),
            ('💳 Hvordan betale? / How to pay?',
              'Trykk på "Mitt abonnement" for å se abonnementsvalg. Betaling skjer via Apple In-App Purchase eller Stripe på bonusvarsel.no.\n\nTap "My subscription" to see subscription options. Payment is via Apple In-App Purchase or Stripe at bonusvarsel.no.'),
            ('🏆 Hva er forskjellen på Premium og Elite? / Premium vs Elite?',
              'Premium (49 kr/mnd): 5 favoritter, AI-rådgiver, personlige varsler.\nElite (89 kr/mnd): 10 favoritter, SkyTeam-bonus, VIP-varsler, concierge-support.\n\nPremium (NOK 49/month): 5 favourites, AI advisor, personal alerts.\nElite (NOK 89/month): 10 favourites, SkyTeam bonus, VIP alerts, concierge support.'),
            ('❓ Trenger jeg hjelp? / Need help?',
              'Kontakt oss på support@bonusvarsel.no — vi svarer så fort vi kan!\n\nContact us at support@bonusvarsel.no — we reply as soon as possible!'),
          ].map((faq) => _FaqItem(question: faq.$1, answer: faq.$2)).toList(),

          const SizedBox(height: 16),

          // ── APP INFO ─────────────────────────────────────────────
          Text('Bonusvarsel',
            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () {
              setState(() => _versionTaps++);
              if (_versionTaps >= 7) {
                setState(() => _versionTaps = 0);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const BonusvarselDevHubPage()));
              }
            },
            child: Text('Versjon: 1.0.8', style: t.bodyMedium),
          ),
          const SizedBox(height: 16),

          // ── INNLOGGING ───────────────────────────────────────────
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user != null && user.email != null) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF152B4A),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF3D6490)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.account_circle, color: Color(0xFF60A5FA), size: 24),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Innlogget / Signed in',
                            style: TextStyle(color: Color(0xFFF8F6F0),
                              fontSize: 13, fontWeight: FontWeight.w700)),
                          Text(user.email!,
                            style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 12)),
                        ],
                      )),
                    ]),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, size: 16),
                        label: const Text('Logg ut / Sign out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF87171),
                          side: const BorderSide(color: Color(0xFFF87171)),
                        ),
                        onPressed: () async {
                          await AuthService.instance.signOut();
                        },
                      ),
                    ),
                  ]),
                );
              }
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF152B4A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF3D6490)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Logg inn for å aktivere Premium/Elite',
                    style: TextStyle(color: Color(0xFFF8F6F0),
                      fontSize: 14, fontWeight: FontWeight.w700)),
                  const Text('Sign in to activate Premium/Elite',
                    style: TextStyle(color: Color(0xFF8BA5C0), fontSize: 12)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.apple, size: 18),
                      label: const Text('Fortsett med Apple / Continue with Apple'),
                      style: FilledButton.styleFrom(backgroundColor: Colors.black),
                      onPressed: () async {
                        try {
                          await AuthService.instance.signInWithApple();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Feil: $e')));
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: const Text('Logg inn med e-post / Sign in with email'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF60A5FA),
                        side: const BorderSide(color: Color(0xFF60A5FA)),
                      ),
                      onPressed: () => _showEmailLogin(context),
                    ),
                  ),
                ]),
              );
            },
          ),

          // ── WEB-SEKSJON ──────────────────────────────────────────
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://bonusvarsel.no'),
              mode: LaunchMode.externalApplication),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1C3860), Color(0xFF0F2340)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF60A5FA).withOpacity(0.4)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Text('🌐', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text('bonusvarsel.no',
                    style: TextStyle(color: Color(0xFF60A5FA),
                      fontSize: 15, fontWeight: FontWeight.w900)),
                  Spacer(),
                  Icon(Icons.open_in_new, color: Color(0xFF60A5FA), size: 16),
                ]),
                const SizedBox(height: 8),
                const Text(
                  'Kjøp Premium eller Elite direkte på nettsiden — logg deretter inn i appen med samme e-post for å aktivere tilgangen.',
                  style: TextStyle(color: Color(0xFFC8D8E8), fontSize: 13, height: 1.5)),
                const SizedBox(height: 6),
                const Text(
                  'Buy Premium or Elite on our website — then log in to the app with the same email to activate.',
                  style: TextStyle(color: Color(0xFF8BA5C0), fontSize: 11, height: 1.4)),
                const SizedBox(height: 10),
                Row(children: [
                  WebChip('🔔 Varsler'),
                  SizedBox(width: 6),
                  WebChip('✈️ SAS bonus'),
                  SizedBox(width: 6),
                  WebChip('🛒 Trumf'),
                ]),
              ]),
            ),
          ),

          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Support', style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('E-post: support@bonusvarsel.no'),
              const SizedBox(height: 6),
              const Text('Vi svarer så fort vi kan.'),
            ]),
          )),
          const SizedBox(height: 12),

          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Personvern', style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('bonusvarsel.no/personvern'),
            ]),
          )),
          const SizedBox(height: 12),

          Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Vilkår', style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('bonusvarsel.no/vilkar'),
            ]),
          )),
          const SizedBox(height: 12),

          // ── SE ONBOARDING PÅ NYTT ────────────────────────────────
          GestureDetector(
            onTap: _resetOnboarding,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF152B4A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF3D6490)),
              ),
              child: const Row(children: [
                Text('🔄', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Se velkomsten på nytt',
                      style: TextStyle(color: Color(0xFFF8F6F0),
                        fontSize: 14, fontWeight: FontWeight.w700)),
                    Text('Start onboarding fra begynnelsen igjen',
                      style: TextStyle(color: Color(0xFF8BA5C0), fontSize: 12)),
                  ],
                )),
                Icon(Icons.chevron_right, color: Color(0xFF60A5FA), size: 20),
              ]),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}


class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _open = !_open),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF152B4A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2E5080)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(child: Text(widget.question,
                style: const TextStyle(color: Color(0xFFF8F6F0),
                  fontSize: 13, fontWeight: FontWeight.w700))),
              Icon(_open ? Icons.expand_less : Icons.expand_more,
                color: const Color(0xFF60A5FA), size: 20),
            ]),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(widget.answer,
                style: const TextStyle(color: Color(0xFFC8D8E8),
                  fontSize: 13, height: 1.6)),
            ),
        ]),
      ),
    );
  }
}

class WebChip extends StatelessWidget {
  final String label;
  const WebChip(this.label, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF243F6E),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: const Color(0xFF3D6490)),
    ),
    child: Text(label,
      style: const TextStyle(color: Color(0xFFC8D8E8),
        fontSize: 11, fontWeight: FontWeight.w600)),
  );
}
