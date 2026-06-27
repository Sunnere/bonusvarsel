#!/usr/bin/env python3
import re, os, subprocess

pbx = os.path.expanduser('~/bonusvarsel/ios/Runner.xcodeproj/project.pbxproj')
with open(pbx, 'r') as f:
    content = f.read()
with open(pbx + '.bak_widget', 'w') as f:
    f.write(content)

# Finn widget appex UUID
m = re.search(r'(\w{24}) /\* BonusWidgetExtension\.appex \*/', content)
if not m:
    print("❌ Fant ikke BonusWidgetExtension.appex UUID")
    exit(1)
appex_uuid = m.group(1)
print(f"✅ Widget UUID: {appex_uuid}")

# Finn Runner target UUID
m2 = re.search(r'(\w{24}) /\* Runner \*/ = \{[^}]*isa = PBXNativeTarget', content, re.DOTALL)
if not m2:
    # Prøv annen pattern
    m2 = re.search(r'name = Runner;\n\s*productName = Runner;.*?(\w{24})', content, re.DOTALL)
runner_target = None
# Finn via buildPhases
m3 = re.search(r'(\w{24}) /\* Runner \*/ = \{\s*isa = PBXNativeTarget', content)
if m3:
    runner_target = m3.group(1)
    print(f"✅ Runner target UUID: {runner_target}")
else:
    print("❌ Fant ikke Runner target UUID")
    exit(1)

# Sjekk om embed allerede finnes
if 'Embed App Extensions' in content or ('CopyFiles' in content and 'BonusWidgetExtension' in content):
    print("⚠️  Embed finnes allerede")
else:
    # Generer nye UUIDs
    import uuid
    def new_uuid():
        return uuid.uuid4().hex[:24].upper()
    
    build_file_uuid = new_uuid()
    copy_phase_uuid = new_uuid()
    
    # Legg til PBXBuildFile for widget
    build_file_section = f'\t\t{build_file_uuid} /* BonusWidgetExtension.appex in Embed App Extensions */ = {{isa = PBXBuildFile; fileRef = {appex_uuid} /* BonusWidgetExtension.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};\n'
    
    content = content.replace(
        '/* Begin PBXBuildFile section */',
        '/* Begin PBXBuildFile section */\n' + build_file_section
    )
    
    # Legg til CopyFiles phase
    copy_phase = f'''\t\t{copy_phase_uuid} /* Embed App Extensions */ = {{
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = (
\t\t\t\t{build_file_uuid} /* BonusWidgetExtension.appex in Embed App Extensions */,
\t\t\t);
\t\t\tname = "Embed App Extensions";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
'''
    
    content = content.replace(
        '/* Begin PBXCopyFilesBuildPhase section */',
        '/* Begin PBXCopyFilesBuildPhase section */\n' + copy_phase
    )
    
    # Legg til phase i Runner target buildPhases
    content = re.sub(
        r'(' + re.escape(runner_target) + r' /\* Runner \*/ = \{[^}]*buildPhases = \([^)]*)',
        r'\1\t\t\t\t' + copy_phase_uuid + ' /* Embed App Extensions */,\n',
        content,
        flags=re.DOTALL
    )
    
    # Legg til dependency
    dep_uuid = new_uuid()
    proxy_uuid = new_uuid()
    
    print(f"✅ Lagt til embed phase: {copy_phase_uuid}")

with open(pbx, 'w') as f:
    f.write(content)

print("✅ project.pbxproj oppdatert")
print("\nKjør nå:")
print("flutter run -d 00008110-001138643E60401E --dart-define=ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
