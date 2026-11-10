import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ImportedBalance {
  final String program;
  final int value;
  final String confidence;
  final String label;
  const ImportedBalance(this.program, this.value, this.confidence, this.label);
}

class BalanceImportException implements Exception {
  final String message;
  const BalanceImportException(this.message);
  @override
  String toString() => message;
}

class BalanceImportService {
  /// Velger skjermbilde fra galleriet og sender det til Claude. Returnerer null hvis bruker avbryter.
  static Future<List<ImportedBalance>?> pickAndRead() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 80,
    );
    if (picked == null) return null;
    final bytes = await File(picked.path).readAsBytes();
    final lower = picked.path.toLowerCase();
    final mediaType = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : 'image/jpeg';
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final callable = FirebaseFunctions.instance.httpsCallable(
        'importBalance',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
      );
      final res = await callable.call({
        'imageBase64': base64Encode(bytes),
        'mediaType': mediaType,
      });
      final raw = (res.data['balances'] as List?) ?? const [];
      return [
        for (final b in raw)
          ImportedBalance(
            b['program'] as String,
            (b['value'] as num).toInt(),
            (b['confidence'] as String?) ?? 'low',
            (b['label'] as String?) ?? '',
          ),
      ];
    } on FirebaseFunctionsException catch (e) {
      throw BalanceImportException(e.message ?? 'Kunne ikke lese skjermbildet.');
    } catch (_) {
      throw const BalanceImportException('Kunne ikke lese skjermbildet. Prøv igjen.');
    }
  }
}
