#!/usr/bin/env bash
set -euo pipefail

API_SERVER="api/server.js"
API_SERVICE="lib/services/api_service.dart"
PANEL="lib/widgets/dev_pipeline_panel.dart"

[[ -f "$API_SERVER" ]] || { echo "❌ Fant ikke $API_SERVER"; exit 1; }
[[ -f "$API_SERVICE" ]] || { echo "❌ Fant ikke $API_SERVICE"; exit 1; }
[[ -f "$PANEL" ]] || { echo "❌ Fant ikke $PANEL"; exit 1; }

cp "$API_SERVER" "$API_SERVER.bak_804.$(date +%s)"
cp "$API_SERVICE" "$API_SERVICE.bak_804.$(date +%s)"
cp "$PANEL" "$PANEL.bak_804.$(date +%s)"
echo "✅ Backup laget"

python3 <<'PY'
from pathlib import Path
import re

# ----------------------------
# api/server.js
# ----------------------------
p = Path("api/server.js")
text = p.read_text()

old = 'const autoPipelineThreshold = Number(process.env.AUTO_PIPELINE_THRESHOLD || 2);\n'
new = 'let currentAutoPipelineThreshold = Number(process.env.AUTO_PIPELINE_THRESHOLD || 2);\n'
if old in text:
    text = text.replace(old, new, 1)

text = text.replace("autoPipelineThreshold", "currentAutoPipelineThreshold")

route_block = r'''
app.get("/v1/dev/auto-pipeline-threshold", (_, res) => {
  res.json({
    ok: true,
    threshold: currentAutoPipelineThreshold,
  });
});

app.post("/v1/dev/auto-pipeline-threshold", express.json(), (req, res) => {
  const next = Number(req.body?.threshold);

  if (!Number.isFinite(next) || next <= 0) {
    return res.status(400).json({
      ok: false,
      error: "threshold must be a positive number",
    });
  }

  currentAutoPipelineThreshold = next;

  state.pipeline = {
    ...state.pipeline,
    threshold: currentAutoPipelineThreshold,
    lastUpdated: nowIso(),
    summary: `${state.pipeline?.summary ?? "threshold updated"} • threshold=${currentAutoPipelineThreshold}`,
  };

  return res.json({
    ok: true,
    threshold: currentAutoPipelineThreshold,
  });
});

'''
if '/v1/dev/auto-pipeline-threshold' not in text:
    marker = 'app.listen(port, () => {'
    if marker not in text:
        raise SystemExit("❌ Fant ikke app.listen-markør i api/server.js")
    text = text.replace(marker, route_block + "\n" + marker, 1)

p.write_text(text)

# ----------------------------
# lib/services/api_service.dart
# ----------------------------
p = Path("lib/services/api_service.dart")
text = p.read_text()

if "getAutoPipelineThreshold()" not in text:
    insert = '''
  static Future<Map<String, dynamic>> getAutoPipelineThreshold() async {
    final decoded = await _getMap('/v1/dev/auto-pipeline-threshold');
    return decoded;
  }

  static Future<Map<String, dynamic>> setAutoPipelineThreshold(num threshold) async {
    final res = await http.post(
      _uri('/v1/dev/auto-pipeline-threshold'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'threshold': threshold}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'POST /v1/dev/auto-pipeline-threshold failed: ${res.statusCode} ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('POST /v1/dev/auto-pipeline-threshold expected JSON object');
    }
    return decoded;
  }

'''
    marker = "\n}\n"
    idx = text.rfind(marker)
    if idx == -1:
        raise SystemExit("❌ Fant ikke slutten av ApiService-klassen")
    text = text[:idx] + insert + text[idx:]

p.write_text(text)

# ----------------------------
# lib/widgets/dev_pipeline_panel.dart
# ----------------------------
p = Path("lib/widgets/dev_pipeline_panel.dart")
text = p.read_text()

# state fields
anchor = "  Timer? _autoRefreshTimer;\n"
if "TextEditingController _thresholdController" not in text:
    if anchor not in text:
        raise SystemExit("❌ Fant ikke state-anchor i dev_pipeline_panel.dart")
    text = text.replace(
        anchor,
        anchor + "  final TextEditingController _thresholdController = TextEditingController();\n  bool _savingThreshold = false;\n",
        1,
    )

# dispose
old_dispose = """  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
"""
new_dispose = """  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _thresholdController.dispose();
    super.dispose();
  }
"""
if old_dispose in text:
    text = text.replace(old_dispose, new_dispose, 1)

# update controller from pipeline state
old_apply = """    _lastState = result;
  }
"""
new_apply = """    final pipeline = result['pipeline'];
    if (pipeline is Map) {
      final threshold = pipeline['threshold'];
      if (threshold != null) {
        final next = threshold.toString();
        if (_thresholdController.text != next) {
          _thresholdController.text = next;
        }
      }
    }

    _lastState = result;
  }
"""
if old_apply in text and "_thresholdController.text" not in text:
    text = text.replace(old_apply, new_apply, 1)

# save method
if "_saveThreshold()" not in text:
    marker = "  Future<void> _refreshStatus() async {\n"
    method = '''
  Future<void> _saveThreshold() async {
    final raw = _thresholdController.text.trim().replaceAll(',', '.');
    final next = num.tryParse(raw);

    if (next == null || next <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ugyldig threshold')),
        );
      }
      return;
    }

    setState(() => _savingThreshold = true);
    try {
      await ApiService.setAutoPipelineThreshold(next);
      await _refreshStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Threshold oppdatert til $next')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Threshold-feil: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _savingThreshold = false);
      }
    }
  }

'''
    if marker not in text:
        raise SystemExit("❌ Fant ikke _refreshStatus()-markør i dev_pipeline_panel.dart")
    text = text.replace(marker, method + marker, 1)

# UI block under Feed status
old_ui = """                                    Text(
                                      'Last upstream error: $lastUpstreamError',
                                      style: const TextStyle(
                                        color: _textSoft,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
"""
new_ui = """                                    Text(
                                      'Last upstream error: $lastUpstreamError',
                                      style: const TextStyle(
                                        color: _textSoft,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Text(
                                      'Threshold control',
                                      style: TextStyle(
                                        color: _text,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _thresholdController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: const InputDecoration(
                                              labelText: 'Auto threshold',
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        FilledButton(
                                          onPressed: _savingThreshold ? null : _saveThreshold,
                                          child: Text(_savingThreshold ? 'Lagrer…' : 'Save'),
                                        ),
                                      ],
                                    ),
"""
if old_ui in text and "Threshold control" not in text:
    text = text.replace(old_ui, new_ui, 1)

p.write_text(text)

print("✅ Runtime-threshold control lagt inn")
PY

node --check "$API_SERVER"
flutter analyze
echo "✅ 804 ferdig"
