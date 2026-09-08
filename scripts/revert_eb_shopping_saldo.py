import sys

path = sys.argv[1]
src = open(path, encoding='utf-8').read()

# Fjern imports
old_imports = "import '../services/api_service.dart';\nimport 'package:home_widget/home_widget.dart';\nimport '../services/user_state.dart';\n"
new_imports = "import '../services/api_service.dart';\n"
if src.count(old_imports) != 1:
    print(f"ABORT (imports): fant {src.count(old_imports)} ganger, forventet 1.")
    sys.exit(1)
src = src.replace(old_imports, new_imports, 1)

# Fjern state-felt/metoder - finn blokken mellom markørene
start_marker = "  final _euroBonusCtrl = TextEditingController();"
end_marker = "  Widget build(BuildContext context) {"
start_idx = src.find(start_marker)
end_idx = src.find(end_marker)
if start_idx == -1 or end_idx == -1 or start_idx > end_idx:
    print("ABORT: fant ikke start/slutt-markør for saldo-blokken.")
    sys.exit(1)
src = src[:start_idx] + src[end_idx:]

# Fjern fra build()
old_build = """          SliverToBoxAdapter(child: _hero()),
          SliverToBoxAdapter(child: _saldoSection()),
          SliverToBoxAdapter(child: _stepsSection()),"""
new_build = """          SliverToBoxAdapter(child: _hero()),
          SliverToBoxAdapter(child: _stepsSection()),"""
if src.count(old_build) != 1:
    print(f"ABORT (build): fant {src.count(old_build)} ganger, forventet 1.")
    sys.exit(1)
src = src.replace(old_build, new_build, 1)

open(path, 'w', encoding='utf-8').write(src)
print("OK: saldo-seksjon fjernet fra eb_shopping_page.dart")
