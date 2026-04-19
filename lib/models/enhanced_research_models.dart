/// Erweiterte Recherche-Datenmodelle
/// Professionelles Deep-Research-System mit detaillierten Analysen
/// Version: 2.0.0
library;


// ═══════════════════════════════════════════════════════════════
// ERWEITERTE METADATEN
// ═══════════════════════════════════════════════════════════════

enum QuellenTyp {
  primaer,           // Primärquelle (Originaldokument)
  sekundaer,         // Sekundärquelle (Analyse)
  whistleblower,     // Whistleblower-Aussage
  geleakteDokumente, // Geleakte Dokumente
  investigativ,      // Investigative Recherche
  mainstream,        // Mainstream-Medien
  alternativ,        // Alternative Medien
  akademisch,        // Akademische Quelle
  regierung,         // Regierungsdokument
  unbekannt,         // Unbekannte Herkunft
}

enum VertrauenswuerdigkeitsStufe {
  hochVerifiziert,   // Mehrfach verifiziert
  verifiziert,       // Verifiziert
  plausibel,         // Plausibel, nicht verifiziert
  umstritten,        // Umstritten
  spekulativ,        // Spekulativ
  widerlegt,         // Widerlegt
}

class ErweiterteQuellenMetadaten {
  final String quellenId;
  final QuellenTyp typ;
  final VertrauenswuerdigkeitsStufe vertrauenswuerdigkeit;
  final DateTime veroeffentlichungsDatum;
  final String autor;
  final String organisation;
  final String land;
  final List<String> verifikationen;
  final List<String> widersprueche;
  final double bias; // -1 (stark linkslastig) bis +1 (stark rechtslastig)
  final double sensationalismus; // 0-1
  final int zitatHaeufigkeit;
  final List<String> verknuepfteQuellen;
  
  ErweiterteQuellenMetadaten({
    required this.quellenId,
    required this.typ,
    required this.vertrauenswuerdigkeit,
    required this.veroeffentlichungsDatum,
    required this.autor,
    required this.organisation,
    required this.land,
    required this.verifikationen,
    required this.widersprueche,
    required this.bias,
    required this.sensationalismus,
    required this.zitatHaeufigkeit,
    required this.verknuepfteQuellen,
  });
  
  Map<String, dynamic> toJson() => {
    'quellenId': quellenId,
    'typ': typ.toString(),
    'vertrauenswuerdigkeit': vertrauenswuerdigkeit.toString(),
    'veroeffentlichungsDatum': veroeffentlichungsDatum.toIso8601String(),
    'autor': autor,
    'organisation': organisation,
    'land': land,
    'verifikationen': verifikationen,
    'widersprueche': widersprueche,
    'bias': bias,
    'sensationalismus': sensationalismus,
    'zitatHaeufigkeit': zitatHaeufigkeit,
    'verknuepfteQuellen': verknuepfteQuellen,
  };
}

// ═══════════════════════════════════════════════════════════════
// ERWEITERTE BEHAUPTUNGS-ANALYSE
// ═══════════════════════════════════════════════════════════════

enum BeweisTyp {
  dokumentiert,      // Dokumentiert (Akten, Fotos)
  zeugnis,          // Zeugenaussage
  statistisch,      // Statistische Analyse
  logischAbleitung, // Logische Ableitung
  indizienbeweis,   // Indizienbeweis
  anekdotisch,      // Anekdotische Evidenz
}

class Beweismittel {
  final String id;
  final BeweisTyp typ;
  final String beschreibung;
  final double staerke; // 0-1 (Beweiskraft)
  final List<String> quellenIds;
  final DateTime datierung;
  final bool verifiziert;
  final List<String> gegenbeweise;
  
  Beweismittel({
    required this.id,
    required this.typ,
    required this.beschreibung,
    required this.staerke,
    required this.quellenIds,
    required this.datierung,
    required this.verifiziert,
    required this.gegenbeweise,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'typ': typ.toString(),
    'beschreibung': beschreibung,
    'staerke': staerke,
    'quellenIds': quellenIds,
    'datierung': datierung.toIso8601String(),
    'verifiziert': verifiziert,
    'gegenbeweise': gegenbeweise,
  };
}

class DetaillierteBehauptung {
  final String id;
  final String behauptung;
  final String kategorie;
  final double plausibilitaet; // 0-1
  final double relevanz; // 0-1
  final List<String> beteiligte;
  final List<String> motive;
  final List<Beweismittel> beweise;
  final List<Beweismittel> gegenbeweise;
  final List<String> zeitlicherKontext;
  final List<String> geografischerKontext;
  final Map<String, double> narrativUebereinstimmung; // Pro Narrativ
  final List<String> verbindungenZuAnderenFaellen;
  final DateTime erstErwaehnt;
  final DateTime letztAktualisiert;
  
