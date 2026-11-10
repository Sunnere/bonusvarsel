import 'package:firebase_auth/firebase_auth.dart';

/// Gjør om en Stripe Payment Link til en lenke som kobler kjøpet til innlogget bruker.
/// client_reference_id = Firebase-uid, så webhooken vet hvem som betalte selv om
/// e-posten i Stripe er en annen enn innloggingen. E-post forhåndsutfylles hvis den
/// ikke er Apples skjulte videresendingsadresse.
Uri stripeCheckoutUri(String base) {
  final u = FirebaseAuth.instance.currentUser;
  final params = <String, String>{};
  if (u != null) {
    params['client_reference_id'] = u.uid;
    final email = u.email;
    if (email != null &&
        email.isNotEmpty &&
        !email.toLowerCase().endsWith('@privaterelay.appleid.com')) {
      params['prefilled_email'] = email;
    }
  }
  final uri = Uri.parse(base);
  if (params.isEmpty) return uri;
  return uri.replace(queryParameters: {...uri.queryParameters, ...params});
}
