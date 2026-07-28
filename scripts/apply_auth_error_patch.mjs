// scripts/apply_auth_error_patch.mjs
//
// Fikser rå exception-visning ved Apple-innlogging.
// Feiler tydelig uten å endre noe hvis ankertekst ikke finnes,
// eller hvis patchen allerede er anvendt.
//
// Kjør med: node scripts/apply_auth_error_patch.mjs

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT = path.join(__dirname, '..');

const FILES = {
  auth: path.join(ROOT, 'lib', 'services', 'auth_service.dart'),
  login: path.join(ROOT, 'lib', 'pages', 'login_page.dart'),
  settings: path.join(ROOT, 'lib', 'pages', 'settings_page.dart'),
};

function replaceOnce(content, search, replace, label) {
  const count = content.split(search).length - 1;
  if (count === 0) {
    throw new Error(`FEIL: fant ikke ankertekst for "${label}". Ingen filer er endret. Sjekk at filen matcher det forventede.`);
  }
  if (count > 1) {
    throw new Error(`FEIL: fant ankertekst for "${label}" ${count} ganger (forventet 1). Avbryter for sikkerhets skyld.`);
  }
  return content.replace(search, replace);
}

const contents = {};
for (const [key, p] of Object.entries(FILES)) {
  contents[key] = fs.readFileSync(p, 'utf8');
}
const originals = { ...contents };

if (contents.auth.includes('AuthCancelledException')) {
  console.error('FEIL: auth_service.dart er allerede patchet (fant "AuthCancelledException"). Avbryter uten å endre noe.');
  process.exit(1);
}

// ── 1) auth_service.dart ─────────────────────────────────────────────────────

if (!contents.auth.includes("package:flutter/foundation.dart")) {
  contents.auth = "import 'package:flutter/foundation.dart' show debugPrint;\n" + contents.auth;
}

contents.auth = replaceOnce(
  contents.auth,
  `    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw Exception('Apple-innlogging avbrutt');
      }
      throw Exception('Apple-innlogging feilet: \${e.message}');
    } catch (e) {
      throw Exception('Apple-innlogging feilet: \$e');
    }`,
  `    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw const AuthCancelledException();
      }
      debugPrint('[AuthService] Apple-innlogging feilet (teknisk): \${e.code} \${e.message}');
      throw Exception('Innlogging med Apple feilet. Prøv igjen om litt.');
    } catch (e) {
      debugPrint('[AuthService] Apple-innlogging feilet (teknisk): \$e');
      throw Exception('Innlogging med Apple feilet. Prøv igjen om litt.');
    }`,
  'auth_service catch-blokker'
);

contents.auth = contents.auth.trimEnd() + `

/// Kastes når brukeren selv avbryter innloggingen.
/// Dette er et bevisst valg, ikke en feil - skal aldri vises som feilmelding.
class AuthCancelledException implements Exception {
  const AuthCancelledException();
}
`;

// ── 2) login_page.dart ───────────────────────────────────────────────────────

contents.login = replaceOnce(
  contents.login,
  `    } on Exception catch (e) {
      final msg = e.toString()
        .replaceAll('Exception: ', '')
        .replaceAll('Apple-innlogging avbrutt', '')
        .replaceAll('[firebase_auth/network-request-failed]', 'Nettverksfeil. Sjekk internettforbindelsen.')
        .replaceAll('[firebase_auth/too-many-requests]', 'For mange forsøk. Vent litt og prøv igjen.');
      if (msg.isNotEmpty) setState(() => _error = msg);
    } finally {`,
  `    } on AuthCancelledException {
      // Brukeren avbrøt selv - ingen feilmelding.
    } on Exception catch (e) {
      final raw = e.toString().replaceAll('Exception: ', '');
      final msg = raw.contains('network-request-failed')
          ? 'Nettverksfeil. Sjekk internettforbindelsen.'
          : raw.contains('too-many-requests')
              ? 'For mange forsøk. Vent litt og prøv igjen.'
              : raw;
      setState(() => _error = msg);
    } finally {`,
  'login_page Apple catch-blokk'
);

// ── 3) settings_page.dart ────────────────────────────────────────────────────

contents.settings = replaceOnce(
  contents.settings,
  `                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                          }
                        }`,
  `                        } on AuthCancelledException {
                          // Brukeren avbrøt selv - ingen feilmelding.
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                          }
                        }`,
  'settings_page Apple catch-blokk'
);

// ── Skriv alt, med backup ────────────────────────────────────────────────────

const stamp = Date.now();
for (const [key, p] of Object.entries(FILES)) {
  const backupPath = `${p}.bak_auth_error_patch.${stamp}`;
  fs.writeFileSync(backupPath, originals[key], 'utf8');
  fs.writeFileSync(p, contents[key], 'utf8');
  console.log(`OK: ${path.relative(ROOT, p)} oppdatert (backup: ${path.basename(backupPath)})`);
}

console.log('');
console.log('Endringer:');
console.log('  1. auth_service.dart: AuthCancelledException, menneskelige meldinger, debugPrint av teknisk detalj');
console.log('  2. login_page.dart: avbrudd fanges stille, rene meldinger for reelle feil');
console.log('  3. settings_page.dart: avbrudd fanges stille i snackbar');
console.log('');
console.log('Kjør nå: flutter analyze');
