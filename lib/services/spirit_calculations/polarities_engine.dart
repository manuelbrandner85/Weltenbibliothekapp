/// ⚖️ POLARITIES ENGINE
/// 
/// Berechnet alle Polaritäten und Ausgleichsmodelle basierend auf:
/// - Numerologischen Daten (Lebenszahl, Seelenzahl, etc.)
/// - Geburtsdatum und aktuelles Datum
/// - Name (Gematria-Werte)
library;

import 'dart:math';
import '../../models/energie_profile.dart';
import '../../models/spirit_polarities.dart';

class PolaritiesEngine {
  static const String version = '1.0.0';

  /// Hauptfunktion: Berechnet alle Polaritäten
  static SpiritPolarities calculatePolarities(EnergieProfile profile) {
    final now = DateTime.now();

    // Numerologische Basis-Berechnungen
    final lifePathNumber = _calculateLifePathNumber(profile.birthDate);
    final soulNumber = _calculateSoulNumber(profile.firstName);
    final destinyNumber = _calculateDestinyNumber('${profile.firstName} ${profile.lastName}');
    final personalYear = _calculatePersonalYear(profile.birthDate, now);
    final personalMonth = _calculatePersonalMonth(profile.birthDate, now);
// UNUSED: final personalDay = _calculatePersonalDay(profile.birthDate, now);

    // Gematria-Werte
    final hebrewValue = _calculateHebrewGematria('${profile.firstName} ${profile.lastName}');
// UNUSED: final latinValue = _calculateLatinGematria('${profile.firstName} ${profile.lastName}');

    // Alter berechnen
    final age = now.year - profile.birthDate.year;

    return SpiritPolarities(
      version: version,
      calculatedAt: now,
      profileName: '${profile.firstName} ${profile.lastName}',
      activePassiveDominance: _calculateActivePassiveDominance(
        lifePathNumber,
        soulNumber,
        destinyNumber,
        personalYear,
      ),
      orderChaosAxis: _calculateOrderChaosAxis(
        lifePathNumber,
        destinyNumber,
        personalMonth,
        age,
      ),
      controlSurrenderBalance: _calculateControlSurrenderBalance(
        soulNumber,
        destinyNumber,
        personalYear,
        hebrewValue,
      ),
      expansionWithdrawal: _calculateExpansionWithdrawal(
        lifePathNumber,
        personalYear,
        personalMonth,
        age,
      ),
      innerTensionAxes: _calculateInnerTensionAxes(
        lifePathNumber,
        soulNumber,
        destinyNumber,
        personalYear,
      ),
      balanceStates: _calculateBalanceStates(
        lifePathNumber,
        soulNumber,
        destinyNumber,
        personalYear,
        personalMonth,
      ),
      oversteeringIndicators: _calculateOversteeringIndicators(
        lifePathNumber,
        soulNumber,
        destinyNumber,
        personalYear,
      ),
      integrationPoles: _calculateIntegrationPoles(
        lifePathNumber,
        soulNumber,
        destinyNumber,
        age,
      ),
    );
  }

  // ========================================
  // 1️⃣ AKTIV ↔ PASSIV DOMINANZ
  // ========================================

  static ActivePassiveDominance _calculateActivePassiveDominance(
    int lifePathNumber,
    int soulNumber,
    int destinyNumber,
    int personalYear,
  ) {
    // Aktiv: ungerade Zahlen (1,3,5,7,9)
    // Passiv: gerade Zahlen (2,4,6,8)

    int activeCount = 0;
    int passiveCount = 0;

    final numbers = [lifePathNumber, soulNumber, destinyNumber, personalYear];
    for (var num in numbers) {
      if (num % 2 == 1) {
        activeCount++;
      } else {
        passiveCount++;
      }
    }

    final activeScore = (activeCount / numbers.length) * 100;
    final passiveScore = (passiveCount / numbers.length) * 100;
    final balanceRatio = activeScore / max(passiveScore, 1);

    String dominantPole;
    if (balanceRatio > 1.5) {
      dominantPole = 'Aktiv';
    } else if (balanceRatio < 0.67) {
      dominantPole = 'Passiv';
    } else {
      dominantPole = 'Ausgeglichen';
    }

    String currentPhase;
    if (personalYear % 2 == 1) {
      currentPhase = 'Aktiv-Phase';
    } else {
      currentPhase = 'Passiv-Phase';
    }

    final activeIndicators = <String>[];
    final passiveIndicators = <String>[];

    if (lifePathNumber % 2 == 1) {
      activeIndicators.add('Lebensweg ist aktiv geprägt');
    } else {
      passiveIndicators.add('Lebensweg ist passiv empfangend');
    }

    if (soulNumber % 2 == 1) {
      activeIndicators.add('Seele strebt nach Aktion');
    } else {
      passiveIndicators.add('Seele sucht Empfangen');
    }

    String interpretation;
    if (dominantPole == 'Aktiv') {
      interpretation = 'Du bist von Natur aus eine treibende Kraft. '
          'Deine Energie fließt nach außen, du initiierst, gestaltest, bewegst. '
          'Achte darauf, auch Phasen des Empfangens zuzulassen – '
          'nicht alles muss von dir selbst geschaffen werden.';
    } else if (dominantPole == 'Passiv') {
      interpretation = 'Du bist von Natur aus empfangend und integrierend. '
          'Deine Kraft liegt im Aufnehmen, Verarbeiten, Reifen-Lassen. '
          'Erlaube dir auch, selbst zu initiieren – '
          'du musst nicht immer nur reagieren.';
    } else {
      interpretation = 'Du lebst eine ausgeglichene Polarität zwischen '
          'Aktion und Empfangen. Du weißt, wann du vorangehen und '
          'wann du dich zurücklehnen solltest. Diese Balance ist selten.';
    }

    return ActivePassiveDominance(
      activeScore: activeScore,
      passiveScore: passiveScore,
      dominantPole: dominantPole,
      balanceRatio: balanceRatio,
      currentPhase: currentPhase,
      activeIndicators: activeIndicators,
      passiveIndicators: passiveIndicators,
      interpretation: interpretation,
    );
  }

