/**
 * ERWEITERTE NARRATIVE DATENBANK v5.0
 * 
 * 30+ Alternative Narrative mit Kategorien-System
 * Kategorien: UFOs, Geheime Gesellschaften, Technologie, Historie, Geopolitik, Wissenschaft, Kosmologie
 */

const CATEGORIES = {
  UFO: { id: 'ufo', name: 'UFOs & Außerirdische', icon: '👽', color: '#00FF00' },
  SECRET_SOCIETY: { id: 'secret_society', name: 'Geheime Gesellschaften', icon: '🏛️', color: '#8B4513' },
  TECHNOLOGY: { id: 'technology', name: 'Technologie & Experimente', icon: '⚡', color: '#FFD700' },
  HISTORY: { id: 'history', name: 'Historische Ereignisse', icon: '📜', color: '#CD5C5C' },
  GEOPOLITICS: { id: 'geopolitics', name: 'Geopolitik & Macht', icon: '🌍', color: '#4169E1' },
  SCIENCE: { id: 'science', name: 'Wissenschaft & Medizin', icon: '🔬', color: '#32CD32' },
  COSMOLOGY: { id: 'cosmology', name: 'Kosmologie & Weltbild', icon: '🌌', color: '#9370DB' },
};

const ENHANCED_NARRATIVE_DATABASE = {
  // ============================================================================
  // UFOs & AUSSERIRDISCHE
  // ============================================================================
  
  area51: {
    id: 'area51',
    title: 'Area 51 & Außerirdische Technologie',
    categories: [CATEGORIES.UFO, CATEGORIES.TECHNOLOGY],
    priority: 1,
    keyPoints: [
      'Militärische Testanlage in Nevada seit 1955',
      'UFO-Sichtungen und Zeugenaussagen',
      'Bob Lazar und Element 115',
      'CIA Declassified Documents'
    ],
    keywords: ['area 51', 'ufo', 'aliens', 'bob lazar', 'roswell', 's4', 'element 115'],
    historicalContext: 'Area 51 wurde 1955 als Testgelände für das U-2 Spionageflugzeug eingerichtet.',
    timeline: [
      { year: 1955, event: 'Gründung von Area 51' },
      { year: 1989, event: 'Bob Lazar geht an die Öffentlichkeit' },
      { year: 2013, event: 'CIA gibt Existenz offiziell zu' }
    ],
    relatedNarratives: ['roswell', 'dulce_base', 'majestic12']
  },
  
  roswell: {
    id: 'roswell',
    title: 'Roswell UFO-Absturz 1947',
    categories: [CATEGORIES.UFO, CATEGORIES.HISTORY],
    priority: 1,
    keyPoints: [
      'Angeblicher UFO-Absturz in New Mexico',
      'Militärische Vertuschung',
      'Zeugenaussagen von Ersthelfen',
      'Project Mogul als offizielle Erklärung'
    ],
    keywords: ['roswell', 'ufo crash', '1947', 'new mexico', 'flying saucer'],
    historicalContext: 'Am 8. Juli 1947 verkündete die US Army Air Forces den Fund einer "fliegenden Untertasse".',
    timeline: [
      { year: 1947, event: 'UFO-Absturz bei Roswell' },
      { year: 1947, event: 'Militär zieht Aussage zurück: "Wetterballon"' },
      { year: 1994, event: 'Air Force Report: Project Mogul' }
    ],
    relatedNarratives: ['area51', 'majestic12']
  },
  
  dulce_base: {
    id: 'dulce_base',
    title: 'Dulce Base: Unterirdische Alien-Basis',
    categories: [CATEGORIES.UFO, CATEGORIES.TECHNOLOGY],
    priority: 2,
    keyPoints: [
      'Angebliche unterirdische Basis in New Mexico',
      'Mensch-Alien-Kooperation',
      'Genetische Experimente',
      'Phil Schneider Whistleblower-Aussagen'
    ],
    keywords: ['dulce base', 'underground base', 'phil schneider', 'grey aliens'],
    historicalContext: 'Phil Schneider behauptete 1995, an der Dulce Base gearbeitet zu haben.',
    relatedNarratives: ['area51', 'montauk']
  },
  
  majestic12: {
    id: 'majestic12',
    title: 'Majestic 12: Geheime UFO-Kommission',
    categories: [CATEGORIES.UFO, CATEGORIES.SECRET_SOCIETY],
    priority: 2,
    keyPoints: [
      'Angebliche geheime Regierungsgruppe',
      'UFO-Bergung und Reverse Engineering',
      'Dokumente von 1984',
      'Authentizität umstritten'
    ],
    keywords: ['majestic 12', 'mj12', 'ufo commission', 'eisenhower'],
    historicalContext: 'Dokumente tauchten 1984 auf, angeblich von 1952.',
    relatedNarratives: ['area51', 'roswell']
  },
  
  // ============================================================================
  // GEHEIME GESELLSCHAFTEN
  // ============================================================================
  
  illuminati: {
    id: 'illuminati',
    title: 'Illuminati & Geheime Machteliten',
    categories: [CATEGORIES.SECRET_SOCIETY, CATEGORIES.GEOPOLITICS],
    priority: 1,
    keyPoints: [
      'Historischer Illuminaten-Orden (1776-1785)',
      'Moderne Interpretationen von Machtstrukturen',
      'Symbole in Populärkultur',
      'Bilderberg-Gruppe und Elite-Treffen'
    ],
    keywords: ['illuminati', 'geheimgesellschaft', 'elite', 'neue weltordnung', 'nwo'],
    historicalContext: 'Der Illuminatenorden wurde 1776 in Bayern gegründet und 1785 verboten.',
    timeline: [
      { year: 1776, event: 'Gründung des Illuminatenordens' },
      { year: 1785, event: 'Verbot durch bayerische Regierung' },
      { year: 1903, event: 'Erste Bilderberg-Konferenz' }
    ],
    relatedNarratives: ['bilderberg', 'bohemian_grove', 'skull_bones']
  },
  
  bilderberg: {
    id: 'bilderberg',
    title: 'Bilderberg-Gruppe & Elite-Treffen',
    categories: [CATEGORIES.SECRET_SOCIETY, CATEGORIES.GEOPOLITICS],
    priority: 1,
    keyPoints: [
      'Jährliche Konferenzen seit 1954',
      'Teilnehmerlisten und Agenda geheim',
      'Einfluss auf globale Politik',
      'Medienberichterstattung begrenzt'
    ],
    keywords: ['bilderberg', 'davos', 'wef', 'elite', 'global governance'],
    historicalContext: 'Die Bilderberg-Konferenz wurde 1954 gegründet.',
    timeline: [
      { year: 1954, event: 'Erste Bilderberg-Konferenz' },
      { year: 2010, event: 'Öffentliche Proteste nehmen zu' }
    ],
    relatedNarratives: ['illuminati', 'wef_great_reset', 'trilateral']
  },
  
  bohemian_grove: {
    id: 'bohemian_grove',
    title: 'Bohemian Grove: Elite-Rituale',
    categories: [CATEGORIES.SECRET_SOCIETY],
    priority: 2,
    keyPoints: [
      'Private Club in Kalifornien',
      'Cremation of Care Ritual',
      'Mitglieder aus Politik, Wirtschaft, Medien',
      'Alex Jones Undercover-Footage 2000'
    ],
    keywords: ['bohemian grove', 'elite', 'ritual', 'kalifornien', 'owl'],
    historicalContext: 'Bohemian Grove existiert seit 1872.',
    relatedNarratives: ['illuminati', 'bilderberg']
  },
  
  skull_bones: {
    id: 'skull_bones',
    title: 'Skull & Bones: Yale Secret Society',
    categories: [CATEGORIES.SECRET_SOCIETY],
    priority: 2,
    keyPoints: [
      'Geheimbund an Yale University seit 1832',
      'Prominente Mitglieder (Bush-Familie)',
      'Initiationsrituale',
      'Einfluss auf US-Politik'
    ],
    keywords: ['skull and bones', 'yale', 'secret society', 'bush'],
    historicalContext: 'Gegründet 1832 an der Yale University.',
    relatedNarratives: ['illuminati', 'bohemian_grove']
  },
  
  // ============================================================================
  // HISTORISCHE EREIGNISSE
  // ============================================================================
  
  '911': {
    id: '911',
    title: '9/11: Kritische Untersuchungen',
    categories: [CATEGORIES.HISTORY, CATEGORIES.GEOPOLITICS],
    priority: 1,
    keyPoints: [
      'Building 7 Einsturz ohne Flugzeugeinschlag',
      'NIST-Report und kritische Analysen',
      'Operation Northwoods als Präzedenzfall',
      'Geopolitische Folgen: War on Terror'
    ],
    keywords: ['9/11', 'world trade center', 'building 7', 'nist', 'pentagon'],
    historicalContext: 'Die Anschläge vom 11. September 2001 veränderten die Weltpolitik.',
    timeline: [
      { year: 2001, event: '9/11 Anschläge' },
      { year: 2002, event: 'War on Terror beginnt' },
      { year: 2008, event: 'NIST Final Report' }
    ],
    relatedNarratives: ['operation_northwoods', 'pearl_harbor']
  },
  
  jfk: {
    id: 'jfk',
    title: 'JFK-Attentat: Alternative Narrative',
    categories: [CATEGORIES.HISTORY, CATEGORIES.GEOPOLITICS],
    priority: 1,
    keyPoints: [
      'Warren-Kommission vs. Kritische Analysen',
      'Zapruder-Film und ballistische Fragen',
      'Magic Bullet Theory',
      'CIA und FBI Declassified Documents'
    ],
    keywords: ['jfk', 'kennedy', 'assassination', 'zapruder', 'warren commission', 'oswald'],
    historicalContext: 'John F. Kennedy wurde am 22. November 1963 in Dallas erschossen.',
    timeline: [
      { year: 1963, event: 'JFK-Attentat' },
      { year: 1964, event: 'Warren-Kommission Report' },
      { year: 2017, event: 'Weitere JFK-Files freigegeben' }
    ],
    relatedNarratives: ['cia_operations', 'mafia_conspiracy']
  },
  
  pearl_harbor: {
    id: 'pearl_harbor',
    title: 'Pearl Harbor: Wusste die US-Regierung Bescheid?',
    categories: [CATEGORIES.HISTORY, CATEGORIES.GEOPOLITICS],
    priority: 2,
    keyPoints: [
      'Angriff am 7. Dezember 1941',
      'Vorwarnungen ignoriert?',
      'US-Kriegseintritt als Motiv',
      'Declassified Intelligence Reports'
    ],
    keywords: ['pearl harbor', '1941', 'roosevelt', 'japan', 'world war 2'],
    historicalContext: 'Der Angriff führte zum US-Eintritt in den Zweiten Weltkrieg.',
    relatedNarratives: ['911', 'operation_northwoods']
  },
  
  mondlandung: {
    id: 'mondlandung',
    title: 'Mondlandung: Kontroverse Perspektiven',
    categories: [CATEGORIES.HISTORY, CATEGORIES.SCIENCE, CATEGORIES.COSMOLOGY],
    priority: 2,
    keyPoints: [
      'Technische Herausforderungen der Apollo-Missionen',
      'Fotografische Anomalien',
      'Van Allen Strahlungsgürtel',
      'Stanley Kubrick-Theorie'
    ],
    keywords: ['mondlandung', 'apollo', 'nasa', 'moon hoax', 'van allen', 'kubrick'],
    historicalContext: 'Die erste bemannte Mondlandung fand am 20. Juli 1969 statt (Apollo 11).',
    timeline: [
      { year: 1969, event: 'Apollo 11 Mondlandung' },
      { year: 1972, event: 'Letzte Apollo-Mission' },
      { year: 2001, event: 'Bart Sibrel Kontroverse' }
    ],
    relatedNarratives: ['flat_earth', 'antarktis']
  },
  
  // ============================================================================
  // TECHNOLOGIE & EXPERIMENTE
  // ============================================================================
  
  mk_ultra: {
    id: 'mk_ultra',
    title: 'MK-Ultra: CIA Mind Control Experimente',
    categories: [CATEGORIES.TECHNOLOGY, CATEGORIES.SCIENCE],
    priority: 1,
    keyPoints: [
      'Declassified CIA Documents (1975)',
      'LSD und psychoaktive Substanzen',
      'Menschenversuche ohne Einwilligung',
      'Church Committee Untersuchungen'
    ],
    keywords: ['mk ultra', 'cia', 'mind control', 'lsd', 'experimente'],
    historicalContext: 'MK-Ultra war ein geheimes CIA-Programm (1953-1973) zur Bewusstseinskontrolle.',
    timeline: [
      { year: 1953, event: 'MK-Ultra Programm startet' },
      { year: 1973, event: 'Programm offiziell beendet' },
      { year: 1975, event: 'Church Committee deckt auf' }
    ],
    relatedNarratives: ['montauk', 'monarch']
  },
  
  haarp: {
    id: 'haarp',
    title: 'HAARP & Wetterkontrolle',
    categories: [CATEGORIES.TECHNOLOGY, CATEGORIES.GEOPOLITICS],
    priority: 2,
    keyPoints: [
      'High-frequency Active Auroral Research Program',
      'Ionosphären-Forschung',
      'Wettermanipulations-Theorien',
      'Erdbebenwaffe-Spekulationen'
    ],
    keywords: ['haarp', 'weather control', 'earthquake weapon', 'ionosphere'],
    historicalContext: 'HAARP wurde 1993 in Alaska errichtet.',
    relatedNarratives: ['chemtrails', 'geoengineering']
  },
  
  chemtrails: {
    id: 'chemtrails',
    title: 'Chemtrails & Geoengineering',
    categories: [CATEGORIES.TECHNOLOGY, CATEGORIES.SCIENCE],
    priority: 2,
    keyPoints: [
      'Kondensstreifen vs. Chemtrails',
      'Geoengineering-Programme',
      'Wettermanipulation',
      'Aluminium und Barium in der Atmosphäre'
    ],
    keywords: ['chemtrails', 'geoengineering', 'weather modification', 'contrails'],
    historicalContext: 'Chemtrail-Theorien entstanden in den 1990ern.',
    relatedNarratives: ['haarp', 'climate_change']
  },
  
  philadelphia_experiment: {
    id: 'philadelphia_experiment',
    title: 'Philadelphia Experiment: Unsichtbarkeit',
    categories: [CATEGORIES.TECHNOLOGY, CATEGORIES.HISTORY],
    priority: 3,
    keyPoints: [
      'Angebliches Navy-Experiment 1943',
      'USS Eldridge unsichtbar gemacht',
      'Teleportation nach Norfolk',
      'Carl Allen Briefe'
    ],
    keywords: ['philadelphia experiment', 'uss eldridge', 'invisibility', 'teleportation'],
    historicalContext: 'Angeblich 1943, aber erst 1955 durch Carl Allen bekannt.',
    relatedNarratives: ['montauk', 'nikola_tesla']
  },
  
  montauk: {
    id: 'montauk',
    title: 'Montauk Project: Zeitreise-Experimente',
    categories: [CATEGORIES.TECHNOLOGY],
    priority: 3,
    keyPoints: [
      'Camp Hero Air Force Station',
      'Zeitreise-Experimente',
      'Mind Control',
      'Preston Nichols Enthüllungen'
    ],
    keywords: ['montauk', 'time travel', 'camp hero', 'preston nichols'],
    historicalContext: 'Angebliche Experimente 1971-1983.',
    relatedNarratives: ['philadelphia_experiment', 'mk_ultra']
  },
  
  // ============================================================================
  // GEOPOLITIK & MACHTSTRUKTUREN
  // ============================================================================
  
  operation_northwoods: {
    id: 'operation_northwoods',
    title: 'Operation Northwoods: False Flag Pläne',
    categories: [CATEGORIES.GEOPOLITICS, CATEGORIES.HISTORY],
    priority: 1,
    keyPoints: [
      'Declassified DoD Documents (1997)',
      'Geplante False-Flag-Operationen gegen Kuba',
      'Joint Chiefs of Staff Vorschläge',
      'Präsident Kennedy lehnte ab'
    ],
    keywords: ['operation northwoods', 'false flag', 'kuba', 'pentagon', 'jcs'],
    historicalContext: 'Operation Northwoods war ein 1962 vorgeschlagener (aber abgelehnter) Plan.',
    timeline: [
      { year: 1962, event: 'Operation Northwoods vorgeschlagen' },
      { year: 1962, event: 'Kennedy lehnt ab' },
      { year: 1997, event: 'Dokumente declassified' }
    ],
    relatedNarratives: ['911', 'jfk']
  },
  
  wef_great_reset: {
    id: 'wef_great_reset',
    title: 'Great Reset & World Economic Forum',
    categories: [CATEGORIES.GEOPOLITICS],
    priority: 1,
    keyPoints: [
      'Klaus Schwab und WEF',
      '"You will own nothing and be happy"',
      'COVID-19 als Chance',
      'Agenda 2030'
    ],
    keywords: ['great reset', 'wef', 'klaus schwab', 'davos', 'agenda 2030'],
    historicalContext: 'Great Reset Initiative wurde 2020 angekündigt.',
    relatedNarratives: ['bilderberg', 'covid_origins']
  },
  
  new_world_order: {
    id: 'new_world_order',
    title: 'Neue Weltordnung (NWO)',
    categories: [CATEGORIES.GEOPOLITICS, CATEGORIES.SECRET_SOCIETY],
    priority: 1,
    keyPoints: [
      'George H.W. Bush Rede 1991',
      'Weltregierung-Konzepte',
      'UN und Globalisierung',
      'Souveränitätsverlust der Nationen'
    ],
    keywords: ['new world order', 'nwo', 'weltregierung', 'globalisierung'],
    historicalContext: 'Begriff populär seit Bush-Rede 1991.',
    relatedNarratives: ['illuminati', 'bilderberg', 'wef_great_reset']
  },
  
  antarktis: {
    id: 'antarktis',
    title: 'Antarktis: Geheime Basen & Expeditionen',
    categories: [CATEGORIES.GEOPOLITICS, CATEGORIES.HISTORY],
    priority: 2,
    keyPoints: [
      'Operation Highjump (1946-1947)',
      'Admiral Byrd Expeditionen',
      'Neuschwabenland und Nazi-Deutschland',
      'Moderne Forschungsstationen'
    ],
    keywords: ['antarktis', 'operation highjump', 'admiral byrd', 'neuschwabenland', 'nazis'],
    historicalContext: 'Operation Highjump war die größte Antarktis-Expedition der US Navy (1946-1947).',
    relatedNarratives: ['hollow_earth', 'nazi_ufos']
  },
  
  // ============================================================================
  // WISSENSCHAFT & MEDIZIN
  // ============================================================================
  
  covid_origins: {
    id: 'covid_origins',
    title: 'COVID-19 Ursprung: Labortheorie',
    categories: [CATEGORIES.SCIENCE, CATEGORIES.GEOPOLITICS],
    priority: 1,
    keyPoints: [
      'Wuhan Institute of Virology',
      'Gain-of-Function Research',
      'Fauci und NIH Förderung',
      'Lab-Leak vs. Natürlicher Ursprung'
    ],
    keywords: ['covid-19', 'lab leak', 'wuhan', 'gain of function', 'fauci'],
    historicalContext: 'COVID-19 Pandemie begann Ende 2019.',
    relatedNarratives: ['wef_great_reset', 'vaccine_conspiracy']
  },
  
  fluoride: {
    id: 'fluoride',
    title: 'Fluoridierung: Gesundheitsrisiko?',
    categories: [CATEGORIES.SCIENCE],
    priority: 3,
    keyPoints: [
      'Trinkwasser-Fluoridierung',
      'IQ-Senkung Studien',
      'Zirbeldrüsen-Verkalkung',
      'Industrie-Abfallprodukt'
    ],
    keywords: ['fluoride', 'fluoridierung', 'trinkwasser', 'iq', 'pineal gland'],
    historicalContext: 'Fluoridierung begann in den 1940ern in den USA.',
    relatedNarratives: ['vaccine_conspiracy', 'gmo_food']
  },
  
  // ============================================================================
  // KOSMOLOGIE & WELTBILD
  // ============================================================================
  
  flat_earth: {
    id: 'flat_earth',
    title: 'Flache Erde & Weltbild',
    categories: [CATEGORIES.COSMOLOGY],
    priority: 2,
    keyPoints: [
      'Flache Erde Modelle',
      'NASA-Kritik',
      'Antarktis-Eisrand',
      'Perspektive und Horizont'
    ],
    keywords: ['flat earth', 'flache erde', 'nasa', 'globe', 'dome'],
    historicalContext: 'Flache-Erde-Bewegung gewann ab 2015 an Popularität.',
    relatedNarratives: ['mondlandung', 'antarktis']
  },
  
  hollow_earth: {
    id: 'hollow_earth',
    title: 'Hohle Erde: Innere Zivilisationen',
    categories: [CATEGORIES.COSMOLOGY],
    priority: 3,
    keyPoints: [
      'Hohle Erde Theorie',
      'Agartha und Shambhala',
      'Admiral Byrd Tagebuch',
      'Polöffnungen'
    ],
    keywords: ['hollow earth', 'hohle erde', 'agartha', 'shambhala', 'admiral byrd'],
    historicalContext: 'Theorie existiert seit dem 17. Jahrhundert.',
    relatedNarratives: ['antarktis', 'flat_earth']
  },
  
  denver_airport: {
    id: 'denver_airport',
    title: 'Denver Airport: Okkulte Symbolik',
    categories: [CATEGORIES.COSMOLOGY, CATEGORIES.SECRET_SOCIETY],
    priority: 3,
    keyPoints: [
      'Unheimliche Wandgemälde',
      'Freimauer-Symbolik',
      'Unterirdische Anlagen',
      'Blucifer-Statue'
    ],
    keywords: ['denver airport', 'dia', 'blucifer', 'murals', 'symbolism'],
    historicalContext: 'Denver International Airport eröffnete 1995.',
    relatedNarratives: ['illuminati', 'new_world_order']
  },
  
  ancient_tech: {
    id: 'ancient_tech',
    title: 'Pyramiden & Antike Technologie',
    categories: [CATEGORIES.COSMOLOGY, CATEGORIES.HISTORY],
    priority: 2,
    keyPoints: [
      'Präzision der Pyramidenbauweise',
      'Megalithische Strukturen',
      'Antike Astronauten Theorie',
      'Graham Hancock und alternative Archäologie'
    ],
    keywords: ['pyramiden', 'ancient technology', 'megalithic', 'ancient aliens'],
    historicalContext: 'Große Pyramide von Gizeh ca. 2560 v. Chr. erbaut.',
    relatedNarratives: ['atlantis', 'ancient_aliens']
  },
};

