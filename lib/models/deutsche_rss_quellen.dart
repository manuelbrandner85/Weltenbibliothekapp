import '../models/live_feed_entry.dart';

/// 🇩🇪 v5.47 - NUR DEUTSCHE RSS-QUELLEN
/// Recherchiert am 2026-01-05
/// Garantiert deutschsprachige Inhalte

class DeutscheRSSQuelle {
  final String name;
  final String url;
  final String rssUrl;
  final FeedWorld welt;
  final QuellenTyp typ;
  final String thema;
  
  const DeutscheRSSQuelle({
    required this.name,
    required this.url,
    required this.rssUrl,
    required this.welt,
    required this.typ,
    required this.thema,
  });
}

/// 🔵 MATERIE-WELT - Deutsche Quellen für Forschung, Fakten, Geopolitik
const List<DeutscheRSSQuelle> deutscheMaterieQuellen = [
  
  // ═══ WISSENSCHAFT & FORSCHUNG ═══
  
  DeutscheRSSQuelle(
    name: 'Wissenschaft.de',
    url: 'https://www.wissenschaft.de',
    rssUrl: 'https://www.wissenschaft.de/feeds/news.rss',
    welt: FeedWorld.materie,
    typ: QuellenTyp.fachtext,
    thema: 'Wissenschaft',
  ),
  
  DeutscheRSSQuelle(
    name: 'Scinexx - Wissensmagazin',
    url: 'https://www.scinexx.de',
    rssUrl: 'https://www.scinexx.de/feed/',
    welt: FeedWorld.materie,
    typ: QuellenTyp.fachtext,
    thema: 'Wissenschaft',
  ),
  
  DeutscheRSSQuelle(
    name: 'Heise Online Wissenschaft',
    url: 'https://www.heise.de',
    rssUrl: 'https://www.heise.de/rss/heise-atom.xml',
    welt: FeedWorld.materie,
    typ: QuellenTyp.fachtext,
    thema: 'Technologie',
  ),
  
  DeutscheRSSQuelle(
    name: 'IDW - Informationsdienst Wissenschaft',
    url: 'https://idw-online.de',
    rssUrl: 'https://idw-online.de/de/news?format=rss',
    welt: FeedWorld.materie,
    typ: QuellenTyp.fachtext,
    thema: 'Forschung',
  ),
  
  // ═══ GEOPOLITIK & NACHRICHTEN ═══
  
  DeutscheRSSQuelle(
    name: 'Tagesschau',
    url: 'https://www.tagesschau.de',
    rssUrl: 'https://www.tagesschau.de/index~rss2.xml',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse, // Statt 'nachrichten'
    thema: 'Nachrichten',
  ),
  
  DeutscheRSSQuelle(
    name: 'Deutschlandfunk',
    url: 'https://www.deutschlandfunk.de',
    rssUrl: 'https://www.deutschlandfunk.de/die-nachrichten-100~rss.xml',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse, // Statt 'nachrichten'
    thema: 'Nachrichten',
  ),
  
  DeutscheRSSQuelle(
    name: 'SWP Berlin - Stiftung Wissenschaft und Politik',
    url: 'https://www.swp-berlin.org',
    rssUrl: 'https://www.swp-berlin.org/rss/publications.rss',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Geopolitik',
  ),
  
  DeutscheRSSQuelle(
    name: 'Deutsche Welle Politik',
    url: 'https://www.dw.com',
    rssUrl: 'https://rss.dw.com/rdf/rss-de-pol',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Politik',
  ),
  
  DeutscheRSSQuelle(
    name: 'Amerika21 - Nachrichten aus Lateinamerika',
    url: 'https://amerika21.de',
    rssUrl: 'https://amerika21.de/rss.xml',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Geopolitik',
  ),
  
  DeutscheRSSQuelle(
    name: 'Bundestag - Aktuelle Meldungen',
    url: 'https://www.bundestag.de',
    rssUrl: 'https://www.bundestag.de/rss/feeds/nachricht',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Politik',
  ),
];

/// 🟣 ENERGIE-WELT - Deutsche Quellen für Spiritualität, Bewusstsein
const List<DeutscheRSSQuelle> deutscheEnergieQuellen = [
  
  // ═══ SPIRITUALITÄT & BEWUSSTSEIN ═══
  
  DeutscheRSSQuelle(
    name: 'Yoga Vidya Blog',
    url: 'https://blog.yoga-vidya.de',
    rssUrl: 'https://blog.yoga-vidya.de/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Spiritualität',
  ),
  
  DeutscheRSSQuelle(
    name: 'Zeit zu Leben - Bewusst Leben',
    url: 'https://www.zeitzuleben.de',
    rssUrl: 'https://www.zeitzuleben.de/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Bewusstsein',
  ),
  
  DeutscheRSSQuelle(
    name: 'Sein.de - Ganzheitliches Bewusstsein',
    url: 'https://www.sein.de',
    rssUrl: 'https://www.sein.de/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Spiritualität',
  ),
  
  DeutscheRSSQuelle(
    name: 'Spiritual.wiki - Spiritualität & Esoterik',
    url: 'https://spiritual.wiki',
    rssUrl: 'https://spiritual.wiki/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Esoterik',
  ),
  
  DeutscheRSSQuelle(
    name: 'Tattva Viveka - Zeitschrift für Wissenschaft',
    url: 'https://www.tattva.de',
    rssUrl: 'https://www.tattva.de/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Philosophie',
  ),
  
  // ═══ MEDITATION & ACHTSAMKEIT ═══
  
  DeutscheRSSQuelle(
    name: 'Achtsamkeit Leben',
    url: 'https://www.achtsamkeit-leben.at',
    rssUrl: 'https://www.achtsamkeit-leben.at/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Achtsamkeit',
  ),
  
  DeutscheRSSQuelle(
    name: 'Buddhismus Aktuell',
    url: 'https://www.buddhismus-aktuell.de',
    rssUrl: 'https://www.buddhismus-aktuell.de/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Buddhismus',
  ),
  
  DeutscheRSSQuelle(
    name: 'Dalai Lama Deutschland',
    url: 'https://dalailama-deutschland.de',
    rssUrl: 'https://dalailama-deutschland.de/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Buddhismus',
  ),
  
  // ═══ GEISTESWISSENSCHAFTEN ═══
  
  DeutscheRSSQuelle(
    name: 'Hypotheses Geisteswissenschaften',
    url: 'https://de.hypotheses.org',
    rssUrl: 'https://de.hypotheses.org/feed',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Philosophie',
  ),
  
  DeutscheRSSQuelle(
    name: 'Philosophie Magazin',
    url: 'https://www.philomag.de',
    rssUrl: 'https://www.philomag.de/rss.xml',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Philosophie',
  ),
];
