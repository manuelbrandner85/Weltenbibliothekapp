// OsintCrossLink — Cross-Tool-Jump-Detection (D2).
//
// Findet in einem Resultat-String IPs / Domains / E-Mail-Adressen /
// Phone-Numbers / Bitcoin-Adressen / Hashes — und bietet einen "Open
// in {Tool}"-Vorschlag.
//
// Verwendung:
//   final hits = OsintCrossLink.detect(resultText);
//   // hits = [{type: 'domain', value: 'example.com', tool: 'Domain-OSINT'}, ...]

class OsintCrossHit {
  final String type;   // 'domain' | 'email' | 'phone' | 'crypto' | 'ip' | 'hash'
  final String value;
  final String tool;   // Anzeige-Name des Ziel-Tools
  final String toolKey; // interner Key zum Öffnen
  const OsintCrossHit({
    required this.type,
    required this.value,
    required this.tool,
    required this.toolKey,
  });
}

class OsintCrossLink {
  // Regex-Pool (bewusst tolerant — false-positives akzeptiert für
  // Recall-Optimum, der User filtert visuell).
  static final _domain = RegExp(
      r'\b([a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,24}\b',
      caseSensitive: false);
  static final _email = RegExp(
      r'\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b',
      caseSensitive: false);
  static final _ipv4 = RegExp(
      r'\b(?:(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|[01]?\d?\d)\b');
  static final _phone = RegExp(r'\+?\d[\d\s\-\(\)]{8,16}\d');
  static final _btc = RegExp(r'\b(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}\b');
  static final _eth = RegExp(r'\b0x[a-fA-F0-9]{40}\b');
  static final _sha = RegExp(r'\b[a-fA-F0-9]{32,64}\b');

  static List<OsintCrossHit> detect(String text) {
    final seen = <String>{};
    final hits = <OsintCrossHit>[];

    void add(OsintCrossHit h) {
      final key = '${h.type}:${h.value.toLowerCase()}';
      if (seen.add(key)) hits.add(h);
    }

    for (final m in _email.allMatches(text)) {
      add(OsintCrossHit(
          type: 'email',
          value: m.group(0)!,
          tool: 'Phone/E-Mail-OSINT',
          toolKey: 'phone_osint'));
    }
    for (final m in _phone.allMatches(text)) {
      final v = m.group(0)!.replaceAll(RegExp(r'[^\d+]'), '');
      if (v.length >= 9) {
        add(OsintCrossHit(
            type: 'phone',
            value: v,
            tool: 'Phone-OSINT',
            toolKey: 'phone_osint'));
      }
    }
    for (final m in _ipv4.allMatches(text)) {
      add(OsintCrossHit(
          type: 'ip',
          value: m.group(0)!,
          tool: 'Domain-OSINT',
          toolKey: 'domain_osint'));
    }
    for (final m in _btc.allMatches(text)) {
      add(OsintCrossHit(
          type: 'crypto',
          value: m.group(0)!,
          tool: 'Crypto-Tracker',
          toolKey: 'crypto_tracker'));
    }
    for (final m in _eth.allMatches(text)) {
      add(OsintCrossHit(
          type: 'crypto',
          value: m.group(0)!,
          tool: 'Crypto-Tracker',
          toolKey: 'crypto_tracker'));
    }
    for (final m in _sha.allMatches(text)) {
      // Nur sehr lange Hashes (≥40) zählen als Hash, um Phone-Confusion zu reduzieren.
      if (m.group(0)!.length >= 40) {
        add(OsintCrossHit(
            type: 'hash',
            value: m.group(0)!,
            tool: 'Image-Analyse',
            toolKey: 'image_analysis'));
      }
    }
    // Domain als Letztes weil _email den Domain-Match überschattet.
    for (final m in _domain.allMatches(text)) {
      final v = m.group(0)!;
      // Wenn schon als Email-TLD erfasst, skip.
      if (hits.any((h) => h.type == 'email' && h.value.endsWith(v))) continue;
      add(OsintCrossHit(
          type: 'domain',
          value: v,
          tool: 'Domain-OSINT',
          toolKey: 'domain_osint'));
    }

    return hits;
  }
}
