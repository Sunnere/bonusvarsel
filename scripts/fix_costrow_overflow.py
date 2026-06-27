#!/usr/bin/env python3
path = '/Users/sunnerehelse/bonusvarsel/lib/pages/travel_page.dart'
with open(path, 'r') as f:
    content = f.read()

old = """  Widget _costRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(
          color: bold ? _textSoft : _textMuted,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          fontSize: bold ? 14 : 13)),
        Text(value, style: TextStyle(
          color: color ?? (bold ? _text : _textSoft),
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          fontSize: bold ? 14 : 13)),
      ]),
    );
  }"""

new = """  Widget _costRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Flexible(child: Text(label, style: TextStyle(
          color: bold ? _textSoft : _textMuted,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          fontSize: bold ? 14 : 13))),
        const SizedBox(width: 8),
        Text(value, style: TextStyle(
          color: color ?? (bold ? _text : _textSoft),
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
          fontSize: bold ? 14 : 13)),
      ]),
    );
  }"""

if old in content:
    content = content.replace(old, new)
    print("✅ _costRow fikset")
else:
    print("❌ Fant ikke _costRow")

with open(path, 'w') as f:
    f.write(content)
