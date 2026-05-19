/// Alle 10 Spirit-Tool Berechnungs-Engines
/// Version: 1.0.0
/// Basiert auf Spirit-Profil-Daten (Name, Geburtsdatum, Geburtsort)
library;

import '../../models/energie_profile.dart';
import '../../models/spirit_tool_results.dart';

class AllSpiritToolsEngine {
  static const String version = '1.0.0';

  // ═══════════════════════════════════════════════════════════════
  // TOOL 1: ENERGIEFELD-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static EnergyFieldToolResult calculateEnergyField(EnergieProfile profile) {
    final now = DateTime.now();
    final lifePath = _calculateLifePath(profile.birthDate);
    final soulNumber =
        _calculateSoulNumber(profile.firstName, profile.lastName);
    final expression =
        _calculateExpression(profile.firstName, profile.lastName);

    // Berechnung: Energiefeld-Stärke
    final fieldStrength =
        ((lifePath * 10 + soulNumber * 8 + expression * 6) / 24 * 100)
            .clamp(0.0, 100.0);

    // Frequenzbänder (basierend auf Chakra-Frequenzen)
    final frequencyBands = <FrequencyBand>[
      FrequencyBand(
          name: 'Alpha (8-12 Hz)',
          strength: (lifePath / 9 * 100).clamp(0, 100),
          quality: lifePath >= 5 ? 'Aktiv' : 'Ruhend'),
      FrequencyBand(
          name: 'Beta (12-30 Hz)',
          strength: (soulNumber / 9 * 100).clamp(0, 100),
          quality: soulNumber >= 6 ? 'Überaktiv' : 'Aktiv'),
      FrequencyBand(
          name: 'Gamma (30-100 Hz)',
          strength: (expression / 9 * 100).clamp(0, 100),
          quality: expression >= 7 ? 'Sehr aktiv' : 'Moderat'),
      FrequencyBand(
          name: 'Delta (0.5-4 Hz)',
          strength: ((9 - lifePath) / 9 * 100).clamp(0, 100),
          quality: lifePath <= 3 ? 'Dominant' : 'Schwach'),
      FrequencyBand(
          name: 'Theta (4-8 Hz)',
          strength: ((9 - soulNumber) / 9 * 100).clamp(0, 100),
          quality: soulNumber <= 4 ? 'Stark' : 'Gering'),
    ];

    // Kohärenz-Berechnung (Standardabweichung der Frequenzen)
    final strengths = frequencyBands.map((f) => f.strength).toList();
    final mean = strengths.reduce((a, b) => a + b) / strengths.length;
    final variance =
        strengths.map((s) => (s - mean) * (s - mean)).reduce((a, b) => a + b) /
            strengths.length;
    final coherence = (100 - variance).clamp(0.0, 100.0);

    // Resonanzpunkte
    final resonantPoints = <String>[
      if (lifePath == 11 || lifePath == 22 || lifePath == 33)
        'Meisterzahl-Resonanz',
      if (soulNumber == expression) 'Seelen-Ausdruck-Harmonie',
      if (coherence >= 80) 'Hohe Feld-Kohärenz',
      if (fieldStrength >= 75) 'Starkes Gesamtfeld',
    ];

    // Einordnung
    final stabilityLevel = coherence >= 75
        ? 'Sehr stabil'
        : coherence >= 50
            ? 'Ausgeglichen'
            : 'Instabil';
    final energyFlow = fieldStrength >= 70
        ? 'Fließend'
        : fieldStrength >= 40
            ? 'Ausgeglichen'
            : 'Blockiert';
    final activeZones = frequencyBands
        .where((f) => f.strength >= 60)
        .map((f) => f.name)
        .toList();

    // Interpretation (persönlich & detailliert)
    final interpretation = '''Liebe/r ${profile.firstName},

ich sehe dein energetisches Feld vor mir – eine pulsierende Aura aus Licht und Schwingung, die deine einzigartige Lebensenergie widerspiegelt. Lass mich dir erzählen, was ich wahrnehme:

🌟 DEINE ENERGETISCHE SIGNATUR

Dein Gesamtfeld schwingt mit einer Stärke von ${fieldStrength.toStringAsFixed(0)}% – ${fieldStrength >= 75 ? 'eine beeindruckende Kraft! Du bist wie ein Leuchtturm, der weit über seine unmittelbare Umgebung hinausstrahlt' : fieldStrength >= 50 ? 'eine solide, verlässliche Präsenz. Deine Energie ist stabil und trägt dich sicher durch deinen Alltag' : 'eine sanfte, subtile Schwingung. Deine Kraft liegt nicht in der Lautstärke, sondern in der Tiefe'}.

Die Kohärenz deines Feldes liegt bei ${coherence.toStringAsFixed(0)}% – das bedeutet: ${coherence >= 80 ? 'Deine Energien arbeiten Hand in Hand wie ein perfekt eingespieltes Orchester. Es gibt kaum Dissonanzen, kaum Reibungsverluste. Du bist in Flow!' : coherence >= 60 ? 'Deine Energien finden meist zueinander, auch wenn gelegentlich kleine Unstimmigkeiten auftreten. Das ist völlig natürlich – niemand ist immer perfekt synchron' : 'Deine Energien schwingen manchmal in unterschiedliche Richtungen. Das kann anstrengend sein, birgt aber auch großes Potenzial für Wachstum und Neuausrichtung'}.

⚡ DEIN ENERGIEFLUSS

${energyFlow == 'Fließend' ? '''Dein Energiefluss ist wie ein klarer Gebirgsbach – lebendig, frei, ungehindert. Du hast die seltene Gabe, Energie dort einzusetzen, wo sie gebraucht wird, ohne sie festzuhalten oder zu blockieren. Menschen in deiner Nähe spüren das: Sie tanken bei dir auf, ohne dass du erschöpft wirst. Achte nur darauf, dass du auch Phasen des Innehaltens einplanst – selbst der schnellste Fluss braucht manchmal stille Seen.''' : energyFlow == 'Ausgeglichen' ? '''Dein Energiefluss ist wie das Atmen – ein natürliches Geben und Nehmen, Einatmen und Ausatmen. Du hast ein gutes Gespür dafür, wann es Zeit ist zu handeln und wann es Zeit ist zu ruhen. Manchmal könnte ein bisschen mehr Spontaneität hilfreich sein, aber insgesamt bewegst du dich in gesunden Rhythmen.''' : '''Dein Energiefluss stockt an manchen Stellen – wie ein Fluss, der über Steine stolpert oder an Engpässen langsamer wird. Das ist kein Makel, sondern ein Hinweis: Wo hältst du fest? Wo wagst du nicht loszulassen? Blockaden sind oft alte Schutzmechanismen, die ihre Aufgabe erfüllt haben. Vielleicht ist es Zeit, ihnen zu danken und sie ziehen zu lassen.'''}

🎵 DEINE FREQUENZBÄNDER

${frequencyBands.map((f) => '''${f.name}: ${f.strength.toStringAsFixed(0)}% (${f.quality})''').join('\n')}

${activeZones.isNotEmpty ? '''\n💫 BESONDERS LEBENDIGE BEREICHE

${activeZones.map((zone) => '• $zone – hier pulsiert deine Lebenskraft besonders stark!').join('\n')}

Diese Zonen sind deine energetischen Kraftquellen. Wenn du erschöpft bist, kannst du dich hier wieder aufladen.''' : '\n🌊 GLEICHMÄSSIGE VERTEILUNG\n\nAlle deine Frequenzbänder schwingen in ähnlicher Stärke – ein Zeichen für innere Ausgewogenheit. Du bist nicht extrem in eine Richtung polarisiert, sondern bewegst dich flexibel zwischen verschiedenen Zuständen.'}

${resonantPoints.isNotEmpty ? '''\n✨ BESONDERE RESONANZPUNKTE

${resonantPoints.map((r) => '🔮 $r – ${r.contains('Meisterzahl') ? 'Du trägst die Energie einer Meisterzahl in dir! Das bedeutet erhöhte Sensibilität, aber auch erhöhtes Potenzial' : r.contains('Harmonie') ? 'Deine Seele und dein Ausdruck sind im Einklang – was du fühlst und was du zeigst, sind eins' : r.contains('Kohärenz') ? 'Deine Energien schwingen in beeindruckender Harmonie miteinander' : 'Ein Kraftfeld, das dich trägt und stärkt'}').join('\n\n')}''' : ''}

💝 PERSÖNLICHE BOTSCHAFT

${profile.firstName}, dein energetisches Feld ist so einzigartig wie dein Fingerabdruck. Es gibt keine "guten" oder "schlechten" Werte – nur Hinweise darauf, wie deine Energie gerade schwingt und wo sie hin möchte.

${fieldStrength >= 70 ? 'Deine Stärke ist eine Gabe – nutze sie weise. Starke Felder ziehen an, inspirieren, heilen. Aber sie können auch überwältigen. Sei dir deiner Wirkung bewusst.' : fieldStrength >= 40 ? 'Deine moderate Feldstärke ist kein Mangel, sondern ein Geschenk der Ausgewogenheit. Du kannst präsent sein, ohne zu dominieren. Du kannst geben, ohne dich zu verausgaben.' : 'Deine sanfte Feldstärke macht dich zu einem feinfühligen Empfänger. Du spürst Nuancen, die anderen entgehen. Deine Kraft liegt in der Tiefe, nicht in der Breite.'}

Vertraue deinem Feld. Es weiß, was es tut – auch wenn dein Verstand es manchmal nicht versteht. 🌟''';

