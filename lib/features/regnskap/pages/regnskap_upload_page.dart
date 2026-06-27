// ============================================================
// Bonusvarsel Regnskap — Upload Page
// lib/features/regnskap/pages/regnskap_upload_page.dart
// ============================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegnskapUploadPage extends StatefulWidget {
  const RegnskapUploadPage({super.key});
  @override
  State<RegnskapUploadPage> createState() => _RegnskapUploadPageState();
}

class _RegnskapUploadPageState extends State<RegnskapUploadPage> {
  static const String _baseUrl = 'http://192.168.1.144:8787';

  File?   _selectedFile;
  String? _fileName;
  bool    _uploading = false;
  double  _progress = 0;
  String  _progressLabel = '';
  Map<String, dynamic>? _result;

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _fileName     = result.files.single.name;
        _result       = null;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: source, imageQuality: 85);
    if (img != null) {
      setState(() {
        _selectedFile = File(img.path);
        _fileName     = img.name;
        _result       = null;
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;
    setState(() { _uploading = true; _progress = 0; _result = null; });

    final steps = [
      (0.2, 'Leser fil…'),
      (0.45, 'Parser transaksjoner…'),
      (0.7, 'Analyserer kategorier…'),
      (0.88, 'Finner bonusmuligheter…'),
      (0.95, 'Lagrer…'),
    ];
    int step = 0;
    final ticker = Stream.periodic(const Duration(milliseconds: 600)).listen((_) {
      if (step < steps.length) {
        setState(() {
          _progress      = steps[step].$1;
          _progressLabel = steps[step].$2;
          step++;
        });
      }
    });

    try {
      final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/upload/statement'));
      req.files.add(await http.MultipartFile.fromPath('file', _selectedFile!.path));
      final streamed = await req.send();
      final body     = await streamed.stream.bytesToString();
      final data     = jsonDecode(body) as Map<String, dynamic>;

      ticker.cancel();
      setState(() {
        _progress      = 1.0;
        _progressLabel = 'Ferdig!';
        _uploading     = false;
        _result        = data;
      });
    } catch (e) {
      ticker.cancel();
      setState(() {
        _uploading = false;
        _result    = {'ok': false, 'error': e.toString()};
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF070D26),
    appBar: AppBar(
      backgroundColor: const Color(0xFF070D26),
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFA3AED0), size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Last opp kontoutskrift',
        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last opp en PDF-kontoutskrift fra banken din. AI-en analyserer utgiftene og finner bonusmuligheter automatisk.',
            style: TextStyle(color: Color(0xFFA3AED0), fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 20),

          // Drop-sone
          GestureDetector(
            onTap: _pickPdf,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36),
              decoration: BoxDecoration(
                color: const Color(0xFF868CFF).withOpacity(0.04),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF868CFF).withOpacity(0.35),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Text('📄', style: TextStyle(fontSize: 44)),
                  const SizedBox(height: 12),
                  const Text('Trykk for å velge PDF',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  const Text('PDF-kontoutskrift fra banken din',
                    style: TextStyle(color: Color(0xFFA3AED0), fontSize: 12)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _formatTag('PDF'),
                      const SizedBox(width: 8),
                      _formatTag('Maks 20 MB'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Kamera / galleri
          Row(children: [
            Expanded(child: _actionBtn('📸 Ta bilde', const Color(0xFF01B574),
              () => _pickImage(ImageSource.camera))),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('🖼️ Velg bilde', const Color(0xFF868CFF),
              () => _pickImage(ImageSource.gallery))),
          ]),
          const SizedBox(height: 16),

          // Valgt fil
          if (_selectedFile != null) _buildFilePreview(),

          // Progress
          if (_uploading) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.white.withOpacity(0.07),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF868CFF)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(_progressLabel,
              style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12),
              textAlign: TextAlign.center),
          ],

          const SizedBox(height: 16),

          // Upload-knapp
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedFile != null && !_uploading) ? _upload : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4318FF),
                disabledBackgroundColor: const Color(0xFF4318FF).withOpacity(0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                _uploading ? 'Analyserer…' : 'Analyser kontoutskrift',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Resultat
          if (_result != null) ...[
            const SizedBox(height: 16),
            _buildResult(),
          ],

          const SizedBox(height: 24),
          _buildSupportedBanks(),
        ],
      ),
    ),
  );

  Widget _formatTag(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF868CFF).withOpacity(0.12),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFF868CFF).withOpacity(0.25)),
    ),
    child: Text(text, style: const TextStyle(color: Color(0xFF868CFF), fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _actionBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Center(child: Text(label,
        style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500))),
    ),
  );

  Widget _buildFilePreview() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(
      children: [
        const Text('📄', style: TextStyle(fontSize: 26)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fileName ?? '',
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              Text('${(_selectedFile!.lengthSync() / 1024 / 1024).toStringAsFixed(1)} MB',
                style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 11)),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => setState(() { _selectedFile = null; _fileName = null; }),
          child: const Icon(Icons.close, color: Color(0xFFA3AED0), size: 18),
        ),
      ],
    ),
  );

  Widget _buildResult() {
    final ok = _result!['ok'] == true;
    if (!ok) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEE5D50).withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEE5D50).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Kunne ikke analysere filen',
              style: TextStyle(color: Color(0xFFEE5D50), fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_result!['error'] ?? '', style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12)),
          ],
        ),
      );
    }

    final stats    = _result!['stats'] as Map<String, dynamic>? ?? {};
    final insights = (_result!['breakdown'] as List? ?? []);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111C44),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅', style: TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(_result!['message'] ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _resultRow('Transaksjoner importert', '${_result!['saved'] ?? 0}', const Color(0xFF01B574)),
          _resultRow('Totalt beløp', '${stats['total_amount'] ?? 0} kr', Colors.white),
          _resultRow('Bonus-muligheter', '${stats['bonus_possible_count'] ?? 0} transaksjoner', const Color(0xFFFFB547)),
          if (insights.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('AI-INNSIKTER GENERERT',
              style: TextStyle(color: Color(0xFFA3AED0), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.6)),
            const SizedBox(height: 8),
            ...insights.map((i) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF868CFF).withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${i['type'] == 'bonus_opportunity' ? '⭐' : i['type'] == 'missing_receipt' ? '🧾' : '💡'} ${i['title']}',
                style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 12)),
            )),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4318FF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Se innsikter på dashbordet →',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultRow(String key, String value, Color valueColor) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 13)),
        Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildSupportedBanks() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STØTTEDE BANKER',
          style: TextStyle(color: Color(0xFFA3AED0), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.7)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: ['DNB', 'Sbanken', 'Nordea', 'SpareBank 1',
            'Handelsbanken', 'Danske Bank', 'Komplett Bank', 'Revolut', 'Andre banker']
            .map((b) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2559),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(b, style: const TextStyle(color: Color(0xFFA3AED0), fontSize: 11)),
            )).toList(),
        ),
      ],
    ),
  );
}
