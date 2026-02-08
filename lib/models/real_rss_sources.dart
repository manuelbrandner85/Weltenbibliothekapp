import '../models/live_feed_entry.dart';

/// v5.42 - ECHTE RSS-QUELLEN FÜR LIVE-FEEDS
/// Umfassend recherchiert am 2025-01-05
/// Internationale + Deutschsprachige Quellen

class RealRSSSource {
  final String name;
  final String url;
  final String rssUrl;
  final FeedWorld welt;
  final QuellenTyp typ;
  final String thema;
  
  const RealRSSSource({
    required this.name,
    required this.url,
    required this.rssUrl,
    required this.welt,
    required this.typ,
    required this.thema,
  });
}

/// 🔵 MATERIE-WELT QUELLEN - Forschung, Fakten, Geopolitik, Wissen
const List<RealRSSSource> materieQuellen = [
  // ═══ WISSENSCHAFT & FORSCHUNG ═══
  RealRSSSource(
    name: 'ScienceDaily',
    url: 'https://www.sciencedaily.com',
    rssUrl: 'https://www.sciencedaily.com/rss/all.xml',
    welt: FeedWorld.materie,
    typ: QuellenTyp.fachtext,
    thema: 'Wissenschaft',
  ),
  
  RealRSSSource(
    name: 'Nature News',
    url: 'https://www.nature.com',
    rssUrl: 'https://www.nature.com/nature.rss',
    welt: FeedWorld.materie,
    typ: QuellenTyp.fachtext,
    thema: 'Wissenschaft',
  ),
  
  RealRSSSource(
    name: 'New Scientist',
    url: 'https://www.newscientist.com',
    rssUrl: 'https://www.newscientist.com/feed/home',
    welt: FeedWorld.materie,
    typ: QuellenTyp.fachtext,
    thema: 'Wissenschaft',
  ),
  
  RealRSSSource(
    name: 'Phys.org',
    url: 'https://phys.org',
    rssUrl: 'https://phys.org/rss-feed/',
    welt: FeedWorld.materie,
    typ: QuellenTyp.fachtext,
    thema: 'Physik & Technologie',
  ),
  
  // ═══ GEOPOLITIK & INTERNATIONALE BEZIEHUNGEN ═══
  RealRSSSource(
    name: 'Foreign Affairs',
    url: 'https://www.foreignaffairs.com',
    rssUrl: 'https://www.foreignaffairs.com/rss.xml',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Geopolitik',
  ),
  
  RealRSSSource(
    name: 'Foreign Policy',
    url: 'https://foreignpolicy.com',
    rssUrl: 'https://foreignpolicy.com/feed/',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Geopolitik',
  ),
  
  RealRSSSource(
    name: 'Geopolitical Monitor',
    url: 'https://www.geopoliticalmonitor.com',
    rssUrl: 'https://www.geopoliticalmonitor.com/feed/',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Geopolitik',
  ),
  
  RealRSSSource(
    name: 'E-International Relations',
    url: 'https://www.e-ir.info',
    rssUrl: 'https://www.e-ir.info/feed/',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Internationale Politik',
  ),
  
  // ═══ FAKTEN & NACHRICHTEN ═══
  RealRSSSource(
    name: 'BBC Science',
    url: 'https://www.bbc.com/news/science_and_environment',
    rssUrl: 'http://feeds.bbci.co.uk/news/science_and_environment/rss.xml',
    welt: FeedWorld.materie,
    typ: QuellenTyp.essay,
    thema: 'Wissenschaftsnachrichten',
  ),
  
  RealRSSSource(
    name: 'The Guardian Science',
    url: 'https://www.theguardian.com/science',
    rssUrl: 'https://www.theguardian.com/science/rss',
    welt: FeedWorld.materie,
    typ: QuellenTyp.essay,
    thema: 'Wissenschaftsnachrichten',
  ),
  
  // ═══ DEUTSCHSPRACHIGE QUELLEN ═══
  RealRSSSource(
    name: 'Amerika21',
    url: 'https://amerika21.de',
    rssUrl: 'https://amerika21.de/rss.xml',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Lateinamerika & Geopolitik',
  ),
  
  RealRSSSource(
    name: 'SWP Berlin',
    url: 'https://www.swp-berlin.org',
    rssUrl: 'https://www.swp-berlin.org/rss/publications.rss',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Sicherheitspolitik',
  ),
  
  RealRSSSource(
    name: 'Konrad-Adenauer-Stiftung',
    url: 'https://www.kas.de',
    rssUrl: 'https://www.kas.de/de/web/rss/feed/news',
    welt: FeedWorld.materie,
    typ: QuellenTyp.analyse,
    thema: 'Politik & Gesellschaft',
  ),
];