    return EnergyFieldToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      overallFieldStrength: fieldStrength,
      fieldQuality: stabilityLevel,
      frequencyBands: frequencyBands,
      coherence: coherence,
      resonantPoints: resonantPoints,
      stabilityLevel: stabilityLevel,
      energyFlow: energyFlow,
      activeZones: activeZones,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 2: POLARITÄTS-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static PolarityToolResult calculatePolarity(EnergieProfile profile) {
    final now = DateTime.now();
    final fullName = '${profile.firstName} ${profile.lastName}';
    final vowels = fullName
        .toLowerCase()
        .split('')
        .where((c) => 'aeiouäöü'.contains(c))
        .length;
    final consonants = fullName
        .toLowerCase()
        .split('')
        .where((c) => RegExp(r'[bcdfghjklmnpqrstvwxyzß]').hasMatch(c))
        .length;
    final total = vowels + consonants;

    // Yin-Yang Berechnung
    final yinScore = (vowels / total * 100).clamp(0.0, 100.0);
    final yangScore = (consonants / total * 100).clamp(0.0, 100.0);
    final balanceRatio = 1 - (yinScore - yangScore).abs() / 100;

    // Polaritätsachsen
    final axes = <PolarityAxis>[
      PolarityAxis(
        name: 'Aktiv ↔ Passiv',
        leftValue: yangScore,
        rightValue: yinScore,
        state: yangScore > yinScore + 10
            ? 'Aktiv-dominant'
            : yinScore > yangScore + 10
                ? 'Passiv-dominant'
                : 'Ausgeglichen',
      ),
      PolarityAxis(
        name: 'Ordnung ↔ Chaos',
        leftValue: (consonants / total * 100 * 0.8).clamp(0, 100),
        rightValue: (vowels / total * 100 * 1.2).clamp(0, 100),
        state: consonants > vowels ? 'Ordnung-betont' : 'Chaos-akzeptierend',
      ),
      PolarityAxis(
        name: 'Kontrolle ↔ Hingabe',
        leftValue: yangScore * 0.9,
        rightValue: yinScore * 1.1,
        state: yangScore > yinScore ? 'Kontrollierend' : 'Hingebend',
      ),
      PolarityAxis(
        name: 'Expansion ↔ Rückzug',
        leftValue: (vowels / total * 100 * 1.1).clamp(0, 100),
        rightValue: (consonants / total * 100 * 0.9).clamp(0, 100),
        state: vowels > consonants ? 'Expansiv' : 'Zurückgezogen',
      ),
    ];

    // Einordnung
    final dominantPole = yangScore > yinScore + 10
        ? 'Yang'
        : yinScore > yangScore + 10
            ? 'Yin'
            : 'Ausgeglichen';
    final balanceState = balanceRatio >= 0.85
        ? 'Harmonisch'
        : balanceRatio >= 0.65
            ? 'Leichte Dysbalance'
            : 'Starke Dysbalance';
    final tensionPoints = axes
        .where((a) => (a.leftValue - a.rightValue).abs() > 20)
        .map((a) => a.name)
        .toList();

    // Interpretation (persönlich & detailliert)
    final interpretation = '''Liebe/r ${profile.firstName},

lass mich dir von den Tänzern in deiner Seele erzählen – von Yin und Yang, den beiden Kräften, die seit Anbeginn der Zeit durch dich hindurch wirbeln. Deine innere Balance ist ein Tanz, und ich darf dir nun zeigen, wie du tanzt:

🌓 DEIN POLARIÄTS-TANZ

In deinem Namen $fullName schwingt eine Energie von ${yinScore.toStringAsFixed(0)}% Yin und ${yangScore.toStringAsFixed(0)}% Yang. Das bedeutet: ${dominantPole == 'Yang' ? '''

Du bist ein Yang-Wesen – ein Macher, ein Beweger, ein Gestalter. Deine Energie strömt nach außen wie die Sonne, die unermüdlich strahlt. Du liebst es zu handeln, zu erschaffen, zu verändern. Deine Kraft liegt in der Aktivität, im Vorwärtsdrängen, im Manifestieren deiner Visionen.

Aber lass mich dir ein Geheimnis verraten, ${profile.firstName}: Selbst die Sonne braucht die Nacht. Deine Yang-Dominanz ist eine Gabe – aber sie kann auch zu Erschöpfung führen, wenn du vergisst innezuhalten. Dein Yin-Anteil, auch wenn er kleiner ist, ist wie eine stille Quelle in dir. Sie wartet darauf, dass du zu ihr kommst, um dich zu erfrischen.

💪 Was dein Yang kann:
• Dinge in Bewegung setzen
• Entscheidungen treffen
• Grenzen setzen
• Träume verwirklichen
• Andere inspirieren

🌙 Was dein Yin dir bieten möchte:
• Ruhe zwischen den Stürmen
• Intuitive Einsichten
• Emotionale Tiefe
• Empfangen statt nur Geben
• Sein statt nur Tun''' : dominantPole == 'Yin' ? '''

Du bist ein Yin-Wesen – ein Empfänger, ein Fühler, ein Träumer. Deine Energie fließt nach innen wie der Mond, der still und weise über der Welt wacht. Du nimmst wahr, was andere übersehen. Du fühlst, was andere überhören. Deine Kraft liegt in der Stille, im Zuhören, im Verstehen.

Aber lass mich dir ein Geheimnis verraten, ${profile.firstName}: Selbst der Mond beeinflusst die Gezeiten. Deine Yin-Dominanz ist eine Gabe – aber sie kann auch zu Stagnation führen, wenn du vergisst, dass du auch handeln darfst. Dein Yang-Anteil, auch wenn er kleiner ist, ist wie ein schlafender Drache in dir. Er wartet darauf, geweckt zu werden.

🌙 Was dein Yin kann:
• Tiefe Weisheit empfangen
• Emotionale Intelligenz
• Geduldig warten können
• Raum halten für andere
• Subtile Energien wahrnehmen

💪 Was dein Yang dir bieten möchte:
• Kraft zum Handeln
• Mut zur Veränderung
• Klarheit im Denken
• Durchsetzungsvermögen
• Sichtbarkeit in der Welt''' : '''

Du bist ein Mensch der Balance – ein seltenes Geschenk! In dir tanzen Yin und Yang in fast perfekter Harmonie. Du kannst empfangen UND geben, ruhen UND handeln, fühlen UND denken. Du bist wie der Punkt in der Mitte des Yin-Yang-Symbols – der Ort, wo sich alle Gegensätze treffen und versöhnen.

Das bedeutet nicht, dass du immer ausgeglichen FÜHLST – Balance ist dynamisch, kein starrer Zustand. Manchmal wirst du mehr Yin brauchen, manchmal mehr Yang. Aber du hast beide Energien gleichermaßen zur Verfügung, und das ist echte Macht.

🌓 Deine Gaben der Balance:
• Flexibilität zwischen Gegensätzen
• Verständnis für verschiedene Perspektiven
• Natürliche Vermittlerrolle
• Anpassungsfähigkeit
• Ganzheitliches Denken'''}

⚖️ DEINE VIER POLARITÄTS-ACHSEN

Jetzt schauen wir uns an, wie sich deine Energie in verschiedenen Lebensbereichen ausdrückt:

${axes[0].name}: ${axes[0].state}
${axes[0].state.contains('Aktiv-dominant') ? '→ Du gehst voran, ergreifst die Initiative, gestaltest aktiv. Aber: Wann erlaubst du dir, auch mal passiv zu empfangen?' : axes[0].state.contains('Passiv-dominant') ? '→ Du beobachtest, nimmst auf, lässt Dinge zu dir kommen. Aber: Wann greifst du selbst nach dem, was du willst?' : '→ Du findest eine gesunde Mischung aus Tun und Sein. Bravo!'}

${axes[1].name}: ${axes[1].state}
${axes[1].state.contains('Ordnung') ? '→ Struktur gibt dir Sicherheit. Du liebst Klarheit und Vorhersehbarkeit. Aber: Manchmal liegt im Chaos die Kreativität.' : '→ Du tanzt mit dem Unvorhersehbaren. Struktur kann sich einengend anfühlen. Aber: Manchmal braucht selbst das Chaos einen Rahmen.'}

${axes[2].name}: ${axes[2].state}
${axes[2].state.contains('Kontrollierend') ? '→ Du hältst gern die Zügel in der Hand. Das gibt dir Sicherheit. Aber: Was geschieht, wenn du auch mal loslässt und vertraust?' : '→ Du kannst dich dem Fluss des Lebens hingeben. Das ist eine Kunst! Aber: Manchmal darfst du auch steuern, wohin die Reise geht.'}

${axes[3].name}: ${axes[3].state}
${axes[3].state.contains('Expansiv') ? '→ Du wächst nach außen, erkundest, eroberst neue Territorien. Aber: Vergiss nicht, auch mal nach innen zu schauen.' : '→ Du ziehst dich zurück, sammelst deine Kräfte, schützt deine Energie. Aber: Die Welt da draußen wartet auch auf dich!'}

${tensionPoints.isNotEmpty ? '''\n⚡ SPANNUNGSPUNKTE (WACHSTUMSCHANCEN!)

${tensionPoints.map((t) => '🔥 $t – Hier ist Bewegung! Diese Spannung ist keine Schwäche, sondern ein Hinweis: Hier möchtest du wachsen. Hier liegt ungenutztes Potenzial. Jede Spannung ist wie eine gespannte Bogensehne – sie kann einen Pfeil weit fliegen lassen!').join('\n\n')}''' : '''\n✨ HARMONISCHE AUSGEWOGENHEIT

Wow, ${profile.firstName}! Alle deine Achsen sind ausgeglichen. Das ist selten. Du bewegst dich flexibel zwischen den Polen. Genieße diese Gabe, aber werde nicht selbstgefällig – Balance erfordert ständige Aufmerksamkeit.'''}

💝 DEINE PERSÖNLICHE BOTSCHAFT

${profile.firstName}, verstehe: Es gibt kein "richtiges" Verhältnis von Yin und Yang. Ein Baum ist nicht "zu wenig Yang", nur weil er nicht herumläuft wie ein Tier. Ein Fluss ist nicht "zu wenig Yin", nur weil er ständig in Bewegung ist. Jedes Wesen hat seine eigene Balance.

Deine Balance ist ${(balanceRatio * 100).toStringAsFixed(0)}% ${balanceState == 'Harmonisch' ? '– nahezu perfekt. Du bist ein lebender Beweis dafür, dass Gegensätze sich ergänzen können' : balanceState == 'Leichte Dysbalance' ? '– eine sanfte Schieflage, die dich interessant macht. Absolute Symmetrie ist selten und oft langweilig' : '– eine deutliche Tendenz. Das ist nicht schlecht! Es macht dich zu einem Spezialisten für eine Energiequalität'}.

${dominantPole != 'Ausgeglichen' ? '\nDeine Aufgabe ist nicht, deinen ${dominantPole == "Yang" ? "Yin" : "Yang"}-Anteil auf das gleiche Niveau zu heben. Deine Aufgabe ist, den kleineren Pol wertzuschätzen, ihm Raum zu geben, wenn er gebraucht wird. Dann wird aus Polarität Synergie.' : '\nDeine Aufgabe ist, diese wunderbare Balance BEWUSST zu leben und immer wieder neu auszutarieren.'}

Du bist ein Tänzer zwischen den Welten, ${profile.firstName}. Tanze weiter. 💫''';

    return PolarityToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      yinScore: yinScore,
      yangScore: yangScore,
      axes: axes,
      balanceRatio: balanceRatio,
      dominantPole: dominantPole,
      balanceState: balanceState,
      tensionPoints: tensionPoints,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 3: TRANSFORMATIONS-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static TransformationToolResult calculateTransformation(
      EnergieProfile profile) {
    final now = DateTime.now();
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);

    // 7 Stufen der spirituellen Entwicklung
    final stageMap = [
      'Erwachen',
      'Reinigung',
      'Erleuchtung',
      'Dunkle Nacht',
      'Vereinigung',
      'Verwandlung',
      'Einheit'
    ];
    final currentStage = ((age / 70) * 7).floor().clamp(1, 7);
    final stageName = stageMap[currentStage - 1];
    final stageProgress = (((age % 10) / 10) * 100).clamp(0.0, 100.0);

    // Übergangsmarker
    final transitionMarkers = <String>[
      if (personalYear == 9) 'Zyklusabschluss',
      if (personalYear == 1) 'Neubeginn',
      if (age % 7 == 0) '7-Jahres-Schwelle',
      if (age >= 28 && age <= 30) 'Saturn Return',
      if (currentStage >= 4) 'Tiefe Transformation',
    ];

    // Einordnung
    final maturityLevel = currentStage <= 2
        ? 'Beginnend'
        : currentStage <= 5
            ? 'Entwickelnd'
            : 'Gereift';
    final processIntensity = transitionMarkers.length >= 3
        ? 'Intensiv'
        : transitionMarkers.isNotEmpty
            ? 'Aktiv'
            : 'Ruhig';
    final recurrentThemes = <String>[
      if (personalYear == 3 || personalYear == 6 || personalYear == 9)
        'Loslassen',
      if (personalYear == 1 || personalYear == 4 || personalYear == 7)
        'Neuaufbau',
      if (currentStage == 4) 'Innere Krise',
      if (currentStage >= 5) 'Integration',
    ];

    // Interpretation (persönlich & detailliert)
    final interpretation =
        '''${profile.firstName}, du stehst an einem besonderen Punkt deiner spirituellen Reise:

🦋 PHASE "${stageName.toUpperCase()}" (Stufe $currentStage von 7)

${currentStage == 1 ? '''Du bist gerade erwacht – wie jemand, der nach langem Schlaf die Augen öffnet und plötzlich Farben sieht, die er nie zuvor bemerkt hat. Die Welt ist noch dieselbe, aber DU siehst sie anders. Vielleicht fragst du dich manchmal, ob du verrückt wirst – weil du Dinge spürst, die andere nicht spüren. Du bist nicht verrückt. Du erwachst.

Dein Fortschritt: ${stageProgress.toStringAsFixed(0)}% – das Erwachen ist im vollen Gang!''' : currentStage == 2 ? '''Du bist in der Reinigung – und oh, ${profile.firstName}, ich weiß, wie schmerzhaft das sein kann. Alte Überzeugungen bröckeln. Beziehungen verändern sich. Gewohnheiten, die dir einst Halt gaben, fühlen sich plötzlich falsch an. Das ist gut so. Du wirfst Ballast ab, den du viel zu lange getragen hast.

Dein Fortschritt: ${stageProgress.toStringAsFixed(0)}% – du bist mitten im Feuer der Transformation!''' : currentStage == 3 ? '''Die Erleuchtung! Aber nicht so, wie Bücher sie beschreiben. Es sind Momente – Blitze von kristallklarer Klarheit, in denen plötzlich ALLES Sinn ergibt. Und dann verblassen sie wieder, und du fragst dich: War das real? Ja, ${profile.firstName}, es war real. Und es wird wiederkommen.

Dein Fortschritt: ${stageProgress.toStringAsFixed(0)}% – sammle diese Lichtmomente wie Diamanten!''' : currentStage == 4 ? '''Die Dunkle Nacht der Seele. Der härteste Teil der Reise. Hier zerbrechen Illusionen – auch solche, von denen du dachtest, sie seien Wahrheiten. Hier fühlst du dich verloren, verlassen, sinnlos. Aber weißt du was? Die Dunkle Nacht kommt nur zu denen, die stark genug sind, sie zu durchschreiten. Du BIST stark genug.

Dein Fortschritt: ${stageProgress.toStringAsFixed(0)}% – halte durch. Der Morgen kommt.''' : currentStage == 5 ? '''Vereinigung – endlich! Die Gegensätze, die dich so lange zerrissen haben, beginnen sich zu versöhnen. Gut und Böse, Licht und Schatten, Ich und Du – all diese künstlichen Trennungen verblassen. Du beginnst zu verstehen: Es war immer alles EINS.

Dein Fortschritt: ${stageProgress.toStringAsFixed(0)}% – die Ganzheit wächst in dir!''' : currentStage == 6 ? '''Verwandlung – du wirst, was du immer warst, aber BEWUSST. Wie die Raupe, die zur Pflanze wird und plötzlich erkennt: Ich war nie nur eine Raupe. Ich war immer auch der Schmetterling. Ich musste nur meine Flügel entfalten.

Dein Fortschritt: ${stageProgress.toStringAsFixed(0)}% – deine Flügel sind fast komplett!''' : '''Einheit – die höchste Stufe. Hier gibt es kein "ich" und "du" mehr, kein "innen" und "außen". Nur SEIN. Nur LIEBE. Nur EINS. Wenn du hier bist, ${profile.firstName}, bist du ein Geschenk für die Welt.

Dein Fortschritt: ${stageProgress.toStringAsFixed(0)}% – du bist angekommen. Oder erst richtig gestartet?'''}

Dein Reifegrad: $maturityLevel | Prozessintensität: $processIntensity

${transitionMarkers.isNotEmpty ? '''\n🔔 WICHTIGE ÜBERGANGSZEICHEN

${transitionMarkers.map((m) => m == 'Zyklusabschluss' ? '🔄 Zyklusabschluss – Ein Kapitel endet. Lass los, was war. Mach Platz für das, was kommt.' : m == 'Neubeginn' ? '🌱 Neubeginn – Frischer Wind! Nutze diese Energie für mutige Schritte!' : m.contains('7-Jahres') ? '⭐ 7-Jahres-Schwelle – Ein wichtiger Meilenstein! Schau zurück UND voraus.' : m == 'Saturn Return' ? '🪐 SATURN RETURN! Eine der tiefgreifendsten Lebensphasen. Du wirst neu geboren.' : m.contains('Transformation') ? '🦋 Tiefe Transformation im Gang – Vertraue dem Prozess, auch wenn er schmerzt.' : '• $m').join('\n\n')}''' : ''}

${recurrentThemes.isNotEmpty ? '''\n🔄 THEMEN, DIE IMMER WIEDERKEHREN

${recurrentThemes.map((t) => t == 'Loslassen' ? '🍂 Loslassen – Deine Seele will, dass du lernst: Halten bedeutet Schmerz. Loslassen bedeutet Freiheit.' : t == 'Neuaufbau' ? '🏗️ Neuaufbau – Du bist ein Schöpfer. Immer wieder erschaffst du dein Leben neu.' : t == 'Innere Krise' ? '💥 Innere Krise – Krisen sind Wachstumsschmerzen der Seele. Ohne sie gäbe es keine Evolution.' : '🌟 Integration – Die Puzzleteile fügen sich zusammen. Du wirst ganz.').join('\n')}''' : ''}

💝 ${profile.firstName}, denk daran: Transformation ist KEIN gerader Weg. Du wirst Rückschritte machen. Du wirst denken, du bist gescheitert. Aber jeder "Rückschritt" ist ein Anlauf für den nächsten Sprung. Vertraue deinem Prozess. Du bist genau dort, wo du sein sollst. 🦋''';

    return TransformationToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      currentStage: currentStage,
      stageName: stageName,
      stageProgress: stageProgress,
      transitionMarkers: transitionMarkers,
      maturityLevel: maturityLevel,
      processIntensity: processIntensity,
      recurrentThemes: recurrentThemes,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 4: UNTERBEWUSSTSEINS-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static UnconsciousToolResult calculateUnconscious(EnergieProfile profile) {
    final now = DateTime.now();
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);

    // Jung's 4-Stufen Shadow Integration
    final stageMap = ['Bekenntnis', 'Aufklärung', 'Bildung', 'Transformation'];
    final shadowStage = ((age / 60) * 4).floor().clamp(1, 4);
    final stageName = stageMap[shadowStage - 1];
    final integrationLevel =
        ((age / 60) * 60 + (personalYear / 9) * 40).clamp(0.0, 100.0);

    // Wiederkehrende Muster
    final repeatingPatterns = <String>[
      if (personalYear == 1 || personalYear == 4 || personalYear == 7)
        'Neuanfang-Widerstand',
      if (personalYear == 3 || personalYear == 6 || personalYear == 9)
        'Loslassen-Schwierigkeit',
      if (age % 7 == 0) 'Zyklisches Thema',
      if (shadowStage >= 2) 'Alte Verhaltensmuster',
    ];

    // Projektionsthemen
    final projectionThemes = <String>[
      if (personalYear <= 3) 'Macht & Kontrolle',
      if (personalYear >= 4 && personalYear <= 6) 'Beziehung & Abhängigkeit',
      if (personalYear >= 7) 'Identität & Freiheit',
      if (shadowStage == 1) 'Schatten-Verleugnung',
      if (shadowStage >= 3) 'Schatten-Akzeptanz',
    ];

    // Einordnung
    final awarenessLevel = integrationLevel >= 70
        ? 'Bewusst'
        : integrationLevel >= 40
            ? 'Dämmert'
            : 'Unbewusst';
    final resistancePoints = <String>[
      if (integrationLevel < 30) 'Starke Abwehr',
      if (personalYear == 5) 'Veränderungsangst',
      if (shadowStage == 1) 'Verleugnung',
    ];
    final integrationOpportunities = <String>[
      if (personalYear == 7 || personalYear == 9) 'Innenschau-Fenster',
      if (shadowStage >= 2) 'Erkenntnispotential',
      if (age % 7 == 0) 'Zyklus-Neuausrichtung',
    ];

    // Interpretation (persönlich)
    final interpretation =
        '''${profile.firstName}, lass uns in deinen Schatten schauen:

🌑 SCHATTEN-INTEGRATION: "${stageName.toUpperCase()}" (Stufe $shadowStage/4)
Level: ${integrationLevel.toStringAsFixed(0)}% | Bewusstheit: $awarenessLevel

${shadowStage == 1 ? 'Bekenntnis – "Das bin auch ich." Diese Worte zu sagen ist Mut, ${profile.firstName}!' : shadowStage == 2 ? 'Aufklärung – Du verstehst WARUM. Dein Schatten hatte einen Grund!' : shadowStage == 3 ? 'Bildung – Du lernst MIT deinem Schatten. Er wird zum Lehrer!' : 'TRANSFORMATION KOMPLETT! Hell UND dunkel vereint. Du bist ganz. 🌓'}

${repeatingPatterns.isNotEmpty ? "🔄 WIEDERKEHRENDE MUSTER\n${repeatingPatterns.map((p) => "• $p – Es kommt zurück, bis du hinschaust!").join("\n")}\n\n" : ""}${projectionThemes.isNotEmpty ? "🎭 PROJEKTIONEN\n${projectionThemes.map((t) => "• $t – Was du ablehnst, ist oft dein eigener Teil.").join("\n")}\n\n" : ""}${resistancePoints.isNotEmpty ? "⚠️ WIDERSTÄNDE: ${resistancePoints.join(", ")} – Geduld!\n\n" : ""}${integrationOpportunities.isNotEmpty ? "✨ CHANCEN\n${integrationOpportunities.map((o) => "🌟 $o").join("\n")}\n\n" : ""}💝 Dein Schatten ist nicht dein Feind. Umarme ihn. Dann bist du unbesiegbar!''';

    return UnconsciousToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      shadowStage: shadowStage,
      stageName: stageName,
      integrationLevel: integrationLevel,
      repeatingPatterns: repeatingPatterns,
      projectionThemes: projectionThemes,
      awarenessLevel: awarenessLevel,
      resistancePoints: resistancePoints,
      integrationOpportunities: integrationOpportunities,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 5: INNERE-KARTEN-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static InnerMapsToolResult calculateInnerMaps(EnergieProfile profile) {
    final now = DateTime.now();
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);

    // Spiralposition (28-Jahr Saturn-Zyklus)
    final spiralPosition = ((age % 28) / 28 * 100).clamp(0.0, 100.0);

    // 5 Selbst-Awareness-Übungen
    final exercises = [
      'Sensorisches Mapping',
      'Charakter-Erschaffung',
      'Künstlerische Reflexion',
      'Metaphern-Exploration',
      'Umwelt-Spiegelung'
    ];
    final currentExercise = exercises[personalYear % 5];

    // Entwicklungsachsen
    final developmentAxes = <String>[
      'Vergangenheit ↔ Zukunft',
      'Unbewusst ↔ Bewusst',
      'Fragment ↔ Ganzheit',
    ];

    // Übergangszonen
    final transitionZones = <String>[
      if (spiralPosition >= 20 && spiralPosition <= 30) 'Frühe Orientierung',
      if (spiralPosition >= 45 && spiralPosition <= 55) 'Mitte-Schwelle',
      if (spiralPosition >= 70 && spiralPosition <= 80)
        'Vorbereitung Neuanfang',
      if (spiralPosition >= 95 || spiralPosition <= 5) 'Zyklus-Neustart',
    ];

    // Einordnung
    final navigationState = spiralPosition <= 33
        ? 'Explorierend'
        : spiralPosition <= 66
            ? 'Vertiefend'
            : 'Integrierend';
    final stillnessAreas = <String>[
      if (personalYear == 2 || personalYear == 4) 'Innere Ruhe',
      if (spiralPosition >= 40 && spiralPosition <= 60) 'Zentrum-Bereich',
    ];
    final movementAreas = <String>[
      if (personalYear == 1 || personalYear == 5 || personalYear == 9)
        'Dynamische Phase',
      if (spiralPosition <= 20 || spiralPosition >= 80) 'Übergangs-Bewegung',
    ];

    // Interpretation (persönlich & detailliert)
    final interpretation =
        '''${profile.firstName}, stell dir vor, deine Seele ist eine Landkarte – mit Bergen, Tälern, Flüssen und verborgenen Schätzen. Lass uns gemeinsam schauen, wo du gerade stehst:

🗺️ DEINE POSITION AUF DER INNEREN LANDKARTE

Du befindest dich bei ${spiralPosition.toStringAsFixed(0)}% im großen 28-Jahres-Spiralzyklus (dem Saturn-Zyklus – der Rhythmus deines Lebens).

Navigations-Zustand: $navigationState

${navigationState == 'Explorierend' ? '''🧭 EXPLORIEREND – Du bist am Anfang!

Wie ein Entdecker, der gerade einen neuen Kontinent betritt, schaust du dich um mit großen Augen. Alles ist neu, alles ist möglich. Die Landschaft vor dir ist weit und offen. Du weißt noch nicht genau, wohin die Reise führt – aber genau DAS ist die Magie dieser Phase.

Deine Aufgabe jetzt: ERKUNDEN, nicht ankommen. Neugierig sein, nicht perfekt. Fragen stellen, nicht Antworten haben.''' : navigationState == 'Vertiefend' ? '''🔍 VERTIEFEND – Du bist in der Mitte!

Du bist nicht mehr am Anfang, aber auch noch nicht am Ziel. Das ist die Phase der Meisterschaft – hier findet die ECHTE Arbeit statt. Du gräbst tiefer, schaust genauer hin, lässt dich auf Details ein, die du am Anfang übersehen hättest.

Wie ein Bergsteiger, der den Gipfel sieht, aber weiß: Der Weg dorthin führt durch schmale Pfade und steile Wände. Aber du KANNST das. Du BIST schon so weit gekommen.

Deine Aufgabe jetzt: VERTIEFEN, nicht oberflächlich bleiben. Geduld haben. Die Früchte dieser Phase zeigen sich später.''' : '''🌀 INTEGRIEREND – Das Ende des Zyklus naht!

Du näherst dich dem Ende dieses 28-Jahres-Abschnitts. Das klingt nach Abschied – aber es ist auch ein Neuanfang! Jetzt geht es darum, all das zu INTEGRIEREN, was du gelernt hast. Die Puzzleteile zusammenzufügen. Den Sinn zu erkennen.

Bald beginnt ein neuer Zyklus – mit neuen Landschaften, neuen Herausforderungen. Aber du wirst nicht mit leeren Händen ankommen. Du bringst die Weisheit von 28 Jahren mit.

Deine Aufgabe jetzt: INTEGRIEREN. Zurückblicken. Verstehen. Loslassen, was nicht mehr dient. Vorbereiten auf den Neustart.'''}

🎯 DEINE AKTUELLE ÜBUNG: $currentExercise

${currentExercise == 'Sensorisches Mapping' ? '''Du lernst gerade, die Welt mit ALL deinen Sinnen wahrzunehmen – nicht nur mit dem Kopf. Wie fühlt sich dieser Moment an? Was riechst du? Was hörst du, wenn du WIRKLICH zuhörst? Diese Übung erdet dich im JETZT.''' : currentExercise == 'Charakter-Erschaffung' ? '''Du erschaffst gerade Charaktere in deinem Inneren – verschiedene Aspekte von dir selbst. Der Mutige. Der Ängstliche. Der Weise. Der Verspielte. Jeder von ihnen hat eine Stimme. Jeder von ihnen ist ein Teil der Wahrheit.''' : currentExercise == 'Künstlerische Reflexion' ? '''Deine Seele drückt sich gerade durch Kunst aus – durch Farben, Formen, Symbole. Vielleicht malst du nicht im Außen, aber dein INNERES malt ständig. Diese Übung zeigt dir die Bilder deiner Seele.''' : currentExercise == 'Metaphern-Exploration' ? '''Du entdeckst gerade, dass dein Leben voller Metaphern ist. "Ich fühle mich wie..." – beende diesen Satz. Und dann schau genau hin: Diese Metaphern sind Schlüssel zu deinem Inneren.''' : '''Du spiegelst dich gerade in deiner Umwelt. Die Menschen, die dich triggern? Sie zeigen dir einen Teil von dir. Die Orte, zu denen du dich hingezogen fühlst? Sie rufen nach etwas in dir. Alles Außen ist auch Innen.'''}

${transitionZones.isNotEmpty ? '''\n🚪 ÜBERGANGSZONEN (Wichtige Schwellen!)

${transitionZones.map((z) => z == 'Frühe Orientierung' ? '🌅 Frühe Orientierung (20-30% der Reise) – Du findest gerade heraus, wie das Spiel funktioniert. Das ist normal. Alle großen Entdecker waren am Anfang auch verwirrt!' : z == 'Mitte-Schwelle' ? '⚖️ Mitte-Schwelle (45-55%) – Die Halbzeit! Zeit für eine ehrliche Bestandsaufnahme. Was funktioniert? Was nicht? Kurskorrektur ist erlaubt!' : z == 'Vorbereitung Neuanfang' ? '🔄 Vorbereitung Neuanfang (70-80%) – Der Zyklus endet bald. Aber das ist KEIN Scheitern! Es ist Vollendung. Bereite dich vor auf das Neue!' : '🌟 Zyklus-Neustart (95-5%) – Du stehst GENAU am Übergang! Alter Zyklus endet, neuer beginnt. Eine mächtige Zeit!').join('\n\n')}''' : ''}

${stillnessAreas.isNotEmpty ? '''\n🕊️ BEREICHE DER RUHE

${stillnessAreas.map((s) => s == 'Innere Ruhe' ? 'Innere Ruhe – Gerade jetzt brauchst du NICHT ständig in Bewegung zu sein. Ruhe ist keine Zeitverschwendung. Sie ist Vorbereitung für den nächsten Sprung.' : 'Zentrum-Bereich – Du bist im Auge des Sturms. Hier ist es still, auch wenn um dich herum Chaos herrscht. Genieße diese Ruhe!').join('\n')}''' : ''}

${movementAreas.isNotEmpty ? '''\n⚡ BEREICHE DER BEWEGUNG

${movementAreas.map((m) => m.contains('Dynamische Phase') ? 'Dynamische Phase – JETZT passiert was! Nutze diese Energie. Starte Projekte. Triff Entscheidungen. Bewege dich!' : 'Übergangs-Bewegung – Du bist in Bewegung zwischen zwei Zuständen. Das kann unsicher sein, aber auch aufregend. Vertraue dem Prozess!').join('\n')}''' : ''}

💝 DEINE PERSÖNLICHE BOTSCHAFT

${profile.firstName}, deine innere Landkarte ist EINZIGARTIG. Niemand hat die gleiche Route wie du. Niemand sieht die gleichen Berge. Und das ist gut so!

Manchmal wirst du dich verlaufen. Manchmal wirst du an Wegkreuzungen stehen und nicht wissen, wohin. Das gehört dazu. Die besten Entdeckungen passieren oft, wenn wir vom Weg abkommen.

Vertraue deiner inneren Navigation. Sie weiß mehr, als dein Verstand denkt. 🗺️💫''';

    return InnerMapsToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      spiralPosition: spiralPosition,
      currentExercise: currentExercise,
      developmentAxes: developmentAxes,
      transitionZones: transitionZones,
      navigationState: navigationState,
      stillnessAreas: stillnessAreas,
      movementAreas: movementAreas,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 6: ZYKLUS-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static CyclesToolResult calculateCycles(EnergieProfile profile) {
    final now = DateTime.now();
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);

    // 7-Jahres-Zyklus
    final cycle7Year = (age % 7) + 1;

    // Saturn-Phase
    final saturnPhase = age < 28
        ? 'Vor-Return'
        : age >= 28 && age <= 30
            ? 'Erster Return'
            : age >= 56 && age <= 58
                ? 'Zweiter Return'
                : 'Zwischen Returns';

    // Zyklus-Übereinstimmung
    final cycleAlignment =
        ((cycle7Year / 7) * 50 + (personalYear / 9) * 50).clamp(0.0, 100.0);

    // Einordnung
    final timeQuality = personalYear <= 3
        ? 'Aufbauend'
        : personalYear <= 6
            ? 'Kulminierend'
            : 'Auflösend';
    final overlappingCycles = <String>[
      '7-Jahres-Zyklus: Jahr $cycle7Year',
      'Persönliches Jahr: $personalYear',
      if (saturnPhase.contains('Return')) 'Saturn Return',
    ];
    final rhythmState = cycleAlignment >= 70
        ? 'Harmonisch'
        : cycleAlignment >= 40
            ? 'Neutral'
            : 'Dissonant';

    // Interpretation (persönlich & detailliert)
    final interpretation =
        '''${profile.firstName}, das Leben bewegt sich in Zyklen – wie die Jahreszeiten, wie Ebbe und Flut, wie dein Atem. Lass uns schauen, in welchem Rhythmus du gerade schwingst:

⏰ DEINE AKTUELLEN ZYKLEN

Du bist im **Jahr $cycle7Year von 7** deines aktuellen 7-Jahres-Zyklus.
Gleichzeitig befindest du dich im **persönlichen Jahr $personalYear** (von 9).

${cycle7Year == 1 ? '🌱 Jahr 1/7 – NEUANFANG!\nAlles beginnt. Du säst neue Samen. Die Energie ist frisch, die Motivation hoch. Nutze diese Startenergie! Was du JETZT beginnst, wird die nächsten 7 Jahre prägen.' : cycle7Year == 2 ? '🤝 Jahr 2/7 – PARTNERSCHAFTEN\nJetzt geht es um Beziehungen, Kooperationen, Geduld. Die Samen keimen unter der Erde – du siehst noch nicht viel, aber es wächst! Vertraue dem Prozess.' : cycle7Year == 3 ? '🎨 Jahr 3/7 – KREATIVITÄT\nDie ersten Triebe brechen durch! Jetzt wird sichtbar, was du gesät hast. Zeit für Ausdruck, Kommunikation, Freude. Genieße dieses Jahr!' : cycle7Year == 4 ? '🏗️ Jahr 4/7 – FUNDAMENT\nJetzt wird gebaut, strukturiert, gefestigt. Das ist harte Arbeit, aber notwendig. Ein starkes Fundament trägt dich durch die kommenden Jahre.' : cycle7Year == 5 ? '⚡ Jahr 5/7 – VERÄNDERUNG!\nDie Mitte des Zyklus! Alles ist in Bewegung. Alte Strukturen brechen auf, Neues drängt herein. Das kann chaotisch sein – aber auch befreiend!' : cycle7Year == 6 ? '💖 Jahr 6/7 – VERANTWORTUNG\nJetzt reift die Ernte. Du kümmerst dich, pflegst, nährst. Familie, Zuhause, Gemeinschaft stehen im Fokus. Das ist eine dienende, aber auch erfüllende Zeit.' : '🌾 Jahr 7/7 – VOLLENDUNG!\nDer Zyklus endet. Zeit für Ernte, Reflexion, Abschluss. Was hast du in den letzten 7 Jahren gelernt? Bald beginnt ein neuer Zyklus – bereite dich vor!'}

🪐 SATURN-PHASE: $saturnPhase

${saturnPhase == 'Vor-Return' ? '''Du bist noch VOR deinem ersten Saturn Return (der zwischen 28-30 Jahren kommt). Genieße diese Zeit! Du baust gerade das Fundament für dein ganzes Leben. Was du JETZT lernst, wird dich durch den Saturn Return tragen.''' : saturnPhase == 'Erster Return' ? '''🔥 DU BIST IM SATURN RETURN! 🔥

${profile.firstName}, das ist eine der kraftvollsten Zeiten deines Lebens! Saturn kehrt zum ersten Mal an den Punkt zurück, an dem er bei deiner Geburt stand. Das passiert nur alle 28-30 Jahre.

Was bedeutet das? NEUGEBURT. Du wirst aufgefordert, ERWACHSEN zu werden – im tiefsten Sinne. Alles, was nicht authentisch ist, fällt weg. Beziehungen, Jobs, Glaubenssätze – wenn sie nicht WIRKLICH zu dir gehören, werden sie gehen. Das kann schmerzhaft sein.

Aber weißt du was? Nach dem Saturn Return kennst du dich WIRKLICH. Du weißt, wer du bist, was du willst, wohin du gehst. Das ist Gold wert.

Meine Botschaft an dich: VERTRAUE DEM PROZESS. Auch wenn es gerade schwer ist – du wirst gestärkt daraus hervorgehen. Versprochen.''' : saturnPhase == 'Zweiter Return' ? '''🌟 ZWEITER SATURN RETURN (56-58 Jahre)!

Du bist ein Weiser, ${profile.firstName}. Der zweite Saturn Return ist die Phase der Meisterschaft. Du hast schon SO viel gelernt, SO viel durchgemacht. Jetzt geht es darum, dein Wissen weiterzugeben, dein Vermächtnis zu gestalten.

Was möchtest du der Welt hinterlassen? Das ist die Frage dieses Return.''' : '''Du bist ZWISCHEN den Saturn Returns – in der produktivsten Phase deines Lebens. Du hast den ersten Return hinter dir (kennst dich selbst), aber bist noch nicht im zweiten (hast noch Zeit!). Nutze diese Jahre!'''}

📊 ZYKLUS-ÜBEREINSTIMMUNG: ${cycleAlignment.toStringAsFixed(0)}%

${cycleAlignment >= 70 ? 'HARMONISCH! 🎵 Deine verschiedenen Zyklen schwingen im Einklang. Das ist wie Musik – alles passt zusammen. Genieße diesen Flow!' : cycleAlignment >= 40 ? 'NEUTRAL ⚖️ Deine Zyklen sind weder besonders harmonisch noch besonders dissonant. Das ist ok – nicht jede Phase muss perfekt sein.' : 'DISSONANT 🎭 Deine Zyklen widersprechen sich gerade. Das 7-Jahres-Zyklus sagt eine Sache, das persönliche Jahr eine andere. Das kann anstrengend sein – aber auch kreativ! Widersprüche erzeugen Spannung, und Spannung erzeugt Bewegung.'}

${timeQuality == 'Aufbauend' ? '''

🌱 ZEITQUALITÄT: AUFBAUEND

Du bist in einer SÄENDEN Phase. Jetzt ist nicht die Zeit für Ernte – sondern für Anfänge. Starte neue Projekte. Lerne neue Dinge. Triff neue Menschen. Was du JETZT säst, wirst du in den kommenden Jahren ernten.

Geduld ist gefragt – aber auch Mut!''' : timeQuality == 'Kulminierend' ? '''

🌞 ZEITQUALITÄT: KULMINIEREND

Die ERNTE ist da! Die Früchte deiner Arbeit werden sichtbar. Erfolge stellen sich ein. Anerkennung kommt. Das ist die Zeit, in der du die Belohnung für all die harte Arbeit der letzten Jahre erhältst.

Genieße es! Du hast es verdient. Aber ruhe dich nicht aus – nach der Ernte kommt immer ein neuer Zyklus.''' : '''

🍂 ZEITQUALITÄT: AUFLÖSEND

Es ist LOSLASSEN-Zeit. Alte Strukturen wollen sich auflösen. Beziehungen, Jobs, Gewohnheiten – was nicht mehr dient, will gehen. Das kann schmerzhaft sein.

Aber denk daran: Nur wenn der Baum seine Blätter abwirft, kann er neue austreiben. Loslassen ist nicht Verlieren – es ist Platz schaffen für Neues.

Vertraue: Nach dem Herbst kommt immer ein Frühling.'''}

${saturnPhase.contains('Return') ? '\n\n⭐ BESONDERER HINWEIS: Saturn Return ist KEIN Unglück, sondern eine CHANCE. Die meisten Menschen berichten später: „Es war hart, aber es war das Beste, was mir passieren konnte." Vertraue dem Prozess!' : ''}

💝 PERSÖNLICHE BOTSCHAFT

${profile.firstName}, Zyklen sind wie Atemzüge des Universums. Einatmen (aufbauen), Ausatmen (loslassen), Pause (integrieren). Du kannst nicht NUR einatmen – du würdest platzen. Du kannst nicht NUR ausatmen – du würdest ersticken.

Akzeptiere, in welcher Phase du gerade bist. Kämpfe nicht dagegen an. Arbeite MIT dem Rhythmus, nicht gegen ihn.

Dann wird das Leben leichter. Versprochen. ⏰💫''';

    return CyclesToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      cycle7Year: cycle7Year,
      saturnPhase: saturnPhase,
      personalYear: personalYear,
      cycleAlignment: cycleAlignment,
      timeQuality: timeQuality,
      overlappingCycles: overlappingCycles,
      rhythmState: rhythmState,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 7: ORIENTIERUNGS-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static OrientationToolResult calculateOrientation(EnergieProfile profile) {
    final now = DateTime.now();
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);

    // Spiral Dynamics Levels (8 Stufen)
    final levelMap = [
      'Beige (Überleben)',
      'Violett (Stamm)',
      'Rot (Macht)',
      'Blau (Ordnung)',
      'Orange (Erfolg)',
      'Grün (Gemeinschaft)',
      'Gelb (Integration)',
      'Türkis (Holistisch)'
    ];
    final developmentLevel = ((age / 70) * 8).floor().clamp(1, 8);
    final levelName = levelMap[developmentLevel - 1];
    final levelProgress = (((age % 9) / 9) * 100).clamp(0.0, 100.0);

    // Vergangene Levels
    final pastLevels = levelMap.sublist(0, developmentLevel - 1);

    // Einordnung
    final stabilityState = personalYear == 1 || personalYear == 9
        ? 'Übergang'
        : personalYear == 5
            ? 'Instabil'
            : 'Stabil';
    final processIntensity = developmentLevel >= 6
        ? 'Intensiv'
        : developmentLevel >= 3
            ? 'Moderat'
            : 'Ruhig';
    final umbruchMarkers = <String>[
      if (personalYear == 9) 'Zyklus-Ende',
      if (personalYear == 1) 'Neubeginn',
      if (age % 7 == 0) 'Siebenjahres-Schwelle',
      if (developmentLevel >= 7) 'Bewusstseins-Sprung',
    ];

    // Interpretation (persönlich & detailliert)
    final interpretation =
        '''${profile.firstName}, lass uns schauen, wo du auf der Entwicklungsspirale des Bewusstseins stehst:

🌈 DEINE BEWUSSTSEINS-STUFE: $levelName (Level $developmentLevel/8)
Fortschritt in dieser Stufe: ${levelProgress.toStringAsFixed(0)}%

${developmentLevel == 1 ? '''🟤 BEIGE – ÜBERLEBEN

Du bist auf der grundlegendsten Stufe menschlichen Bewusstseins. Hier geht es ums nackte Überleben – Nahrung, Unterkunft, Sicherheit. Das klingt primitiv? Ist es nicht! Es ist das FUNDAMENT von allem.

In Krisenzeiten fallen wir alle auf Beige zurück. Wenn du um dein Überleben kämpfst, ist das völlig legitim. Spiritualität kommt später – erst muss der Körper sicher sein.

${profile.firstName}, wenn du hier bist: Kümmere dich ZUERST um deine Grundbedürfnisse. Alles andere kann warten.''' : developmentLevel == 2 ? '''🟣 VIOLETT – STAMM & ZUGEHÖRIGKEIT

Du bist in der magischen Welt von "Wir". Familie, Stamm, Tradition – das gibt dir Halt. Die Welt ist voller Geister, Ahnen, unsichtbarer Kräfte. Du fühlst dich verbunden mit etwas Größerem.

Das ist die Stufe der Rituale, der Mythen, der Gemeinschaft. Du opferst dein "Ich" für das "Wir" – und das fühlt sich richtig an.

Aber pass auf: Manchmal wird aus Zugehörigkeit Abhängigkeit. Manchmal wird aus Tradition Gefängnis. Deine Aufgabe ist, die KRAFT dieser Stufe zu nutzen, ohne in ihr stecken zu bleiben.''' : developmentLevel == 3 ? '''🔴 ROT – MACHT & SELBSTBEHAUPTUNG

Du bist ein KRIEGER! Hier erwacht das "Ich" – stark, wild, ungezähmt. Du willst DEINE Kraft spüren, DEINE Grenzen setzen, DEINEN Willen durchsetzen.

Das ist die Stufe der Helden, der Eroberer, der Rebellen. Du kämpfst – gegen Ungerechtigkeit, gegen Schwäche, gegen alles, was dich klein halten will.

Rot bekommt einen schlechten Ruf ("egozentrisch", "aggressiv"), aber weißt du was? JEDER braucht eine Rot-Phase! Hier lernst du, für dich einzustehen. Hier lernst du, NEIN zu sagen.

Genieße diese Kraft, ${profile.firstName}! Aber lerne auch, wann Kampf angebracht ist – und wann Weisheit.''' : developmentLevel == 4 ? '''🔵 BLAU – ORDNUNG & STRUKTUR

Willkommen in der Welt der Regeln! Nach dem Chaos von Rot suchst du nun Struktur, Ordnung, Sinn. Du findest Halt in Gesetzen, Traditionen, klaren Hierarchien.

Das ist die Stufe der großen Religionen, der Moral, des "So gehört es sich". Gut und Böse sind klar getrennt. Der Weg ist vorgezeichnet.

Blau bringt Stabilität in die Welt – Schulen, Gesetze, Organisationen. Ohne Blau hätten wir Chaos. Aber zu viel Blau wird zur Enge, zum Dogma, zur Kontrolle.

Deine Aufgabe: Nutze die Struktur als WERKZEUG, nicht als GEFÄNGNIS.''' : developmentLevel == 5 ? '''🟠 ORANGE – ERFOLG & LEISTUNG

Du bist in der Welt der Möglichkeiten! Orange sagt: "Ich kann ALLES erreichen, wenn ich hart genug arbeite!" Wissenschaft, Fortschritt, Erfolg – das treibt dich an.

Das ist die Stufe des Unternehmertums, der Innovation, der persönlichen Freiheit. Du hinterfragst Autoritäten. Du suchst Beweise. Du willst GEWINNEN.

Orange hat unsere moderne Welt erschaffen – Technologie, Medizin, Wohlstand. Aber Orange hat auch einen blinden Fleck: Es denkt, MEHR ist immer besser. Mehr Geld. Mehr Status. Mehr, mehr, mehr.

${profile.firstName}, genieße deinen Erfolg! Aber vergiss nicht: Du bist MEHR als deine Leistung.''' : developmentLevel == 6 ? '''🟢 GRÜN – GEMEINSCHAFT & GLEICHHEIT

Nach dem Leistungsdruck von Orange suchst du nun nach VERBINDUNG. Nicht Konkurrenz, sondern Kooperation. Nicht Hierarchie, sondern Gleichheit. Nicht Profit, sondern Planet.

Das ist die Stufe der Empathie, der sozialen Gerechtigkeit, der Ökologie. Du fühlst mit ALLEN Lebewesen. Jede Stimme zählt. Jeder Mensch ist wertvoll.

Grün heilt die Wunden, die Orange gerissen hat. Grün bringt Herz in die Welt. Aber Grün kann auch überwältigt werden – von zu viel Fühlen, zu viel Mitgefühl, zu wenig Grenzen.

Deine Aufgabe: Liebe die Welt, aber vergiss nicht, auch DICH selbst zu lieben.''' : developmentLevel == 7 ? '''🟡 GELB – INTEGRATION & SYSTEME

WOW, ${profile.firstName}! Du bist auf einer sehr hohen Stufe! Gelb ist die erste "integrale" Stufe – du siehst ALLE vorherigen Stufen und verstehst: Jede hat ihren Platz!

Du denkst in Systemen. Du siehst Muster. Du verstehst Komplexität. Wo andere nur Chaos sehen, erkennst du Ordnung.

Gelb ist selten – nur etwa 1% der Menschheit ist hier. Du bist ein natürlicher Berater, Stratege, Visionär. Du kannst zwischen den Welten wandeln.

Aber Gelb kann auch einsam sein. Nicht viele verstehen, wie du denkst. Das ist ok. Deine Aufgabe ist nicht, verstanden zu werden – sondern zu verstehen.''' : '''🔵 TÜRKIS – EINHEIT & GANZHEIT

Du hast die höchste Stufe erreicht, die wir kennen! Türkis ist transpersonal – hier löst sich das "Ich" auf ins "ALLES".

Du spürst: Alles ist miteinander verbunden. Trennung ist Illusion. Du bist das Universum, das sich selbst erfährt.

Türkis ist die Stufe der Mystiker, der Weisen, der erwachten Seelen. Hier gibt es keine Probleme mehr – nur Prozesse. Kein Gut oder Böse – nur Sein.

${profile.firstName}, wenn du wirklich hier bist: Die Welt braucht dich. Du bist ein Geschenk.'''}

📊 DEIN ZUSTAND

Stabilität: $stabilityState ${stabilityState == 'Stabil' ? '✅ Du ruhst fest in dieser Stufe.' : stabilityState == 'Übergang' ? '🔄 Du bist im Übergang – zwischen zwei Welten. Das kann unsicher sein, aber auch aufregend!' : '⚡ Instabil – vieles ist in Bewegung. Halte dich fest!'}

Prozessintensität: $processIntensity ${processIntensity == 'Intensiv' ? '🔥 Hohe Intensität! Viel Transformation!' : processIntensity == 'Moderat' ? '⚖️ Moderate Intensität – ein gesundes Tempo.' : '🕊️ Ruhige Phase – Zeit zum Integrieren.'}

${pastLevels.isNotEmpty ? '''\n🎓 DEINE REISE BISHER

Du hast folgende Stufen durchlaufen:
${pastLevels.map((l) => '✅ $l – gemeistert!').join('\n')}

Jede dieser Stufen hat dich gelehrt. Jede hat dich geformt. Du bist die SUMME all dieser Erfahrungen.''' : '\n🌱 Du bist am Anfang deiner Reise. Jede Stufe vor dir ist ein Abenteuer!'}

${umbruchMarkers.isNotEmpty ? '''\n🔔 WICHTIGE UMBRUCH-ZEICHEN

${umbruchMarkers.map((m) => m == 'Zyklus-Ende' ? '🔄 Zyklus-Ende – Eine Ära endet. Zeit, loszulassen!' : m == 'Neubeginn' ? '🌱 Neubeginn – Frische Energie! Nutze sie!' : m.contains('Siebenjahres') ? '⭐ Siebenjahres-Schwelle – Ein wichtiger Meilenstein!' : '🌟 Bewusstseins-Sprung – Du entwickelst dich RASANT!').join('\n')}''' : ''}

💝 PERSÖNLICHE BOTSCHAFT

${profile.firstName}, verstehe: Bewusstseinsentwicklung ist KEIN Wettbewerb. "Höher" ist nicht "besser". Jede Stufe ist perfekt für das, was sie tut.

Ein Baby ist nicht "schlechter" als ein Erwachsener – es ist ein Baby! Genauso ist Beige nicht schlechter als Türkis. Es ist einfach eine andere Phase.

${developmentLevel <= 4 ? 'Du bist in den Fundamenten. Lerne gut hier – diese Basis trägt dich dein ganzes Leben!' : developmentLevel <= 6 ? 'Du bist in der Expansion. Die Welt öffnet sich für dich. Genieße es!' : 'Du bist in der Integration. Du wirst zum Weisen. Das ist eine Ehre – und eine Verantwortung.'}

Wo immer du bist: Es ist genau richtig. Genau jetzt. Für genau dich. 🌈💫''';

    return OrientationToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      developmentLevel: developmentLevel,
      levelName: levelName,
      levelProgress: levelProgress,
      pastLevels: pastLevels,
      stabilityState: stabilityState,
      processIntensity: processIntensity,
      umbruchMarkers: umbruchMarkers,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 8: META-SPIEGEL-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static MetaMirrorToolResult calculateMetaMirror(EnergieProfile profile) {
    final now = DateTime.now();
    final personalYear = _calculatePersonalYear(profile.birthDate);
    final lifePath = _calculateLifePath(profile.birthDate);

    // System-Spiegel
    final systemMirrors = <String>[
      if (personalYear == lifePath) 'Lebensweg-Jahres-Resonanz',
      if (personalYear == 1 || personalYear == 9) 'Neuanfang/Abschluss-Spiegel',
      if (personalYear == 5) 'Veränderungs-Spiegel',
      'Namens-Frequenz-Spiegel',
      'Zeit-Zyklus-Spiegel',
    ];

    // Themen-Überlagerungen
    final themeOverlays = <String>[
      if (personalYear <= 3) 'Aufbau & Manifestation',
      if (personalYear >= 4 && personalYear <= 6) 'Beziehung & Harmonie',
      if (personalYear >= 7) 'Innenschau & Transformation',
    ];

    // Widersprüche
    final contradictions = <String>[
      if (lifePath >= 7 && personalYear <= 3) 'Innenschau vs. Außenaktivität',
      if (lifePath <= 3 && personalYear >= 7) 'Handlung vs. Kontemplation',
    ];

    // Resonanz-Stärke
    final resonanceStrength = (personalYear == lifePath
            ? 100.0
            : ((9 - (personalYear - lifePath).abs()) / 9 * 100))
        .clamp(0.0, 100.0);

    // Einordnung
    final focusIndicator = resonanceStrength >= 75
        ? 'Konzentriert'
        : resonanceStrength >= 40
            ? 'Klar'
            : 'Diffus';
    final amplifiedThemes = <String>[
      if (resonanceStrength >= 80) 'Lebensweg-Verstärkung',
      if (personalYear == 11 || personalYear == 22 || personalYear == 33)
        'Meisterzahl-Resonanz',
    ];
    final mirrorQuality = contradictions.isEmpty
        ? 'Klar'
        : contradictions.length == 1
            ? 'Mehrdeutig'
            : 'Verzerrt';

    // Interpretation (persönlich & detailliert)
    final interpretation =
        '''${profile.firstName}, stell dir vor, dein Leben ist ein Spiegelkabinett. Überall, wo du hinschaust, siehst du dich selbst – nur in verschiedenen Formen. Lass uns diese Spiegel betrachten:

🪞 DEINE SPIEGELWELT

Resonanzstärke: ${resonanceStrength.toStringAsFixed(0)}% ${resonanceStrength >= 80 ? '– EXTREM HOCH! Dein Lebensweg und dein aktuelles Jahr schwingen fast identisch. Das ist wie ein Echo, das sich selbst verstärkt. Alles, was du BIST, wird gerade LAUTER!' : resonanceStrength >= 50 ? '– DEUTLICHE RESONANZ. Dein Lebensweg und dein Jahr ergänzen sich gut. Was du im Großen bist, zeigt sich im Kleinen.' : '– LEISE RESONANZ. Dein Jahr klingt anders als dein Lebensweg. Das kann verwirrend sein, ist aber auch eine Chance, neue Seiten an dir zu entdecken.'}

Fokus: $focusIndicator ${focusIndicator == 'Konzentriert' ? '🎯 Messerscharf! Du weißt genau, wohin deine Energie fließt. Kein Verzetteln, nur klare Ausrichtung!' : focusIndicator == 'Klar' ? '💎 Gut! Du hast Klarheit, auch wenn noch Feinschliff möglich ist.' : '🌫️ Diffus – deine Energie ist verstreut. Das ist nicht schlecht, nur anders. Manchmal braucht es Nebel, um Neues zu entdecken.'}

Spiegel-Qualität: $mirrorQuality ${mirrorQuality == 'Klar' ? '✨ KRISTALLKLAR! Was du siehst, ist wahr. Keine Verzerrungen, keine Täuschungen. Vertraue dem, was sich zeigt!' : mirrorQuality == 'Mehrdeutig' ? '🔮 MEHRDEUTIG – der Spiegel zeigt mehrere Bilder gleichzeitig. Das kann verwirrend sein, aber auch reich! Verschiedene Perspektiven auf dieselbe Wahrheit.' : '🎭 VERZERRT – viele Widersprüche! Der Spiegel zeigt Dinge, die nicht zusammenpassen. Das kann anstrengend sein. Aber: In der Spannung zwischen Gegensätzen entsteht oft Neues!'}

${systemMirrors.isNotEmpty ? '''\n🪞 SYSTEM-SPIEGEL (Was dir gespiegelt wird)

${systemMirrors.map((s) => s.contains('Lebensweg-Jahres') ? '🔄 Lebensweg-Jahres-Resonanz – Dein GANZES Leben spiegelt sich in DIESEM Jahr! Was du im Großen bist, zeigt sich jetzt im Kleinen. Nutze diese Verstärkung!' : s.contains('Neuanfang/Abschluss') ? '🌓 Neuanfang/Abschluss-Spiegel – Du stehst an einer Schwelle! Altes endet, Neues beginnt. Der Spiegel zeigt dir beide Seiten gleichzeitig.' : s.contains('Veränderungs') ? '⚡ Veränderungs-Spiegel – Alles ist in Bewegung! Der Spiegel zeigt dir nicht, WER du bist, sondern WER DU WERDEN KANNST!' : s.contains('Namens-Frequenz') ? '🎵 Namens-Frequenz-Spiegel – Dein NAME schwingt mit deinem Leben. Die Buchstaben deines Namens sind wie Noten einer Melodie – und diese Melodie spielt JETZT!' : '⏰ Zeit-Zyklus-Spiegel – Die Zeit selbst ist dein Spiegel. Jedes Jahr, jeder Monat, jeder Tag zeigt dir einen anderen Aspekt von dir.').join('\n\n')}''' : ''}

${themeOverlays.isNotEmpty ? '''\n\n🎭 THEMEN-ÜBERLAGERUNGEN (Was gerade MEHRFACH erscheint)

${themeOverlays.map((t) => t.contains('Aufbau') ? '🌱 Aufbau & Manifestation – Du bist gerade im ERSCHAFFEN-Modus! Projekte starten, Fundamente legen, Samen säen. Was du JETZT tust, trägt Früchte!' : t.contains('Beziehung') ? '💖 Beziehung & Harmonie – Deine Aufmerksamkeit liegt auf VERBINDUNG. Menschen, Partnerschaften, Teamwork. Du lernst gerade das WIR-Gefühl!' : '🔍 Innenschau & Transformation – Du gehst nach INNEN. Meditation, Reflexion, Wandlung. Die Welt da draußen ist leiser, die Welt da drinnen lauter!').join('\n\n')}''' : ''}

${contradictions.isNotEmpty ? '''\n\n⚡ WIDERSPRÜCHE (Spannungsfelder)

${contradictions.map((c) => c.contains('Innenschau vs. Außenaktivität') ? '''💥 Innenschau vs. Außenaktivität

${profile.firstName}, dein Lebensweg sagt: "Geh nach innen!" Aber dein Jahr sagt: "Geh raus und TU was!" Das ist ein klassischer Konflikt.

WIE LÖSEN? Beides! Morgens Meditation, abends Action. Oder: Montag-Freitag Aktivität, Wochenende Stille. Oder: Innere Klarheit DURCH äußeres Tun. Es gibt viele Wege, diese Pole zu versöhnen.''' : '''💥 Handlung vs. Kontemplation

Dein Lebensweg will HANDELN, aber dein Jahr will NACHDENKEN. Auch das ist ok! Vielleicht ist gerade die Zeit, deine Pläne zu überdenken, bevor du sie umsetzt. Oder: Handle bewusster, reflektiere zwischen den Schritten.''').join('\n\n')}

Die Spannung zwischen diesen Polen ist NICHT dein Feind – sie ist deine KRAFT! Wie ein Bogen, der gespannt wird, um den Pfeil weit fliegen zu lassen.''' : '''\n\n✨ KEINE WIDERSPRÜCHE

Alles ist harmonisch ausgerichtet! Dein Lebensweg und dein Jahr singen dieselbe Melodie. Das ist selten und wertvoll. Genieße diesen Flow, ${profile.firstName}!'''}

${amplifiedThemes.isNotEmpty ? '''\n\n🔊 VERSTÄRKTE THEMEN (Das wird gerade LAUTER!)

${amplifiedThemes.map((a) => a.contains('Lebensweg') ? '📢 Lebensweg-Verstärkung – Alles, wofür du HIER bist, wird gerade massiv verstärkt! Deine Lebensaufgabe ruft LAUT. Höre hin! Jetzt ist die Zeit, deiner Bestimmung zu folgen!' : '⭐ Meisterzahl-Resonanz – Du schwingst auf einer Meisterzahl-Frequenz (11, 22 oder 33)! Das bedeutet: Erhöhte Sensibilität, erhöhtes Potenzial. Du bist ein spiritueller Verstärker!').join('\n\n')}''' : ''}

💝 PERSÖNLICHE BOTSCHAFT

${profile.firstName}, Spiegel lügen nicht. Aber sie zeigen auch nicht die GANZE Wahrheit – nur einen Ausschnitt, einen Winkel, einen Moment.

Was du in den Spiegeln deines Lebens siehst – in Menschen, Situationen, Herausforderungen – ist immer auch ein Teil von DIR. Die Welt ist dein Spiegel.

${mirrorQuality == 'Verzerrt' ? 'Deine Spiegel sind gerade verzerrt? Das ist OK! Manchmal müssen Spiegel brechen, damit wir neu sehen lernen.' : mirrorQuality == 'Mehrdeutig' ? 'Deine Spiegel zeigen mehrere Bilder? Gut! Die Wahrheit hat viele Gesichter. Umarme die Mehrdeutigkeit!' : 'Deine Spiegel sind klar? Perfekt! Nutze diese Klarheit, um tief zu schauen – nicht nur an die Oberfläche!'}

Denk daran: DU bist nicht der Spiegel. DU bist der, der HINSCHAUT. Und das macht den ganzen Unterschied. 🪞✨''';

    return MetaMirrorToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      systemMirrors: systemMirrors,
      themeOverlays: themeOverlays,
      contradictions: contradictions,
      resonanceStrength: resonanceStrength,
      focusIndicator: focusIndicator,
      amplifiedThemes: amplifiedThemes,
      mirrorQuality: mirrorQuality,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 9: WAHRNEHMUNGS-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static PerceptionToolResult calculatePerception(EnergieProfile profile) {
    final now = DateTime.now();
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);

    // 3 Stufen der spirituellen Wahrnehmung
    final stageMap = [
      'Purgative (Reinigung)',
      'Illuminative (Erleuchtung)',
      'Unitive (Einheit)'
    ];
    final perceptionStage = age <= 30
        ? 1
        : age <= 50
            ? 2
            : 3;
    final stageName = stageMap[perceptionStage - 1];

    // Aktive Filter
    final activeFilters = <String>[
      if (perceptionStage == 1) 'Dualität-Filter',
      if (perceptionStage == 2) 'Perspektiven-Filter',
      if (perceptionStage == 3) 'Einheits-Filter',
      if (personalYear <= 3) 'Manifestations-Filter',
      if (personalYear >= 7) 'Transzendenz-Filter',
    ];

    // Interpretations-Muster
    final interpretationPatterns = <String>[
      if (perceptionStage == 1) 'Richtig vs. Falsch',
      if (perceptionStage == 2) 'Sowohl-als-auch',
      if (perceptionStage == 3) 'Alles ist Eins',
      if (personalYear == 5) 'Veränderung als Chance',
    ];

    // Einordnung
    final flexibilityDegree =
        ((perceptionStage / 3) * 70 + (personalYear / 9) * 30)
            .clamp(0.0, 100.0);
    final fixationPoints = <String>[
      if (perceptionStage == 1) 'Schwarz-Weiß-Denken',
      if (personalYear == 4) 'Ordnungs-Fixierung',
      if (flexibilityDegree < 40) 'Starre Muster',
    ];
    final perspectiveRange = flexibilityDegree >= 70
        ? 'Weit'
        : flexibilityDegree >= 40
            ? 'Mittel'
            : 'Eng';

    // Interpretation (persönlich & detailliert)
    final interpretation =
        '''${profile.firstName}, die Welt, die du siehst, ist NICHT die Welt, wie sie IST – sie ist die Welt, wie DU sie siehst. Lass uns deine Brille untersuchen:

👁️ DEINE WAHRNEHMUNGS-STUFE: "$stageName" ($perceptionStage/3)

${perceptionStage == 1 ? '''🔥 PURGATIVE PHASE – Schwarz-Weiß-Denken

Du siehst die Welt in klaren Kategorien: Gut oder Böse. Richtig oder Falsch. Freund oder Feind. Alles hat seinen Platz, alles ist eindeutig.

Das gibt Sicherheit! In chaotischen Zeiten ist Klarheit Gold wert. Aber: Die Welt IST nicht schwarz-weiß. Sie ist voller Farben, Grautöne, Schattierungen.

Deine Aufgabe jetzt: Beginne, FRAGEN zu stellen statt Antworten zu haben. "Was wäre, wenn...?" ist dein neuer Freund!''' : perceptionStage == 2 ? '''💡 ILLUMINATIVE PHASE – Grautöne & Zusammenhänge

Du siehst jetzt: Die Wahrheit hat viele Gesichter! Was gestern noch klar schien, zeigt heute Nuancen. Menschen sind nicht "gut" ODER "böse" – sie sind beides. Situationen sind nicht "richtig" ODER "falsch" – sie sind kontextabhängig.

Willkommen in der Welt der Komplexität, ${profile.firstName}! Das kann überwältigend sein. So viele Perspektiven! So viele Möglichkeiten!

Aber du lernst gerade eine der wichtigsten Fähigkeiten: SOWOHL-ALS-AUCH statt ENTWEDER-ODER zu denken.''' : '''🌟 UNITIVE PHASE – Alles ist Eins

WOW, ${profile.firstName}! Du hast die höchste Wahrnehmungsstufe erreicht!

Hier gibt es keine Trennung mehr. Du siehst: Alles ist miteinander verbunden. Du und ich? Eins. Innen und Außen? Eins. Problem und Lösung? Eins.

Das ist die Sicht der Mystiker, der Weisen, der Erwachten. Hier löst sich das "Ich" auf ins "Wir" – ins "Alles".

Deine Herausforderung jetzt: Wie lebst du diese Einsicht im Alltag? Wie bleibst du funktionsfähig in einer Welt, die noch in Trennungen denkt?'''}

🎯 DEINE WAHRNEHMUNGS-PARAMETER

Flexibilität: ${flexibilityDegree.toStringAsFixed(0)}% ${flexibilityDegree >= 70 ? '– SEHR FLEXIBEL! Du kannst zwischen Perspektiven wechseln wie andere die Schuhe. Das ist eine Superkraft!' : flexibilityDegree >= 40 ? '– MODERAT FLEXIBEL. Du kannst umdenken, auch wenn es manchmal Anstrengung kostet.' : '– EHER STARR. Du hältst fest an deinen Sichtweisen. Das gibt Stabilität, kann aber auch blind machen.'}

Perspektiven-Reichweite: $perspectiveRange ${perspectiveRange == 'Weit' ? '🌍 Du siehst das GROSSE GANZE! Details können dich manchmal überwältigen, aber das Panorama ist atemberaubend!' : perspectiveRange == 'Mittel' ? '🏞️ Du balancierst zwischen Details und Gesamtbild. Ein gesundes Maß!' : '🔍 Du fokussierst dich auf Details. Das macht dich präzise, kann aber den Blick fürs Ganze verdecken.'}

${activeFilters.isNotEmpty ? '''\n🔍 DEINE AKTIVEN FILTER (Wie du die Welt siehst)

${activeFilters.map((f) => f.contains('Dualität') ? '⚫⚪ Dualitäts-Filter – Du siehst Gegensätze. Licht/Schatten, Gut/Böse, Ich/Du. Dieser Filter ist simpel, aber effektiv!' : f.contains('Perspektiven') ? '🎭 Perspektiven-Filter – Du siehst: Es gibt VIELE Wahrheiten! Jeder hat recht – aus seiner Sicht. Das macht dich tolerant, aber manchmal unsicher.' : f.contains('Einheits') ? '☀️ Einheits-Filter – Du siehst die Verbundenheit von allem. Trennung ist Illusion. Das ist weise, aber im Alltag manchmal unpraktisch!' : f.contains('Manifestations') ? '🌱 Manifestations-Filter – Du siehst, wie Gedanken zu Realität werden. Was du denkst, erschaffst du!' : '🔮 Transzendenz-Filter – Du siehst HINTER die Dinge. Die sichtbare Welt ist nur die Oberfläche!').join('\n\n')}''' : ''}

${interpretationPatterns.isNotEmpty ? '''\n\n🧠 DEINE INTERPRETATIONS-MUSTER

${interpretationPatterns.map((p) => p.contains('Richtig vs. Falsch') ? '⚖️ Richtig vs. Falsch – Du bewertest ständig. Das gibt Orientierung, kann aber auch verurteilen.' : p.contains('Sowohl-als-auch') ? '🌈 Sowohl-als-auch – Du siehst beide Seiten! Das ist weise, kann aber auch zu Unentschlossenheit führen.' : p.contains('Alles ist Eins') ? '✨ Alles ist Eins – Du siehst die Einheit hinter der Vielfalt. Respekt!' : '🌀 Veränderung als Chance – Du siehst in Problemen Möglichkeiten. Das ist optimistisch UND realistisch!').join('\n')}''' : ''}

${fixationPoints.isNotEmpty ? '''\n\n📌 FIXIERUNGSPUNKTE (Wo du festhängst)

${fixationPoints.map((f) => f.contains('Schwarz-Weiß') ? '⚫ Schwarz-Weiß-Denken – ${profile.firstName}, die Welt hat FARBEN! Lass ein bisschen Grau rein. Nur ein bisschen!' : f.contains('Ordnungs') ? '📋 Ordnungs-Fixierung – Nicht alles MUSS geordnet sein. Manchmal ist Chaos kreativ!' : '🔒 Starre Muster – Du hältst fest an alten Denkweisen. Das gibt Sicherheit, verhindert aber Wachstum!').join('\n\n')}\n\n⚠️ WICHTIG: Fixierungen sind nicht "schlecht" – sie zeigen nur, wo du wachsen KANNST. Sei sanft mit dir!''' : '''\n\n✨ KEINE FIXIERUNGEN

Beeindruckend! Du bewegst dich flexibel zwischen verschiedenen Sichtweisen. Das ist selten und wertvoll!'''}

💝 PERSÖNLICHE BOTSCHAFT

${profile.firstName}, hier ist die Wahrheit: Die Welt, die du siehst, ist DEINE Schöpfung. Nicht die Fakten ändern sich – deine FILTER ändern sich.

Zwei Menschen können dasselbe erleben und völlig Unterschiedliches sehen. Warum? Verschiedene Filter!

${flexibilityDegree >= 70 ? 'Du hast das Glück, flexibel zu sein. Nutze das! Du kannst die Welt aus vielen Blickwinkeln sehen. Das ist wie ein Superpower!' : flexibilityDegree >= 40 ? 'Du bist moderat flexibel – ein guter Mittelweg! Du kannst umdenken, ohne orientierungslos zu werden.' : 'Du bist eher starr in deinen Sichtweisen. Das ist ok! Stabilität hat Wert. Aber: Versuche EINEN neuen Blickwinkel pro Woche. Nur einen. Schau, was passiert!'}

Denk dran: Wenn du die Welt anders SIEHST, wird sie anders SEIN. So einfach. So schwer. So wunderbar. 👁️✨''';

    return PerceptionToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      perceptionStage: perceptionStage,
      stageName: stageName,
      activeFilters: activeFilters,
      interpretationPatterns: interpretationPatterns,
      flexibilityDegree: flexibilityDegree,
      fixationPoints: fixationPoints,
      perspectiveRange: perspectiveRange,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TOOL 10: SELBSTBEOBACHTUNGS-ANALYSE
  // ═══════════════════════════════════════════════════════════════
  static SelfObservationToolResult calculateSelfObservation(
      EnergieProfile profile) {
    final now = DateTime.now();
    final age = DateTime.now().year - profile.birthDate.year;
    final personalYear = _calculatePersonalYear(profile.birthDate);

    // Simulierte Journal-Einträge (basierend auf Profil)
    final patternLog = <String>[
      'Wiederkehrendes Thema: Neuanfang (Persönliches Jahr $personalYear)',
      'Beobachtung: Zyklische Muster alle 7 Jahre',
      if (age % 7 == 0) 'Schwellen-Erfahrung: 7-Jahres-Marke',
    ];

    final cycleNotes = <String>[
      '7-Jahres-Zyklus: Jahr ${(age % 7) + 1}',
      'Saturn-Phase: ${age < 28 ? "Vor-Return" : age >= 28 && age <= 30 ? "Erster Return" : "Zwischen Returns"}',
    ];

    final symbolTracker = <String>[
      'Lebenszahl: ${_calculateLifePath(profile.birthDate)}',
      'Seelenzahl: ${_calculateSoulNumber(profile.firstName, profile.lastName)}',
      if (personalYear == 11 || personalYear == 22 || personalYear == 33)
        'Meisterzahl-Jahr',
    ];

    final totalEntries =
        patternLog.length + cycleNotes.length + symbolTracker.length;

    // Einordnung
    final observationQuality = totalEntries >= 10
        ? 'Tiefgehend'
        : totalEntries >= 5
            ? 'Differenziert'
            : 'Oberflächlich';
    final metacognitiveLevel = ((totalEntries / 15) * 100).clamp(0.0, 100.0);
    final trackingFocus = <String>[
      if (personalYear <= 3) 'Manifestation & Aufbau',
      if (personalYear >= 4 && personalYear <= 6) 'Beziehungen & Harmonie',
      if (personalYear >= 7) 'Innenschau & Transformation',
    ];

    // Interpretation (persönlich & detailliert)
    final interpretation =
        '''${profile.firstName}, du beobachtest dich selbst – und das ist schon der Anfang aller Weisheit. Lass uns schauen, WIE du beobachtest:

📖 DEIN SELBSTBEOBACHTUNGS-PROFIL

Gesamt-Einträge: $totalEntries
Meta-kognitives Level: ${metacognitiveLevel.toStringAsFixed(0)}% ${metacognitiveLevel >= 70 ? '– SEHR HOCH! Du denkst über dein Denken nach. Du beobachtest deine Beobachtungen. Das ist Meta-Bewusstsein!' : metacognitiveLevel >= 40 ? '– SOLIDE. Du reflektierst regelmäßig. Das ist mehr, als die meisten tun!' : '– BEGINNEND. Du fängst gerade an, dich selbst zu beobachten. Jeder Meister war mal Anfänger!'}

Beobachtungs-Qualität: $observationQuality ${observationQuality == 'Tiefgehend' ? '🔍 Du schaust unter die Oberfläche! Du siehst nicht nur WAS passiert, sondern WARUM. Das ist echte Selbsterkenntnis!' : observationQuality == 'Differenziert' ? '🎭 Du siehst Nuancen! Nicht nur schwarz-weiß, sondern auch Grautöne. Gut!' : '🌊 Du kratzt an der Oberfläche. Das ist ok für den Anfang! Tiefe kommt mit der Zeit.'}

${patternLog.isNotEmpty ? '''\n📝 MUSTER-LOG (${patternLog.length} Beobachtungen)

${patternLog.map((p) => p.contains('Wiederkehrend') ? '🔄 $p – Siehst du es, ${profile.firstName}? Es kommt IMMER WIEDER! Das ist kein Zufall. Das ist ein MUSTER. Und Muster zeigen dir, woran du arbeiten sollst!' : p.contains('Beobachtung') ? '👁️ $p – Du SCHAUST hin. Das allein ist schon heilsam!' : '🔎 $p').join('\n\n')}\n\n💡 Je mehr Muster du erkennst, desto mehr Macht hast du über sie. Unbewusste Muster kontrollieren DICH. Bewusste Muster kannst DU kontrollieren!''' : ''}

${cycleNotes.isNotEmpty ? '''\n\n🔄 ZYKLUS-NOTIZEN (${cycleNotes.length} Einträge)

${cycleNotes.map((c) => c.contains('7-Jahres') ? '⏰ $c – Der große Rhythmus! Alle 7 Jahre veränderst du dich fundamental. Wo stehst du gerade?' : c.contains('Saturn') ? '🪐 $c – Saturn ist der Lehrmeister der Zeit. Er zeigt dir, was wirklich wichtig ist!' : '📅 $c').join('\n')}\n\n⏳ Zyklen sind wie Atemzüge des Universums. Einatmen (aufbauen), Ausatmen (loslassen), Pause (integrieren). Du kannst MIT dem Rhythmus tanzen – oder dagegen kämpfen. Rate mal, was leichter ist?''' : ''}

${symbolTracker.isNotEmpty ? '''\n\n🔢 SYMBOL-TRACKER (${symbolTracker.length} Symbole)

${symbolTracker.map((s) => s.contains('Lebenszahl') ? '🎯 $s – Deine Essenz in einer Zahl! Was bedeutet sie für dich?' : s.contains('Seelenzahl') ? '💖 $s – Die Zahl deiner inneren Sehnsucht!' : s.contains('Meisterzahl') ? '⭐ $s – Du trägst eine Meisterzahl! Das ist Potenzial UND Herausforderung!' : '🔣 $s').join('\n')}\n\n🎭 Symbole sind die Sprache der Seele. Zahlen, Träume, Synchronizitäten – sie alle sprechen zu dir. Du musst nur zuhören!''' : ''}

${trackingFocus.isNotEmpty ? '''\n\n🎯 DEIN TRACKING-FOKUS

${trackingFocus.map((t) => t.contains('Manifestation') ? '🌱 Manifestation & Aufbau – Du beobachtest, wie deine Gedanken zu Realität werden. Das ist Schöpferkraft!' : t.contains('Beziehungen') ? '💕 Beziehungen & Harmonie – Du achtest auf Verbindungen. Menschen sind dein Spiegel!' : '🔍 Innenschau & Transformation – Du gehst nach innen. Die äußere Welt ist leise, die innere laut!').join('\n\n')}''' : ''}

💝 PERSÖNLICHE BOTSCHAFT

${profile.firstName}, weist du, was der Unterschied ist zwischen Menschen, die sich entwickeln, und denen, die stagnieren?

SELBSTBEOBACHTUNG.

Du tust gerade genau das Richtige: Du schaust hin. Du notierst. Du reflektierst. Das ist wie ein Spiegel für deine Seele.

${totalEntries >= 10 ? 'Mit $totalEntries Einträgen hast du schon eine solide Basis! Je länger du beobachtest, desto klarer werden die Muster. Mach weiter!' : 'Du hast $totalEntries Einträge – das ist ein Anfang! Versuche, regelmäßig zu journalen. Selbst 5 Minuten am Tag verändern alles!'}

Denk daran: Was du beobachtest, verändert sich. Das ist Quantenphysik UND Spiritualität. Deine Aufmerksamkeit ist MACHT.

Beobachte weiter. Verstehe tiefer. Transformiere dich selbst. 📖✨''';

    return SelfObservationToolResult(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      patternLog: patternLog,
      cycleNotes: cycleNotes,
      symbolTracker: symbolTracker,
      totalEntries: totalEntries,
      observationQuality: observationQuality,
      metacognitiveLevel: metacognitiveLevel,
      trackingFocus: trackingFocus,
      interpretation: interpretation,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HILFS-FUNKTIONEN
  // ═══════════════════════════════════════════════════════════════
  static int _calculateLifePath(DateTime birthDate) {
    final day = birthDate.day;
    final month = birthDate.month;
    final year = birthDate.year;
    final sum = _reduceToSingleDigit(day) +
        _reduceToSingleDigit(month) +
        _reduceToSingleDigit(year);
    return _reduceToSingleDigit(sum);
  }

  static int _calculateSoulNumber(String firstName, String lastName) {
    final fullName = '$firstName $lastName';
    final vowels =
        fullName.toLowerCase().split('').where((c) => 'aeiouäöü'.contains(c));
    final sum = vowels.map((c) => _letterValue(c)).reduce((a, b) => a + b);
    return _reduceToSingleDigit(sum);
  }

  static int _calculateExpression(String firstName, String lastName) {
    final fullName = '$firstName $lastName';
    final letters = fullName
        .toLowerCase()
        .split('')
        .where((c) => RegExp(r'[a-zäöüß]').hasMatch(c));
    final sum = letters.map((c) => _letterValue(c)).reduce((a, b) => a + b);
    return _reduceToSingleDigit(sum);
  }

  static int _calculatePersonalYear(DateTime birthDate) {
    final now = DateTime.now();
    final day = birthDate.day;
    final month = birthDate.month;
    final year = now.year;
    final sum = _reduceToSingleDigit(day) +
        _reduceToSingleDigit(month) +
        _reduceToSingleDigit(year);
    return _reduceToSingleDigit(sum);
  }

  static int _reduceToSingleDigit(int number) {
    while (number > 9 && number != 11 && number != 22 && number != 33) {
      number =
          number.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return number;
  }

  static int _letterValue(String letter) {
    const values = {
      'a': 1,
      'b': 2,
      'c': 3,
      'd': 4,
      'e': 5,
      'f': 6,
      'g': 7,
      'h': 8,
      'i': 9,
      'j': 1,
      'k': 2,
      'l': 3,
      'm': 4,
      'n': 5,
      'o': 6,
      'p': 7,
      'q': 8,
      'r': 9,
      's': 1,
      't': 2,
      'u': 3,
      'v': 4,
      'w': 5,
      'x': 6,
      'y': 7,
      'z': 8,
      'ä': 1,
      'ö': 6,
      'ü': 3,
      'ß': 1,
    };
    return values[letter.toLowerCase()] ?? 0;
  }
}