  // ========================================
  // 2️⃣ ORDNUNG ↔ CHAOS ACHSE
  // ========================================

  static OrderChaosAxis _calculateOrderChaosAxis(
    int lifePathNumber,
    int destinyNumber,
    int personalMonth,
    int age,
  ) {
    // Ordnung: 2,4,6,8 + Lebenszahlen 22
    // Chaos: 1,3,5,7,9

    double orderScore = 0;
    double chaosScore = 0;

    if (lifePathNumber % 2 == 0 || lifePathNumber == 22) {
      orderScore += 40;
    } else {
      chaosScore += 40;
    }

    if (destinyNumber % 2 == 0) {
      orderScore += 30;
    } else {
      chaosScore += 30;
    }

    if (personalMonth % 2 == 0) {
      orderScore += 30;
    } else {
      chaosScore += 30;
    }

    final total = orderScore + chaosScore;
    orderScore = (orderScore / total) * 100;
    chaosScore = (chaosScore / total) * 100;

    String dominantPole;
    if (orderScore > 60) {
      dominantPole = 'Ordnung';
    } else if (chaosScore > 60) {
      dominantPole = 'Chaos';
    } else {
      dominantPole = 'Dynamisches Gleichgewicht';
    }

    final stabilityLevel = orderScore;
    final chaosCreativity = chaosScore;

    final orderPatterns = <String>[];
    final chaosPatterns = <String>[];

    if (lifePathNumber % 2 == 0) {
      orderPatterns.add('Strukturierter Lebensweg');
    } else {
      chaosPatterns.add('Freier, improvisierender Lebensweg');
    }

    if (destinyNumber % 2 == 0) {
      orderPatterns.add('Klare Schicksals-Architektur');
    } else {
      chaosPatterns.add('Offene Schicksals-Gestaltung');
    }

    String currentNeed;
    if (orderScore > 70) {
      currentNeed = 'Mehr Freiheit und Spontaneität';
    } else if (chaosScore > 70) {
      currentNeed = 'Mehr Struktur und Halt';
    } else {
      currentNeed = 'Die aktuelle Balance passt';
    }

    String interpretation;
    if (dominantPole == 'Ordnung') {
      interpretation = 'Ordnung ist dein natürlicher Zustand. '
          'Du schaffst Strukturen, hältst Rahmen ein, liebst Klarheit. '
          'Vergiss nicht: Chaos ist nicht der Feind – '
          'manchmal ist es die Geburtsstätte des Neuen.';
    } else if (dominantPole == 'Chaos') {
      interpretation = 'Chaos ist dein kreativer Raum. '
          'Du liebst Freiheit, Spontaneität, das Unvorhersehbare. '
          'Doch auch im Chaos braucht es kleine Inseln der Ordnung – '
          'sie geben dir Halt, wenn das Chaos überwältigt.';
    } else {
      interpretation = 'Du tanzt zwischen Ordnung und Chaos. '
          'Du kannst Strukturen schaffen UND sie loslassen. '
          'Diese Flexibilität macht dich anpassungsfähig und kreativ zugleich.';
    }

    return OrderChaosAxis(
      orderScore: orderScore,
      chaosScore: chaosScore,
      dominantPole: dominantPole,
      stabilityLevel: stabilityLevel,
      chaosCreativity: chaosCreativity,
      orderPatterns: orderPatterns,
      chaosPatterns: chaosPatterns,
      currentNeed: currentNeed,
      interpretation: interpretation,
    );
  }