  DetaillierteBehauptung({
    required this.id,
    required this.behauptung,
    required this.kategorie,
    required this.plausibilitaet,
    required this.relevanz,
    required this.beteiligte,
    required this.motive,
    required this.beweise,
    required this.gegenbeweise,
    required this.zeitlicherKontext,
    required this.geografischerKontext,
    required this.narrativUebereinstimmung,
    required this.verbindungenZuAnderenFaellen,
    required this.erstErwaehnt,
    required this.letztAktualisiert,
  });
  
  double get gesamtBeweiskraft {
    if (beweise.isEmpty) return 0.0;
    return beweise.fold<double>(0.0, (sum, b) => sum + b.staerke) / beweise.length;
  }
  
  double get kontroversitaet {
    final proBeweise = beweise.fold<double>(0.0, (sum, b) => sum + b.staerke);
    final contraBeweise = gegenbeweise.fold<double>(0.0, (sum, b) => sum + b.staerke);
    if (proBeweise + contraBeweise == 0) return 0.0;
    return (proBeweise - contraBeweise).abs() / (proBeweise + contraBeweise);
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'behauptung': behauptung,
    'kategorie': kategorie,
    'plausibilitaet': plausibilitaet,
    'relevanz': relevanz,
    'beteiligte': beteiligte,
    'motive': motive,
    'beweise': beweise.map((b) => b.toJson()).toList(),
    'gegenbeweise': gegenbeweise.map((b) => b.toJson()).toList(),
    'zeitlicherKontext': zeitlicherKontext,
    'geografischerKontext': geografischerKontext,
    'narrativUebereinstimmung': narrativUebereinstimmung,
    'verbindungenZuAnderenFaellen': verbindungenZuAnderenFaellen,
    'erstErwaehnt': erstErwaehnt.toIso8601String(),
    'letztAktualisiert': letztAktualisiert.toIso8601String(),
    'gesamtBeweiskraft': gesamtBeweiskraft,
    'kontroversitaet': kontroversitaet,
  };
}

// ═══════════════════════════════════════════════════════════════
// ERWEITERTE NETZWERK-ANALYSE
// ═══════════════════════════════════════════════════════════════

enum AkteurKategorie {
  geheimdienst,
  militaer,
  regierung,
  konzern,
  finanzinstitution,
  medienorganisation,
  ngo,
  denkfabrik,
  geheimgesellschaft,
  wissenschaft,
  einzelperson,
  unbekannt,
}

enum VerbindungsTyp {
  finanziell,
  personell,
  operativ,
  hierarchisch,
  informell,
  familiaer,
  geschaeftlich,
  politisch,
  ideologisch,
}

class DetaillierteMachtverbindung {
  final String vonAkteurId;
  final String zuAkteurId;
  final VerbindungsTyp typ;
  final double staerke; // 0-1
  final String beschreibung;
  final DateTime beginn;
  final DateTime? ende;
  final bool aktiv;
  final List<String> belege;
  final double transparenz; // 0-1 (0 = komplett verborgen)
  
  DetaillierteMachtverbindung({
    required this.vonAkteurId,
    required this.zuAkteurId,
    required this.typ,
    required this.staerke,
    required this.beschreibung,
    required this.beginn,
    this.ende,
    required this.aktiv,
    required this.belege,
    required this.transparenz,
  });
  
  Map<String, dynamic> toJson() => {
    'vonAkteurId': vonAkteurId,
    'zuAkteurId': zuAkteurId,
    'typ': typ.toString(),
    'staerke': staerke,
    'beschreibung': beschreibung,
    'beginn': beginn.toIso8601String(),
    'ende': ende?.toIso8601String(),
    'aktiv': aktiv,
    'belege': belege,
    'transparenz': transparenz,
  };
}

class DetaillierterMachtakteur {
  final String id;
  final String name;
  final AkteurKategorie kategorie;
  final String beschreibung;
  final double einflussGlobal; // 0-100
  final double einflussRegional; // 0-100
  final double oeffentlicheSichtbarkeit; // 0-1
  final List<String> bereiche; // Einflussbereich
  final List<DetaillierteMachtverbindung> verbindungen;
  final List<String> bekannteOperationen;
  final List<String> vermuteteOperationen;
  final DateTime gruendung;
  final String hauptsitz;
  final List<String> schluesselPersonen;
  final Map<String, double> finanzstroeme; // Richtung → Volumen
  final double transparenzIndex; // 0-1
  final List<String> kontroversen;
  