/**
 * Get all narratives with categories
 */
export function getAllNarratives() {
  return Object.values(ENHANCED_NARRATIVE_DATABASE);
}

/**
 * Get narratives by category
 */
export function getNarrativesByCategory(categoryId) {
  return Object.values(ENHANCED_NARRATIVE_DATABASE).filter(narrative =>
    narrative.categories.some(cat => cat.id === categoryId)
  );
}

/**
 * Get all categories
 */
export function getAllCategories() {
  return Object.values(CATEGORIES);
}

/**
 * Search narratives
 */
export function searchNarratives(query) {
  query = query.toLowerCase();
  
  return Object.values(ENHANCED_NARRATIVE_DATABASE).filter(narrative => {
    return narrative.keywords.some(keyword => query.includes(keyword)) ||
           narrative.title.toLowerCase().includes(query);
  }).sort((a, b) => a.priority - b.priority);
}

/**
 * Get narrative by ID
 */
export function getNarrativeById(id) {
  return ENHANCED_NARRATIVE_DATABASE[id] || null;
}

/**
 * Get related narratives
 */
export function getRelatedNarratives(narrativeId) {
  const narrative = ENHANCED_NARRATIVE_DATABASE[narrativeId];
  if (!narrative || !narrative.relatedNarratives) return [];
  
  return narrative.relatedNarratives
    .map(id => ENHANCED_NARRATIVE_DATABASE[id])
    .filter(n => n !== undefined);
}

export { ENHANCED_NARRATIVE_DATABASE, CATEGORIES };