  // ========================================
  // 3️⃣ KONTROLLE ↔ HINGABE
  // ========================================

  static ControlSurrenderBalance _calculateControlSurrenderBalance(
    int soulNumber,
    int destinyNumber,
    int personalYear,
    int hebrewValue,
  ) {
    // Kontrolle: 1,4,8
    // Hingabe: 2,5,7,9
    // Neutral: 3,6

    double controlScore = 0;
    double surrenderScore = 0;

    final controlNumbers = [1, 4, 8];
    final surrenderNumbers = [2, 5, 7, 9];

    if (controlNumbers.contains(soulNumber)) {
      controlScore += 35;
    } else if (surrenderNumbers.contains(soulNumber)) {
      surrenderScore += 35;
    } else {
      controlScore += 17.5;
      surrenderScore += 17.5;
    }

    if (controlNumbers.contains(destinyNumber)) {
      controlScore += 35;
    } else if (surrenderNumbers.contains(destinyNumber)) {
      surrenderScore += 35;
    } else {
      controlScore += 17.5;
      surrenderScore += 17.5;
    }

    if (controlNumbers.contains(personalYear)) {
      controlScore += 30;
    } else if (surrenderNumbers.contains(personalYear)) {
      surrenderScore += 30;
    } else {
      controlScore += 15;
      surrenderScore += 15;
    }

    final total = controlScore + surrenderScore;
    controlScore = (controlScore / total) * 100;
    surrenderScore = (surrenderScore / total) * 100;

    String dominantMode;
    if (controlScore > 60) {
      dominantMode = 'Kontrolle';
    } else if (surrenderScore > 60) {
      dominantMode = 'Hingabe';
    } else {
      dominantMode = 'Flexibel';
    }

    final trustLevel = surrenderScore;
    final fearOfLoss = controlScore;

    final controlAreas = <String>[];
    final surrenderAreas = <String>[];

    if (controlNumbers.contains(soulNumber)) {
      controlAreas.add('Emotionale Kontrolle');
    } else if (surrenderNumbers.contains(soulNumber)) {
      surrenderAreas.add('Emotionales Vertrauen');
    }

    if (controlNumbers.contains(destinyNumber)) {
      controlAreas.add('Schicksals-Steuerung');
    } else if (surrenderNumbers.contains(destinyNumber)) {
      surrenderAreas.add('Schicksals-Hingabe');
    }

    String currentLesson;
    if (dominantMode == 'Kontrolle') {
      currentLesson = 'Lerne, loszulassen ohne zu fallen';
    } else if (dominantMode == 'Hingabe') {
      currentLesson = 'Lerne, zu steuern ohne zu verkrampfen';
    } else {
      currentLesson = 'Verfeinere deine Balance zwischen Steuerung und Vertrauen';
    }

    String interpretation;
    if (dominantMode == 'Kontrolle') {
      interpretation = 'Du hältst die Zügel fest in der Hand. '
          'Kontrolle gibt dir Sicherheit, doch sie kann auch einengen. '
          'Die tiefste Lektion: Manchmal ist Loslassen die höchste Form der Meisterschaft.';
    } else if (dominantMode == 'Hingabe') {
      interpretation = 'Du vertraust dem Fluss des Lebens. '
          'Hingabe ist deine Superkraft – doch sie darf nicht zu Passivität werden. '
          'Auch im Vertrauen darfst du deine Intention setzen.';
    } else {
      interpretation = 'Du bist flexibel zwischen Kontrolle und Hingabe. '
          'Du weißt, wann du steuern und wann du vertrauen solltest. '
          'Diese Weisheit ist selten – nutze sie bewusst.';
    }

    return ControlSurrenderBalance(
      controlScore: controlScore,
      surrenderScore: surrenderScore,
      dominantMode: dominantMode,
      trustLevel: trustLevel,
      fearOfLoss: fearOfLoss,
      controlAreas: controlAreas,
      surrenderAreas: surrenderAreas,
      currentLesson: currentLesson,
      interpretation: interpretation,
    );
  }

  // ========================================
  // 4️⃣ EXPANSION ↔ RÜCKZUG
  // ========================================

