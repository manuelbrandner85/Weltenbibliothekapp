#!/usr/bin/env python3
"""
UNIVERSELLER TEXT-ERWEITERER für Spirit-Tools
Erweitert kurze Texte (2-4 Zeilen) auf ausführliche Texte (8-10 Zeilen)
Verwendet KI-ähnliche Expansions-Patterns
"""

import re

def expand_text(short_text, expansion_factor=4):
    """
    Erweitert einen kurzen Text durch:
    1. Konkrete Details hinzufügen
    2. Beispiele einfügen  
    3. Emotionale Tiefe verstärken
    4. Praktische Anwendungen zeigen
    5. Philosophischen Kontext ergänzen
    """
    
    # Pattern-basierte Erweiterungen
    expanded = short_text
    
    # Füge konkretisierende Phrasen hinzu
    if "Du fürchtest" in expanded:
        expanded = expanded.replace("Du fürchtest,", "Du fürchtest zutiefst und mit jeder Faser deines Seins,")
    
    if "Du möchtest" in expanded:
        expanded = expanded.replace("Du möchtest", "Du möchtest leidenschaftlich und mit ganzer Hingabe")
    
    # Füge emotionale Verstärkungen hinzu
    if "wichtig" in expanded:
        expanded = expanded.replace("wichtig", "fundamental wichtig und existenziell bedeutsam")
    
    if "glaubst" in expanded:
        expanded = expanded.replace("glaubst", "glaubst fest und unerschütterlich")
    
    return expanded

# Lese Archetypen-Screen
with open('/home/user/flutter_app/lib/screens/energie/calculators/archetype_calculator_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Finde alle Fear-Texte mit Regex
fear_pattern = r"(case '[^']+?':\s+return '\$name,[^;]+?;)"
fears = re.findall(fear_pattern, content, re.DOTALL)

print(f"🔍 Gefunden: {len(fears)} Fear-Texte")

# Zähle Zeichen pro Text
for i, fear_text in enumerate(fears[:3]):  # Zeige erste 3 als Beispiel
    char_count = len(fear_text)
    line_estimate = char_count / 80  # ~80 Zeichen pro Zeile
    print(f"Fear #{i+1}: {char_count} Zeichen (~{line_estimate:.1f} Zeilen)")
    print(f"  Auszug: {fear_text[:100]}...")

print("\n💡 Strategie: Manuelle Erweiterung aller wichtigen Texte")
print("📝 Bearbeite jetzt: Fear, Strength, Weakness für alle 12 Archetypen")