  DetaillierterMachtakteur({
    required this.id,
    required this.name,
    required this.kategorie,
    required this.beschreibung,
    required this.einflussGlobal,
    required this.einflussRegional,
    required this.oeffentlicheSichtbarkeit,
    required this.bereiche,
    required this.verbindungen,
    required this.bekannteOperationen,
    required this.vermuteteOperationen,
    required this.gruendung,
    required this.hauptsitz,
    required this.schluesselPersonen,
    required this.finanzstroeme,
    required this.transparenzIndex,
    required this.kontroversen,
  });
  
  int get anzahlVerbindungen => verbindungen.length;
  
  double get durchschnittlicheVerbindungsstaerke {
    if (verbindungen.isEmpty) return 0.0;
    return verbindungen.fold<double>(0.0, (sum, v) => sum + v.staerke) / verbindungen.length;
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kategorie': kategorie.toString(),
    'beschreibung': beschreibung,
    'einflussGlobal': einflussGlobal,
    'einflussRegional': einflussRegional,
    'oeffentlicheSichtbarkeit': oeffentlicheSichtbarkeit,
    'bereiche': bereiche,
    'verbindungen': verbindungen.map((v) => v.toJson()).toList(),
    'bekannteOperationen': bekannteOperationen,
    'vermuteteOperationen': vermuteteOperationen,
    'gruendung': gruendung.toIso8601String(),
    'hauptsitz': hauptsitz,
    'schluesselPersonen': schluesselPersonen,
    'finanzstroeme': finanzstroeme,
    'transparenzIndex': transparenzIndex,
    'kontroversen': kontroversen,
    'anzahlVerbindungen': anzahlVerbindungen,
    'durchschnittlicheVerbindungsstaerke': durchschnittlicheVerbindungsstaerke,
  };
}

class ErweiterteNetzwerkAnalyse {
  final List<DetaillierterMachtakteur> akteure;
  final List<DetaillierteMachtverbindung> alleVerbindungen;
  final Map<String, List<String>> cluster; // Cluster-ID → Akteur-IDs
  final List<String> zentraleKnotenpunkte; // Akteur-IDs
  final double netzwerkDichte; // 0-1
  final double zentralisierung; // 0-1
  final Map<String, int> hierarchieEbenen;
  final List<String> verborgeneVerbindungen;
  final DateTime analysiertAm;
  
  ErweiterteNetzwerkAnalyse({
    required this.akteure,
    required this.alleVerbindungen,
    required this.cluster,
    required this.zentraleKnotenpunkte,
    required this.netzwerkDichte,
    required this.zentralisierung,
    required this.hierarchieEbenen,
    required this.verborgeneVerbindungen,
    required this.analysiertAm,
  });
  
  Map<String, dynamic> toJson() => {
    'akteure': akteure.map((a) => a.toJson()).toList(),
    'alleVerbindungen': alleVerbindungen.map((v) => v.toJson()).toList(),
    'cluster': cluster,
    'zentraleKnotenpunkte': zentraleKnotenpunkte,
    'netzwerkDichte': netzwerkDichte,
    'zentralisierung': zentralisierung,
    'hierarchieEbenen': hierarchieEbenen,
    'verborgeneVerbindungen': verborgeneVerbindungen,
    'analysiertAm': analysiertAm.toIso8601String(),
  };
}

// ═══════════════════════════════════════════════════════════════
// ERWEITERTE ZEITACHSEN-ANALYSE
// ═══════════════════════════════════════════════════════════════

enum EreignisTyp {
  offiziellBestaetigt,
  geleakt,
  investigativAufgedeckt,
  whistleblowerEnthuellung,
  regierungserklaerung,
  gerichtsdokument,
  medienBerichterstattung,
  akademischeStudie,
  zeugenaussage,
}

class DetailliertesZeitereignis {
  final String id;
  final DateTime zeitpunkt;
  final EreignisTyp typ;
  final String titel;
  final String beschreibung;
  final String offizielleDarstellung;
  final String alternativeDarstellung;
  final List<String> beteiligte;
  final List<String> quellenIds;
  final double signifikanz; // 0-1
  final bool wendepunkt;
  final List<String> auswirkungen;
  final List<String> unterdueckteInformationen;
  final Map<String, String> narrativEvolution; // Zeitpunkt → Darstellung
  final List<String> widerspruecheInOffiziellerId;
  final String geografischerOrt;
  