  static ExpansionWithdrawal _calculateExpansionWithdrawal(
    int lifePathNumber,
    int personalYear,
    int personalMonth,
    int age,
  ) {
    // Expansion: 1,3,5,9
    // Rückzug: 2,4,7,8
    // Neutral: 6

    double expansionScore = 0;
    double withdrawalScore = 0;

    final expansionNumbers = [1, 3, 5, 9];
    final withdrawalNumbers = [2, 4, 7, 8];

    if (expansionNumbers.contains(lifePathNumber)) {
      expansionScore += 40;
    } else if (withdrawalNumbers.contains(lifePathNumber)) {
      withdrawalScore += 40;
    } else {
      expansionScore += 20;
      withdrawalScore += 20;
    }

    if (expansionNumbers.contains(personalYear)) {
      expansionScore += 35;
    } else if (withdrawalNumbers.contains(personalYear)) {
      withdrawalScore += 35;
    } else {
      expansionScore += 17.5;
      withdrawalScore += 17.5;
    }

    if (expansionNumbers.contains(personalMonth)) {
      expansionScore += 25;
    } else if (withdrawalNumbers.contains(personalMonth)) {
      withdrawalScore += 25;
    } else {
      expansionScore += 12.5;
      withdrawalScore += 12.5;
    }

    final total = expansionScore + withdrawalScore;
    expansionScore = (expansionScore / total) * 100;
    withdrawalScore = (withdrawalScore / total) * 100;

    String currentDirection;
    if (expansionScore > 60) {
      currentDirection = 'Expansion';
    } else if (withdrawalScore > 60) {
      currentDirection = 'Rückzug';
    } else {
      currentDirection = 'Pendel';
    }

    final energyFlow = expansionScore - withdrawalScore; // -100 bis +100

    final expansionAreas = <String>[];
    final withdrawalAreas = <String>[];

    if (expansionNumbers.contains(lifePathNumber)) {
      expansionAreas.add('Grundsätzlich nach außen gerichtet');
    } else if (withdrawalNumbers.contains(lifePathNumber)) {
      withdrawalAreas.add('Grundsätzlich nach innen gerichtet');
    }

    if (expansionNumbers.contains(personalYear)) {
      expansionAreas.add('Aktuelles Jahr fordert Expansion');
    } else if (withdrawalNumbers.contains(personalYear)) {
      withdrawalAreas.add('Aktuelles Jahr fordert Rückzug');
    }

    final cyclicPattern = 'Alle 9 Jahre wechselt deine Energie zwischen '
        'maximaler Expansion (Jahr 1,5,9) und tiefem Rückzug (Jahr 4,7,8).';

    String healthyBalance;
    if (currentDirection == 'Expansion') {
      healthyBalance = 'Plane bewusst Zeiten des Rückzugs ein – '
          'sonst brennst du aus.';
    } else if (currentDirection == 'Rückzug') {
      healthyBalance = 'Wage kleine Schritte nach außen – '
          'sonst isolierst du dich zu sehr.';
    } else {
      healthyBalance = 'Dein aktuelles Pendeln ist gesund – '
          'achte darauf, dass es rhythmisch bleibt.';
    }

    String interpretation;
    if (currentDirection == 'Expansion') {
      interpretation = 'Du bist in einer Phase des Wachstums nach außen. '
          'Die Welt ruft dich, und du antwortest. '
          'Doch vergiss nicht: Jede Expansion braucht Phasen der Integration. '
          'Sonst verzettelst du dich.';
    } else if (currentDirection == 'Rückzug') {
      interpretation = 'Du ziehst dich zurück, sammelst dich, gehst in die Tiefe. '
          'Das ist keine Schwäche, sondern Weisheit. '
          'Rückzug ist die Vorbereitung für die nächste Expansion. '
          'Ehre diese Phase.';
    } else {
      interpretation = 'Du pendelst zwischen Expansion und Rückzug. '
          'Mal bist du außen, mal innen. '
          'Dieses rhythmische Atmen ist gesund – '
          'solange du nicht im Pendel stecken bleibst.';
    }

    return ExpansionWithdrawal(
      expansionScore: expansionScore,
      withdrawalScore: withdrawalScore,
      currentDirection: currentDirection,
      energyFlow: energyFlow,
      expansionAreas: expansionAreas,
      withdrawalAreas: withdrawalAreas,
      cyclicPattern: cyclicPattern,
      healthyBalance: healthyBalance,
      interpretation: interpretation,
    );
  }

  // ========================================
  // 5️⃣ INNERE SPANNUNGSACHSEN
  // ========================================

