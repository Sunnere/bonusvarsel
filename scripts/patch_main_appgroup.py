import sys

path = sys.argv[1]
src = open(path, encoding='utf-8').read()

import_anchor = "import 'package:bonusvarsel/services/paywall_trigger_service.dart';\n"
if src.count(import_anchor) != 1:
    print(f"ABORT (import): fant ankeret {src.count(import_anchor)} ganger, forventet 1.")
    sys.exit(1)
src = src.replace(import_anchor, import_anchor + "import 'package:home_widget/home_widget.dart';\n", 1)

main_anchor = """  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
"""
if src.count(main_anchor) != 1:
    print(f"ABORT (main): fant ankeret {src.count(main_anchor)} ganger, forventet 1.")
    sys.exit(1)
main_addition = """  WidgetsFlutterBinding.ensureInitialized();
  await HomeWidget.setAppGroupId('group.com.royrotvold.bonusvarsel');
  await Firebase.initializeApp();
"""
src = src.replace(main_anchor, main_addition, 1)

open(path, 'w', encoding='utf-8').write(src)
print("OK: HomeWidget.setAppGroupId lagt til i main.dart")