  DetailliertesZeitereignis({
    required this.id,
    required this.zeitpunkt,
    required this.typ,
    required this.titel,
    required this.beschreibung,
    required this.offizielleDarstellung,
    required this.alternativeDarstellung,
    required this.beteiligte,
    required this.quellenIds,
    required this.signifikanz,
    required this.wendepunkt,
    required this.auswirkungen,
    required this.unterdueckteInformationen,
    required this.narrativEvolution,
    required this.widerspruecheInOffiziellerId,
    required this.geografischerOrt,
  });
  
  double get narrativDivergenz {
    if (offizielleDarstellung.isEmpty || alternativeDarstellung.isEmpty) return 0.0;
    // Vereinfachte Berechnung - in Realität: NLP-Analyse
    final offWords = offizielleDarstellung.split(' ').length;
    final altWords = alternativeDarstellung.split(' ').length;
    return ((offWords - altWords).abs() / (offWords + altWords)).clamp(0.0, 1.0);
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'zeitpunkt': zeitpunkt.toIso8601String(),
    'typ': typ.toString(),
    'titel': titel,
    'beschreibung': beschreibung,
    'offizielleDarstellung': offizielleDarstellung,
    'alternativeDarstellung': alternativeDarstellung,
    'beteiligte': beteiligte,
    'quellenIds': quellenIds,
    'signifikanz': signifikanz,
    'wendepunkt': wendepunkt,
    'auswirkungen': auswirkungen,
    'unterdueckteInformationen': unterdueckteInformationen,
    'narrativEvolution': narrativEvolution,
    'widerspruecheInOffiziellerId': widerspruecheInOffiziellerId,
    'geografischerOrt': geografischerOrt,
    'narrativDivergenz': narrativDivergenz,
  };
}

class ErweiterteZeitachsenAnalyse {
  final List<DetailliertesZeitereignis> ereignisse;
  final Map<String, int> wendepunkte; // Jahr → Anzahl
  final Map<String, List<String>> narrativVeraenderungen; // Zeitraum → Änderungen
  final List<String> systematischUnterdueckt;
  final Map<String, double> informationsFlussAnalyse; // Zeitraum → Transparenz
  final DateTime analysiertAm;
  
  ErweiterteZeitachsenAnalyse({
    required this.ereignisse,
    required this.wendepunkte,
    required this.narrativVeraenderungen,
    required this.systematischUnterdueckt,
    required this.informationsFlussAnalyse,
    required this.analysiertAm,
  });
  
  Map<String, dynamic> toJson() => {
    'ereignisse': ereignisse.map((e) => e.toJson()).toList(),
    'wendepunkte': wendepunkte,
    'narrativVeraenderungen': narrativVeraenderungen,
    'systematischUnterdueckt': systematischUnterdueckt,
    'informationsFlussAnalyse': informationsFlussAnalyse,
    'analysiertAm': analysiertAm.toIso8601String(),
  };
}

// ═══════════════════════════════════════════════════════════════
// STATISTIK-HELPER
// ═══════════════════════════════════════════════════════════════

class AnalyseStatistiken {
  final int gesamtQuellen;
  final int verifizierteQuellen;
  final int umstritteneQuellen;
  final double durchschnittlicheVertrauenswuerdigkeit;
  final Map<QuellenTyp, int> quellenVerteilung;
  final Map<String, int> laenderVerteilung;
  final Map<String, double> biasVerteilung;
  
  AnalyseStatistiken({
    required this.gesamtQuellen,
    required this.verifizierteQuellen,
    required this.umstritteneQuellen,
    required this.durchschnittlicheVertrauenswuerdigkeit,
    required this.quellenVerteilung,
    required this.laenderVerteilung,
    required this.biasVerteilung,
  });
  
  Map<String, dynamic> toJson() => {
    'gesamtQuellen': gesamtQuellen,
    'verifizierteQuellen': verifizierteQuellen,
    'umstritteneQuellen': umstritteneQuellen,
    'durchschnittlicheVertrauenswuerdigkeit': durchschnittlicheVertrauenswuerdigkeit,
    'quellenVerteilung': quellenVerteilung.map((k, v) => MapEntry(k.toString(), v)),
    'laenderVerteilung': laenderVerteilung,
    'biasVerteilung': biasVerteilung,
  };
}