  static InnerTensionAxes _calculateInnerTensionAxes(
    int lifePathNumber,
    int soulNumber,
    int destinyNumber,
    int personalYear,
  ) {
    final axes = <TensionAxis>[];

    // Achse 1: Wollen vs. Sollen
    final willingVsShould = ((lifePathNumber - destinyNumber).abs() / 9) * 100;
    axes.add(TensionAxis(
      name: 'Wollen ↔ Sollen',
      pole1: 'Was ich will (Lebensweg)',
      pole2: 'Was ich soll (Schicksal)',
      tensionLevel: willingVsShould,
      currentPull: lifePathNumber > destinyNumber
          ? 'Du tendierst zum WOLLEN'
          : 'Du tendierst zum SOLLEN',
    ));

    // Achse 2: Sein vs. Tun
    final beingVsDoing = ((soulNumber - personalYear).abs() / 9) * 100;
    axes.add(TensionAxis(
      name: 'Sein ↔ Tun',
      pole1: 'Wer ich bin (Seele)',
      pole2: 'Was ich tue (Jahr)',
      tensionLevel: beingVsDoing,
      currentPull: soulNumber > personalYear
          ? 'Du tendierst zum SEIN'
          : 'Du tendierst zum TUN',
    ));

    // Achse 3: Innen vs. Außen
    final innerVsOuter = ((soulNumber - destinyNumber).abs() / 9) * 100;
    axes.add(TensionAxis(
      name: 'Innen ↔ Außen',
      pole1: 'Innere Wahrheit (Seele)',
      pole2: 'Äußere Aufgabe (Schicksal)',
      tensionLevel: innerVsOuter,
      currentPull: soulNumber > destinyNumber
          ? 'Du tendierst nach INNEN'
          : 'Du tendierst nach AUSSEN',
    ));

    // Achse 4: Herz vs. Kopf
    final heartVsHead = ((soulNumber - lifePathNumber).abs() / 9) * 100;
    axes.add(TensionAxis(
      name: 'Herz ↔ Kopf',
      pole1: 'Gefühl (Seele)',
      pole2: 'Logik (Lebensweg)',
      tensionLevel: heartVsHead,
      currentPull: soulNumber > lifePathNumber
          ? 'Du tendierst zum HERZ'
          : 'Du tendierst zum KOPF',
    ));

    // Gesamtspannung berechnen
    final overallTension =
        axes.map((a) => a.tensionLevel).reduce((a, b) => a + b) / axes.length;

    // Höchste und niedrigste Spannung
    axes.sort((a, b) => b.tensionLevel.compareTo(a.tensionLevel));
    final highestTension = axes.first.name;
    final lowestTension = axes.last.name;

    final conflictAreas = <String>[];
    for (var axis in axes) {
      if (axis.tensionLevel > 50) {
        conflictAreas.add('${axis.name}: hohe Spannung');
      }
    }

    String resolutionPath;
    if (overallTension > 60) {
      resolutionPath = 'Deine inneren Spannungen sind hoch. '
          'Der Weg ist nicht, sie aufzulösen, sondern sie zu INTEGRIEREN. '
          'Beide Pole in dir sind wahr – finde einen Tanz zwischen ihnen.';
    } else if (overallTension < 30) {
      resolutionPath = 'Deine inneren Spannungen sind gering. '
          'Das kann Harmonie bedeuten – oder Vermeidung. '
          'Prüfe, ob du wirklich integriert bist, oder nur ruhig stellst.';
    } else {
      resolutionPath = 'Deine inneren Spannungen sind moderat. '
          'Du lebst in einem gesunden Spannungsfeld. '
          'Nutze diese Dynamik als kreative Kraft.';
    }

    String interpretation;
    if (overallTension > 60) {
      interpretation = 'In dir tobt ein Sturm. '
          'Verschiedene Teile von dir ziehen in verschiedene Richtungen. '
          'Das ist nicht falsch – es ist MENSCHLICH. '
          'Die Kunst ist, den Sturm nicht zu bekämpfen, sondern in ihm zu tanzen.';
    } else if (overallTension < 30) {
      interpretation = 'In dir herrscht Ruhe. '
          'Das kann tiefe Integration sein – oder tiefe Vermeidung. '
          'Prüfe ehrlich: Ist deine Ruhe Frieden, oder ist sie Stillstand?';
    } else {
      interpretation = 'In dir lebt eine gesunde Spannung. '
          'Du bist nicht zerrissen, aber auch nicht eingeschlafen. '
          'Diese Dynamik hält dich lebendig. Nutze sie.';
    }

    return InnerTensionAxes(
      axes: axes,
      overallTension: overallTension,
      highestTension: highestTension,
      lowestTension: lowestTension,
      conflictAreas: conflictAreas,
      resolutionPath: resolutionPath,
      interpretation: interpretation,
    );
  }

  // ========================================
  // 6️⃣ BALANCE-ZUSTÄNDE
  // ========================================

