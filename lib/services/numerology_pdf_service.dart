// Numerologie-Seelenportraet als PDF generieren.
// Nutzt das vorhandene pdf + share_plus + path_provider Setup.

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/energie_profile.dart';

class NumerologyPdfService {
  static Future<Uint8List> generateSoulPortrait({
    required EnergieProfile profile,
    required int lifePath,
    required int soul,
    required int expression,
    required int personality,
    required int personalYear,
    required List<int> masterNumbers,
    required List<int> karmaNumbers,
    required Map<String, dynamic> inclusionChart,
    required List<Map<String, dynamic>> bridgeNumbers,
    List<String> affirmations = const [],
  }) async {
    final doc = pw.Document(
      title: 'Numerologisches Seelenportraet',
      author: 'Weltenbibliothek',
    );

    final purple = PdfColor.fromInt(0xFF7C4DFF);
    final gold = PdfColor.fromInt(0xFFC9A84C);
    final dark = PdfColor.fromInt(0xFF1A1340);
    final softBg = PdfColor.fromInt(0xFFF4F0FF);

    pw.Widget pageHeader() => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: purple, width: 1.2),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Weltenbibliothek - Seelenportraet',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: purple,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                profile.fullName,
                style: pw.TextStyle(fontSize: 10, color: dark),
              ),
            ],
          ),
        );

    pw.Widget pageFooter(pw.Context ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: purple, width: 0.5),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Erstellt mit der Weltenbibliothek-App',
                style: pw.TextStyle(fontSize: 8, color: dark),
              ),
              pw.Text(
                'Seite ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8, color: dark),
              ),
            ],
          ),
        );

    pw.Widget bigNumberCircle(int n, String label) => pw.Container(
          width: 110,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: softBg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            border: pw.Border.all(color: purple, width: 1),
          ),
          child: pw.Column(
            children: [
              pw.Text('$n',
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: purple,
                  )),
              pw.SizedBox(height: 4),
              pw.Text(label,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontSize: 10, color: dark)),
            ],
          ),
        );

    // ── Seite 1: Titelseite ────────────────────────────────────────
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => pw.Stack(
          children: [
            pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 110,
                    height: 110,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      color: purple,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '$lifePath',
                      style: pw.TextStyle(
                        fontSize: 60,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 28),
                  pw.Text(
                    'Numerologisches\nSeelenportraet',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 26,
                      fontWeight: pw.FontWeight.bold,
                      color: dark,
                    ),
                  ),
                  pw.SizedBox(height: 14),
                  pw.Text(
                    'fuer ${profile.fullName}',
                    style: pw.TextStyle(fontSize: 16, color: purple),
                  ),
                  pw.SizedBox(height: 22),
                  pw.Text(
                    'Geboren am ${profile.formattedBirthDate}',
                    style: pw.TextStyle(fontSize: 12, color: dark),
                  ),
                  pw.Text(
                    'Erstellt am ${_formatToday()}',
                    style: pw.TextStyle(fontSize: 12, color: dark),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text(
                    '"Die Zahlen sind die Sprache, in der das Universum '
                    'spricht."',
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontStyle: pw.FontStyle.italic,
                      color: gold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // ── Seite 2: Kern-Zahlen ───────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pageHeader(),
        footer: pageFooter,
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.Text('Deine Kern-Zahlen',
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: dark)),
          pw.SizedBox(height: 16),
          pw.Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              bigNumberCircle(lifePath, 'Lebenszahl'),
              bigNumberCircle(expression, 'Ausdruckszahl'),
              bigNumberCircle(soul, 'Seelenzahl'),
              bigNumberCircle(personality, 'Persoenlichkeit'),
            ],
          ),
          pw.SizedBox(height: 22),
          if (masterNumbers.isNotEmpty)
            _infoBox(
              title: 'Meisterzahlen',
              body: 'Du traegst die Meisterzahlen ${masterNumbers.join(", ")} '
                  '- besondere spirituelle Aufgaben.',
              accent: gold,
              dark: dark,
            ),
          if (karmaNumbers.isNotEmpty) pw.SizedBox(height: 10),
          if (karmaNumbers.isNotEmpty)
            _infoBox(
              title: 'Karma-Zahlen',
              body: 'Karma-Zahlen ${karmaNumbers.join(", ")} - Lektionen aus '
                  'frueheren Leben warten auf Integration.',
              accent: purple,
              dark: dark,
            ),
        ],
      ),
    );

    // ── Seite 3: Zeitzyklen ────────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pageHeader(),
        footer: pageFooter,
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.Text('Zeitzyklen',
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: dark)),
          pw.SizedBox(height: 14),
          _infoBox(
            title: 'Persoenliches Jahr: $personalYear',
            body: 'Dein aktuelles Jahr im 9-Jahres-Zyklus. '
                'Die Themen entfalten sich rund um diese Schwingung.',
            accent: purple,
            dark: dark,
          ),
        ],
      ),
    );

    // ── Seite 4: Inclusion Chart ───────────────────────────────────
    final counts = (inclusionChart['numberCounts'] as Map?)?.cast<int, int>() ??
        <int, int>{};
    final missing =
        (inclusionChart['missingNumbers'] as List?)?.cast<int>() ?? const [];
    final dominant =
        (inclusionChart['dominantNumbers'] as List?)?.cast<int>() ?? const [];
    final missingTexts = (inclusionChart['missingInterpretations'] as Map?)
            ?.cast<int, String>() ??
        const {};
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pageHeader(),
        footer: pageFooter,
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.Text('Inclusion Chart',
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: dark)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Wie oft jede Zahl 1-9 in deinem Namen vorkommt.',
            style: pw.TextStyle(fontSize: 11, color: dark),
          ),
          pw.SizedBox(height: 14),
          pw.Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(9, (i) {
              final n = i + 1;
              final c = counts[n] ?? 0;
              PdfColor bg = softBg;
              PdfColor fg = dark;
              if (c == 0) {
                bg = PdfColor.fromInt(0xFFFFE5E5);
                fg = PdfColor.fromInt(0xFFB71C1C);
              } else if (c >= 3) {
                bg = PdfColor.fromInt(0xFFFFF6CC);
                fg = PdfColor.fromInt(0xFF8D6E00);
              } else if (c >= 2) {
                bg = PdfColor.fromInt(0xFFE5F7E8);
                fg = PdfColor.fromInt(0xFF1B5E20);
              }
              return pw.Container(
                width: 50,
                height: 50,
                decoration: pw.BoxDecoration(
                  color: bg,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border.all(color: fg, width: 0.6),
                ),
                alignment: pw.Alignment.center,
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('$n',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: fg,
                        )),
                    pw.Text('${c}x',
                        style: pw.TextStyle(fontSize: 9, color: fg)),
                  ],
                ),
              );
            }),
          ),
          if (dominant.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _infoBox(
              title: 'Deine Staerken (dominante Zahlen)',
              body: dominant.map((n) => 'Zahl $n').join(', '),
              accent: gold,
              dark: dark,
            ),
          ],
          if (missing.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            pw.Text('Karmische Lektionen',
                style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: dark)),
            pw.SizedBox(height: 6),
            ...missing.map((n) => _infoBox(
                  title: 'Zahl $n fehlt',
                  body: missingTexts[n] ?? '',
                  accent: PdfColor.fromInt(0xFFB71C1C),
                  dark: dark,
                )),
          ],
        ],
      ),
    );

    // ── Seite 5: Brueckenzahlen ────────────────────────────────────
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pageHeader(),
        footer: pageFooter,
        build: (ctx) => [
          pw.SizedBox(height: 12),
          pw.Text('Brueckenzahlen',
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: dark)),
          pw.SizedBox(height: 6),
          pw.Text(
            'Die Bruecke zwischen zwei Kernzahlen zeigt, welche Energie '
            'sie verbindet.',
            style: pw.TextStyle(fontSize: 11, color: dark),
          ),
          pw.SizedBox(height: 14),
          ...bridgeNumbers.map(
            (b) => _infoBox(
              title:
                  '${b['labelA']} (${b['numberA']}) <-> ${b['labelB']} (${b['numberB']})  ·  Bruecke ${b['bridge']}',
              body: (b['interpretation'] as String?) ?? '',
              accent: purple,
              dark: dark,
            ),
          ),
        ],
      ),
    );

    // ── Seite 6: Affirmationen ─────────────────────────────────────
    if (affirmations.isNotEmpty) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (ctx) => pageHeader(),
          footer: pageFooter,
          build: (ctx) => [
            pw.SizedBox(height: 12),
            pw.Text('Affirmationen fuer Lebenszahl $lifePath',
                style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: dark)),
            pw.SizedBox(height: 14),
            ...affirmations.map(
              (a) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 10),
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: softBg,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(8)),
                  border: pw.Border(
                    left: pw.BorderSide(color: gold, width: 3),
                  ),
                ),
                child: pw.Text(
                  a,
                  style: pw.TextStyle(
                      fontSize: 12,
                      color: dark,
                      fontStyle: pw.FontStyle.italic),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _infoBox({
    required String title,
    required String body,
    required PdfColor accent,
    required PdfColor dark,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8F6FF),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: accent,
              )),
          pw.SizedBox(height: 4),
          pw.Text(body,
              style: pw.TextStyle(fontSize: 11, color: dark)),
        ],
      ),
    );
  }

  static String _formatToday() {
    final d = DateTime.now();
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.${d.year}';
  }
}