/// 🟣 ENERGIE-WELT QUELLEN - Spirit, Bewusstsein, Archetypen, Symbolik
const List<RealRSSSource> energieQuellen = [
  // ═══ SPIRITUALITÄT & BEWUSSTSEIN ═══
  RealRSSSource(
    name: 'Beshara Magazine',
    url: 'https://besharamagazine.org',
    rssUrl: 'https://besharamagazine.org/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Spiritualität & Metaphysik',
  ),
  
  RealRSSSource(
    name: 'Mindful Magazine',
    url: 'https://www.mindful.org',
    rssUrl: 'https://www.mindful.org/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Achtsamkeit & Meditation',
  ),
  
  RealRSSSource(
    name: 'Tricycle Buddhism',
    url: 'https://tricycle.org',
    rssUrl: 'https://tricycle.org/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Buddhismus & Weisheit',
  ),
  
  RealRSSSource(
    name: 'Lion\'s Roar',
    url: 'https://www.lionsroar.com',
    rssUrl: 'https://www.lionsroar.com/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Buddhismus & Praxis',
  ),
  
  RealRSSSource(
    name: 'Spirituality & Health',
    url: 'https://spiritualityhealth.com',
    rssUrl: 'https://spiritualityhealth.com/feed',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Ganzheitliche Gesundheit',
  ),
  
  // ═══ BEWUSSTSEINSFORSCHUNG ═══
  RealRSSSource(
    name: 'ScienceDaily - Consciousness',
    url: 'https://www.sciencedaily.com/news/mind_brain/consciousness/',
    rssUrl: 'https://www.sciencedaily.com/rss/mind_brain/consciousness.xml',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Bewusstseinsforschung',
  ),
  
  RealRSSSource(
    name: 'ScienceDaily - Spirituality',
    url: 'https://www.sciencedaily.com/news/mind_brain/spirituality/',
    rssUrl: 'https://www.sciencedaily.com/rss/mind_brain/spirituality.xml',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Spiritualitätsforschung',
  ),
  
  RealRSSSource(
    name: 'Scientific American - Mind',
    url: 'https://www.scientificamerican.com/mind',
    rssUrl: 'https://www.scientificamerican.com/feed/mind/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Geist & Bewusstsein',
  ),
  
  // ═══ PHILOSOPHIE & ARCHETYPEN ═══
  RealRSSSource(
    name: 'Aeon Magazine',
    url: 'https://aeon.co',
    rssUrl: 'https://aeon.co/feed.rss',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Philosophie & Kultur',
  ),
  
  RealRSSSource(
    name: 'The Marginalian',
    url: 'https://www.themarginalian.org',
    rssUrl: 'https://www.themarginalian.org/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Literatur & Philosophie',
  ),
  
  RealRSSSource(
    name: 'Big Think',
    url: 'https://bigthink.com',
    rssUrl: 'https://bigthink.com/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Große Ideen & Philosophie',
  ),
  
  // ═══ DEUTSCHSPRACHIGE QUELLEN ═══
  RealRSSSource(
    name: 'Yoga Vidya Blog',
    url: 'https://blog.yoga-vidya.de',
    rssUrl: 'https://blog.yoga-vidya.de/feed/',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Yoga & Spiritualität',
  ),
  
  RealRSSSource(
    name: 'Hypotheses Geisteswissenschaften',
    url: 'https://de.hypotheses.org',
    rssUrl: 'https://de.hypotheses.org/feed',
    welt: FeedWorld.energie,
    typ: QuellenTyp.fachtext,
    thema: 'Geisteswissenschaften',
  ),
];

/// Gesamt-Statistiken
/// MATERIE: 13 Quellen (10 International, 3 Deutsch)
/// ENERGIE: 13 Quellen (11 International, 2 Deutsch)
/// TOTAL: 26 echte RSS-Feeds