  static BalanceStates _calculateBalanceStates(
    int lifePathNumber,
    int soulNumber,
    int destinyNumber,
    int personalYear,
    int personalMonth,
  ) {
    // Balance-Berechnung für verschiedene Dimensionen
    final dimensionBalances = <String, double>{};

    // 1. Lebensweg-Balance (wie nah an der Mitte 4.5?)
    final lifePathBalance = 100 - ((lifePathNumber - 5).abs() / 5) * 100;
    dimensionBalances['Lebensweg'] = lifePathBalance;

    // 2. Seelen-Balance
    final soulBalance = 100 - ((soulNumber - 5).abs() / 5) * 100;
    dimensionBalances['Seele'] = soulBalance;

    // 3. Schicksals-Balance
    final destinyBalance = 100 - ((destinyNumber - 5).abs() / 5) * 100;
    dimensionBalances['Schicksal'] = destinyBalance;

    // 4. Zeit-Balance (aktuelles Jahr)
    final yearBalance = 100 - ((personalYear - 5).abs() / 5) * 100;
    dimensionBalances['Aktuelles Jahr'] = yearBalance;

    // 5. Monats-Balance
    final monthBalance = 100 - ((personalMonth - 5).abs() / 5) * 100;
    dimensionBalances['Aktueller Monat'] = monthBalance;

    // Gesamt-Balance
    final overallBalance = dimensionBalances.values.reduce((a, b) => a + b) /
        dimensionBalances.length;

    // Beste und schlechteste Balance
    final sortedBalances = dimensionBalances.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostBalanced = sortedBalances.first.key;
    final leastBalanced = sortedBalances.last.key;

    // Stärken und Schwächen
    final balanceStrengths = <String>[];
    final balanceWeaknesses = <String>[];

    for (var entry in dimensionBalances.entries) {
      if (entry.value > 70) {
        balanceStrengths.add('${entry.key} ist stark ausgeglichen');
      } else if (entry.value < 40) {
        balanceWeaknesses.add('${entry.key} ist unausgeglichen');
      }
    }

    // Balance-Typ
    String balanceType;
    final variance = _calculateVariance(dimensionBalances.values.toList());
    if (variance < 100) {
      balanceType = 'Statisch';
    } else if (variance > 500) {
      balanceType = 'Zyklisch';
    } else {
      balanceType = 'Dynamisch';
    }

    String interpretation;
    if (overallBalance > 70) {
      interpretation = 'Du lebst in einer bemerkenswerten Balance. '
          'Die meisten Aspekte deines Lebens sind harmonisch aufeinander abgestimmt. '
          'Achte darauf, dass diese Balance nicht zu Stillstand wird.';
    } else if (overallBalance < 40) {
      interpretation = 'Dein Leben ist aktuell unausgeglichen. '
          'Verschiedene Aspekte ziehen in verschiedene Richtungen. '
          'Das ist nicht falsch – es ist eine Phase der Transformation. '
          'Balance ist das Ziel, nicht der Ausgangspunkt.';
    } else {
      interpretation = 'Du lebst in einer dynamischen Balance. '
          'Nicht perfekt ausgeglichen, aber auch nicht chaotisch. '
          'Diese gesunde Spannung hält dich in Bewegung.';
    }

    return BalanceStates(
      overallBalance: overallBalance,
      dimensionBalances: dimensionBalances,
      mostBalanced: mostBalanced,
      leastBalanced: leastBalanced,
      balanceStrengths: balanceStrengths,
      balanceWeaknesses: balanceWeaknesses,
      balanceType: balanceType,
      interpretation: interpretation,
    );
  }

  // ========================================
  // 7️⃣ ÜBERSTEUERUNGSINDIKATOREN
  // ========================================

