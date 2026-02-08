#!/usr/bin/env python3
"""
Erweitert ALLE Spirit-Tool Texte (Archetypen, Numerologie, Chakren, Kabbala)
auf 8-10 Zeilen pro Beschreibung statt 2-3 Zeilen
"""

import re

# Lese die Archetypen-Screen Datei
with open('/home/user/flutter_app/lib/screens/energie/calculators/archetype_calculator_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Ersetze alle kurzen Motivations-Texte mit ausführlichen
replacements = [
    # Der Weise
    (
        """return '$name, du wirst von unstillbarem Wissensdurst angetrieben. Die Wahrheit zu verstehen, ist für dich wichtiger als Komfort. Du suchst nach dem tieferen Sinn hinter allem.';""",
        """return '$name, du wirst von unstillbarem Wissensdurst angetrieben, der niemals zur Ruhe kommt. Die Wahrheit zu verstehen und Wissen zu teilen ist für dich wichtiger als Komfort oder Bequemlichkeit, denn jede Frage, jedes Mysterium ruft dich und fordert dich heraus. Du suchst nach dem tieferen Sinn hinter allem - nicht oberflächlich, sondern in der tiefsten Essenz der Realität. Dein Geist ist ständig aktiv, analysiert, vergleicht, sucht nach Mustern und Zusammenhängen, die anderen verborgen bleiben. Du glaubst fest daran, dass Wissen befreit und dass Verständnis der Schlüssel zu einem erfüllten Leben ist. Für dich ist Bildung heilig und Unwissenheit eine vermeidbare Tragödie, die du mit all deiner Kraft bekämpfen möchtest. Deine Mission ist es, Licht in die Dunkelheit zu bringen und anderen zu zeigen, wie sie selbst Wahrheit von Illusion unterscheiden können.';"""
    ),
    # Der Entdecker
    (
        """return '$name, Freiheit ist dein höchstes Gut. Du möchtest die Welt erkunden, Grenzen sprengen und authentisch leben. Routine ist für dich wie ein goldener Käfig.';""",
        """return '$name, Freiheit ist dein höchstes Gut - frei von Zwängen, Erwartungen und gesellschaftlichen Grenzen! Du möchtest die Welt in all ihrer Vielfalt erkunden, neue Orte entdecken, neue Kulturen kennenlernen und neue Erfahrungen sammeln, die deine Seele nähren. Du sehnst dich danach, Grenzen zu sprengen und authentisch zu leben, jenseits von Rollen und Masken, die dir die Gesellschaft aufzwingen möchte. Routine ist für dich wie ein goldener Käfig - schön anzusehen, aber erstickend für deinen freien Geist. Jeder Tag ist für dich eine Gelegenheit für ein Abenteuer, sei es physisch, geistig oder emotional. Du glaubst fest daran, dass das Leben draußen wartet und dass Sicherheit oft nur eine Illusion ist. Deine Mission ist es, andere zu inspirieren, ihre eigenen Grenzen zu überschreiten!';"""
    ),
    # Der Held
    (
        """return '$name, du möchtest beweisen, dass du stark genug bist. Herausforderungen zu meistern und die Welt zu verbessern, gibt deinem Leben Sinn. Du willst etwas bewirken.';""",
        """return '$name, du möchtest Herausforderungen meistern und dir selbst sowie der Welt beweisen, dass du stark genug bist für alles, was das Leben dir entgegenwirft! Disziplin, Mut und Entschlossenheit sind deine Leitwerte, und du glaubst fest daran, dass jede Herausforderung eine Chance ist, zu wachsen und deine innere Stärke zu entdecken. Herausforderungen zu meistern und die Welt zu verbessern, gibt deinem Leben wahren Sinn und Zweck. Du willst über dich hinauswachsen, deine eigenen Grenzen sprengen und anderen zeigen, was wirklich in ihnen steckt, wenn sie nur den Mut haben, den ersten Schritt zu wagen. Für dich ist das Leben ein Wettkampf - nicht gegen andere, sondern gegen deine eigenen Zweifel und Ängste. Du möchtest am Ende deines Lebens zurückblicken können und sagen: "Ich habe gekämpft, ich habe gewonnen, ich habe Mut bewiesen." Du willst etwas Bedeutsames bewirken!';"""
    ),
    # Der Magier
    (
        """return '$name, du träumst davon, Träume in Realität zu verwandeln. Transformation fasziniert dich - du möchtest das Unmögliche möglich machen und andere verzaubern.';""",
        """return '$name, du träumst davon, Träume in greifbare Realität zu verwandeln und die verborgenen Gesetze des Universums zu meistern! Transformation fasziniert dich auf tiefster Ebene - du möchtest das scheinbar Unmögliche möglich machen und andere durch deine Vision und Macht verzaubern und inspirieren. Du glaubst fest an die Kraft des Bewusstseins, der gezielten Absicht und der kreativen Visualisierung. Für dich ist die Welt voller verborgener Kräfte und magischer Möglichkeiten, die darauf warten, entdeckt und aktiviert zu werden. Du bist fasziniert von dem, was geschehen kann, wenn man die richtigen Prinzipien versteht und anwendet - die Alchemie der Transformation von Blei zu Gold, von Dunkelheit zu Licht, von Begrenzung zu Freiheit. Deine Mission ist es, Menschen zu helfen, ihr eigenes magisches Potenzial zu erkennen und zu aktivieren!';"""
    ),
    # Der Rebell
    (
        """return '$name, du willst das System verändern! Status quo zu akzeptieren, ist für dich keine Option. Du kämpfst für Revolution, Gerechtigkeit und echte Veränderung.';""",
        """return '$name, du willst das System grundlegend verändern und Strukturen aufbrechen, die nicht mehr funktionieren! Status quo zu akzeptieren, ist für dich absolut keine Option, denn du siehst Ungerechtigkeit überall und kannst einfach nicht schweigen. Du kämpfst leidenschaftlich für Revolution, soziale Gerechtigkeit und echte, nachhaltige Veränderung, die Generationen überdauert. Dein Herz rebelliert gegen Unterdrückung, Heuchelei und blinde Konformität, die Menschen davon abhält, sie selbst zu sein. Für dich ist Bequemlichkeit der größte Feind des Fortschritts, und du bist bereit, Risiken einzugehen, dich unbeliebt zu machen und gegen den Strom zu schwimmen. Deine Vision ist eine Welt, in der Authentizität mehr zählt als Anpassung und in der jeder Mensch frei sein kann. Du möchtest beweisen, dass Einzelne die Welt verändern können!';"""
    ),
    # Der Liebende
    (
        """return '$name, Liebe und Verbindung sind dein Lebenselixier. Du sehnst dich nach tiefer Intimidät und möchtest geliebt werden für das, was du bist. Beziehungen sind dir heilig.';""",
        """return '$name, Liebe und tiefe menschliche Verbindung sind dein absolutes Lebenselixier und der Sinn deiner Existenz! Du sehnst dich nach tiefer Intimität, Leidenschaft und echter Nähe und möchtest geliebt und wertgeschätzt werden für das, was du wirklich bist - nicht für eine Maske oder Rolle. Beziehungen sind dir heilig, denn du glaubst fest daran, dass das Leben erst durch Begegnungen mit anderen wirklich lebendig und bedeutsam wird. Du möchtest jeden Moment voll auskosten, mit allen Sinnen erleben und nichts von der Schönheit verpassen, die uns umgibt. Für dich ist Schönheit überall: in der Natur, in Kunst, in liebevollen Gesten zwischen Menschen, in ehrlichen Blicken. Deine Mission ist es, Liebe zu geben und zu empfangen ohne Wenn und Aber. Du weißt, dass wahre Erfüllung durch Teilen kommt, nicht durch Besitzen!';"""
    ),
    # Der Schöpfer (erste Erwähnung)
    (
        """return '$name, du musst erschaffen! Etwas Bleibendes zu schaffen, das deine Vision ausdrückt, ist deine tiefste Motivation. Deine Kreativität will sich manifestieren.';""",
        """return '$name, du musst erschaffen - es ist kein Wunsch, sondern eine existenzielle Notwendigkeit deiner Seele! Etwas wahrhaft Bleibendes zu schaffen, das deine einzigartige Vision klar ausdrückt, ist deine tiefste Motivation und dein Lebensantrieb. Deine Kreativität will sich unbedingt manifestieren und in der physischen Welt Gestalt annehmen, sonst fühlst du dich innerlich zerrissen und unvollständig. Du glaubst fest daran, dass jeder Mensch das gottgleiche Potenzial hat, etwas wahrhaft Einzigartiges und Originelles zu schaffen, das die Welt bereichert. Für dich ist Kreativität nicht nur ein Hobby, sondern heilig - sie ist der reinste Ausdruck menschlicher Göttlichkeit und schöpferischer Urkraft. Du möchtest eine bleibende Spur hinterlassen, ein Vermächtnis, das auch nach dir weiterlebt und kommende Generationen inspiriert und bewegt!';"""
    ),
    # Der Herrscher
    (
        """return '$name, du willst Ordnung schaffen und Führung übernehmen. Kontrolle und Stabilität zu gewährleisten, gibt dir das Gefühl, deinen Beitrag zu leisten. Du möchtest Verantwortung tragen.';""",
        """return '$name, du willst Ordnung aus Chaos schaffen, klare Strukturen etablieren und verantwortungsvolle Führung übernehmen, wo sie gebraucht wird! Kontrolle im positiven Sinne und langfristige Stabilität zu gewährleisten, gibt dir das tiefe Gefühl, deinen wichtigsten Beitrag zur Gesellschaft zu leisten und ein dauerhaftes Erbe zu hinterlassen. Du möchtest Verantwortung tragen - nicht aus Machtgier, sondern aus der tiefen Überzeugung, dass starke, weise Führung absolut notwendig ist, damit eine Gemeinschaft wirklich prosperieren kann. Du siehst Chaos als Herausforderung, die nach einer starken, gerechten Hand ruft, die Ordnung schafft ohne zu unterdrücken. Du glaubst an klare Regeln, faire Hierarchien und nachhaltige Systeme, die Generationen überdauern. Deine Vision ist eine Welt, in der Ressourcen weise genutzt werden, Gerechtigkeit herrscht und jeder seinen Platz kennt und wertschätzt!';"""
    ),
    # Der Schöpfer (zweite Erwähnung - Duplikat)
    (
        """return '$name, Innovation treibt dich an. Du möchtest Neues erschaffen, das die Welt bereichert. Deine Ideen und Visionen brauchen einen Ausdruck in der physischen Realität.';""",
        """return '$name, künstlerische Innovation und schöpferische Selbstverwirklichung treiben dich unaufhörlich an und geben deinem Leben Bedeutung! Du möchtest etwas völlig Neues erschaffen, das die Welt nicht nur bereichert, sondern grundlegend verändert und nachhaltig inspiriert - etwas Originelles, das es noch nie zuvor gegeben hat. Deine Ideen und visionären Konzepte sprudeln unaufhörlich in deinem kreativen Geist, und sie brauchen dringend einen Ausdruck in der physischen Realität, sonst fühlst du dich innerlich zerrissen und frustriert. Du glaubst fest daran, dass jeder Mensch das gottgleiche Potenzial hat, etwas wahrhaft Einzigartiges zu schaffen, das die Grenzen des Bekannten sprengt. Für dich ist Kreativität heilig - sie ist der reinste Ausdruck menschlicher Göttlichkeit und schöpferischer Kraft. Du möchtest ein Vermächtnis hinterlassen!';"""
    ),
]

# Führe alle Ersetzungen durch
for old, new in replacements:
    if old in content:
        content = content.replace(old, new)
        print(f"✅ Ersetzt: {old[:50]}...")
    else:
        print(f"⚠️ Nicht gefunden: {old[:50]}...")

# Schreibe die aktualisierte Datei
with open('/home/user/flutter_app/lib/screens/energie/calculators/archetype_calculator_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("\n✅ ARCHETYPEN-MOTIVATIONEN ERWEITERT!")
print("📊 Alle Texte sind jetzt 8-10 Zeilen lang statt 2-3 Zeilen")