  static OversteeringIndicators _calculateOversteeringIndicators(
    int lifePathNumber,
    int soulNumber,
    int destinyNumber,
    int personalYear,
  ) {
    final areas = <OversteeringArea>[];

    // Übersteuerung 1: Zu viel Kontrolle (wenn 1,4,8 dominieren)
    final controlNumbers = [lifePathNumber, soulNumber, destinyNumber]
        .where((n) => [1, 4, 8].contains(n))
        .length;
    if (controlNumbers >= 2) {
      areas.add(OversteeringArea(
        name: 'Kontrolle',
        level: (controlNumbers / 3) * 100,
        direction: 'Zu viel',
        impact: 'Verkrampfung, Angst vor Kontrollverlust',
      ));
    }

    // Übersteuerung 2: Zu viel Chaos (wenn 3,5,9 dominieren)
    final chaosNumbers = [lifePathNumber, soulNumber, destinyNumber]
        .where((n) => [3, 5, 9].contains(n))
        .length;
    if (chaosNumbers >= 2) {
      areas.add(OversteeringArea(
        name: 'Chaos',
        level: (chaosNumbers / 3) * 100,
        direction: 'Zu viel',
        impact: 'Verzettelung, fehlende Erdung',
      ));
    }

    // Übersteuerung 3: Zu viel Hingabe (wenn 2,7,9 dominieren)
    final surrenderNumbers = [lifePathNumber, soulNumber, destinyNumber]
        .where((n) => [2, 7, 9].contains(n))
        .length;
    if (surrenderNumbers >= 2) {
      areas.add(OversteeringArea(
        name: 'Hingabe',
        level: (surrenderNumbers / 3) * 100,
        direction: 'Zu viel',
        impact: 'Passivität, fehlende Eigeninitiative',
      ));
    }

    // Übersteuerung 4: Zu viel Aktivität (wenn 1,3,5 dominieren)
    final activityNumbers = [lifePathNumber, soulNumber, destinyNumber]
        .where((n) => [1, 3, 5].contains(n))
        .length;
    if (activityNumbers >= 2) {
      areas.add(OversteeringArea(
        name: 'Aktivität',
        level: (activityNumbers / 3) * 100,
        direction: 'Zu viel',
        impact: 'Burnout, fehlende Integration',
      ));
    }

    final overallOversteering =
        areas.isEmpty ? 0.0 : areas.map((a) => a.level).reduce((a, b) => a + b) / areas.length;

    final mostOversteered =
        areas.isEmpty ? 'Keine Übersteuerung' : (areas..sort((a, b) => b.level.compareTo(a.level))).first.name;

    final symptoms = <String>[];
    final corrections = <String>[];

    for (var area in areas) {
      symptoms.add('${area.name}: ${area.impact}');
      corrections.add('${area.name}: Gegenpol stärken');
    }

    String urgencyLevel;
    if (overallOversteering > 70) {
      urgencyLevel = 'Hoch';
    } else if (overallOversteering > 40) {
      urgencyLevel = 'Mittel';
    } else {
      urgencyLevel = 'Niedrig';
    }

    String interpretation;
    if (urgencyLevel == 'Hoch') {
      interpretation = 'ACHTUNG: Du bist in mehreren Bereichen übersteuert. '
          'Das bedeutet: Du machst zu viel von etwas Gutem. '
          'Auch Tugenden werden zu Fehlern, wenn sie übertrieben werden. '
          'Suche bewusst die Gegenpole auf.';
    } else if (urgencyLevel == 'Mittel') {
      interpretation = 'Du hast leichte Übersteuerungen. '
          'Das ist normal – niemand ist perfekt ausbalanciert. '
          'Sei dir ihrer bewusst und korrigiere sanft.';
    } else {
      interpretation = 'Keine bedenklichen Übersteuerungen. '
          'Du lebst relativ ausgewogen. '
          'Bleibe achtsam, dass sich das nicht ändert.';
    }

    return OversteeringIndicators(
      areas: areas,
      overallOversteering: overallOversteering,
      mostOversteered: mostOversteered,
      symptoms: symptoms,
      corrections: corrections,
      urgencyLevel: urgencyLevel,
      interpretation: interpretation,
    );
  }

  // ========================================
  // 8️⃣ INTEGRATIONSPOLE
  // ========================================

  static IntegrationPoles _calculateIntegrationPoles(
    int lifePathNumber,
    int soulNumber,
    int destinyNumber,
    int age,
  ) {
    final poles = <IntegrationPole>[];

    // Integrationspol 1: Die Mittlere Zahl (5)
    final distanceTo5 = ((lifePathNumber + soulNumber + destinyNumber) / 3 - 5).abs();
    poles.add(IntegrationPole(
      name: 'Die Mitte (5)',
      description: 'Balance zwischen allen Extremen',
      distance: (distanceTo5 / 5) * 100,
      requirements: [
        'Akzeptiere beide Pole',
        'Pendele bewusst',
        'Vermeide Fixierung',
      ],
    ));

    // Integrationspol 2: Die Meisterzahl (11)
    final distanceTo11 = ((lifePathNumber + soulNumber + destinyNumber) / 3 - 11).abs();
    poles.add(IntegrationPole(
      name: 'Der Meister (11)',
      description: 'Erleuchtete Integration auf höherer Ebene',
      distance: (distanceTo11 / 11) * 100,
      requirements: [
        'Lebe deine volle Wahrheit',
        'Inspiriere andere',
        'Überwinde Dualität',
      ],
    ));

    // Integrationspol 3: Die Ganzheit (9)
    final distanceTo9 = ((lifePathNumber + soulNumber + destinyNumber) / 3 - 9).abs();
    poles.add(IntegrationPole(
      name: 'Die Ganzheit (9)',
      description: 'Vollständige Integration aller Erfahrungen',
      distance: (distanceTo9 / 9) * 100,
      requirements: [
        'Lasse das Alte los',
        'Umarme das Ganze',
        'Diene dem Größeren',
      ],
    ));

    // Integrationspol 4: Die Erdung (4)
    final distanceTo4 = ((lifePathNumber + soulNumber + destinyNumber) / 3 - 4).abs();
    poles.add(IntegrationPole(
      name: 'Die Erdung (4)',
      description: 'Integration durch Struktur und Manifestation',
      distance: (distanceTo4 / 4) * 100,
      requirements: [
        'Schaffe klare Strukturen',
        'Manifestiere deine Visionen',
        'Sei geduldig mit dem Prozess',
      ],
    ));

    // Nächster Integrationspunkt
    poles.sort((a, b) => a.distance.compareTo(b.distance));
    final nearestPole = poles.first.name;

    // Integrations-Fortschritt
    final integrationProgress = 100 - poles.first.distance;

    // Nächste Schritte
    final integrationSteps = poles.first.requirements;

    // Integrations-Qualität
    String integrationQuality;
    if (poles.first.distance < 20) {
      integrationQuality = 'Ganzheitlich';
    } else if (poles.first.distance < 50) {
      integrationQuality = 'Teilweise';
    } else {
      integrationQuality = 'Fragmentiert';
    }

    String interpretation;
    if (integrationQuality == 'Ganzheitlich') {
      interpretation = 'Du bist nah an einem Integrationspunkt. '
          'Das bedeutet: Die verschiedenen Teile von dir finden zusammen. '
          'Du bist nicht mehr zerrissen, sondern wirst GANZ.';
    } else if (integrationQuality == 'Teilweise') {
      interpretation = 'Du bist auf dem Weg zur Integration. '
          'Teile von dir sind schon vereint, andere noch getrennt. '
          'Das ist ein Prozess – kein Zustand. Bleib dran.';
    } else {
      interpretation = 'Du bist noch weit von Integration entfernt. '
          'Verschiedene Teile von dir leben getrennte Leben. '
          'Das ist nicht falsch – es ist eine frühe Phase. '
          'Integration ist das Ziel, nicht der Anfang.';
    }

    return IntegrationPoles(
      poles: poles,
      nearestPole: nearestPole,
      integrationProgress: integrationProgress,
      integrationSteps: integrationSteps,
      integrationQuality: integrationQuality,
      interpretation: interpretation,
    );
  }

  // ========================================
  // HELPER FUNCTIONS
  // ========================================

  static int _calculateLifePathNumber(DateTime birthdate) {
    final day = birthdate.day;
    final month = birthdate.month;
    final year = birthdate.year;

    int reduceToSingleDigit(int number) {
      while (number > 9 && number != 11 && number != 22 && number != 33) {
        number = number.toString().split('').map(int.parse).reduce((a, b) => a + b);
      }
      return number;
    }

    final reducedDay = reduceToSingleDigit(day);
    final reducedMonth = reduceToSingleDigit(month);
    final reducedYear = reduceToSingleDigit(year);

    return reduceToSingleDigit(reducedDay + reducedMonth + reducedYear);
  }

  static int _calculateSoulNumber(String name) {
    const vowels = 'AEIOUaeiou';
    int sum = 0;
    for (var char in name.split('')) {
      if (vowels.contains(char)) {
        sum += _letterValue(char);
      }
    }
    return _reduceToSingleDigit(sum);
  }

  static int _calculateDestinyNumber(String fullName) {
    int sum = 0;
    for (var char in fullName.replaceAll(' ', '').split('')) {
      sum += _letterValue(char);
    }
    return _reduceToSingleDigit(sum);
  }

  static int _calculatePersonalYear(DateTime birthdate, DateTime currentDate) {
    final day = birthdate.day;
    final month = birthdate.month;
    final year = currentDate.year;

    final sum = day + month + year;
    return _reduceToSingleDigit(sum);
  }

  static int _calculatePersonalMonth(DateTime birthdate, DateTime currentDate) {
    final personalYear = _calculatePersonalYear(birthdate, currentDate);
    final currentMonth = currentDate.month;
    return _reduceToSingleDigit(personalYear + currentMonth);
  }

  // TODO: Review unused method: _calculatePersonalDay
  // static int _calculatePersonalDay(DateTime birthdate, DateTime currentDate) {
    // final personalMonth = _calculatePersonalMonth(birthdate, currentDate);
    // final currentDay = currentDate.day;
    // return _reduceToSingleDigit(personalMonth + currentDay);
  // }

  static int _calculateHebrewGematria(String text) {
    // Vereinfachte hebräische Gematria
    int sum = 0;
    for (var char in text.split('')) {
      sum += _letterValue(char) * 3; // Multiplikator für hebräische Gewichtung
    }
    return sum;
  }

  // TODO: Review unused method: _calculateLatinGematria
  // static int _calculateLatinGematria(String text) {
    // Standard lateinische Gematria
    // int sum = 0;
    // for (var char in text.split('')) {
      // sum += _letterValue(char);
    // }
    // return sum;
  // }

  static int _letterValue(String char) {
    final charCode = char.toUpperCase().codeUnitAt(0);
    if (charCode >= 65 && charCode <= 90) {
      return charCode - 64; // A=1, B=2, ..., Z=26
    }
    return 0;
  }

  static int _reduceToSingleDigit(int number) {
    while (number > 9 && number != 11 && number != 22 && number != 33) {
      number = number.toString().split('').map(int.parse).reduce((a, b) => a + b);
    }
    return number;
  }

  static double _calculateVariance(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }
}
