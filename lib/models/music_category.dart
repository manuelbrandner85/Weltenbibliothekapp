import 'package:flutter/material.dart';

/// 📂 Kategorie-Model für thematische Organisation
class ContentCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> keywords;

  ContentCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.keywords,
  });
}

/// 🗂️ Vordefinierte Kategorien für Alternative Forschung & Altes Wissen
final List<ContentCategory> defaultCategories = [
  ContentCategory(
    id: 'illuminati',
    name: 'Illuminati & Geheimgesellschaften',
    description: 'Verborgene Mächte, die die Welt lenken',
    icon: Icons.visibility_off,
    color: Colors.deepPurple,
    keywords: [
      'illuminati',
      'freemason',
      'geheimbund',
      'skull and bones',
      'bilderberg',
    ],
  ),
  ContentCategory(
    id: 'ancient_civilizations',
    name: 'Antike Zivilisationen',
    description: 'Atlantis, Ägypten, versunkene Kulturen',
    icon: Icons.account_balance,
    color: Colors.amber,
    keywords: ['atlantis', 'pyramiden', 'ägypten', 'sumerer', 'maya', 'antike'],
  ),
  ContentCategory(
    id: 'ufo_aliens',
    name: 'UFOs & Außerirdische',
    description: 'Begegnungen der dritten Art',
    icon: Icons.satellite_alt,
    color: Colors.green,
    keywords: ['ufo', 'aliens', 'roswell', 'area 51', 'außerirdische', 'greys'],
  ),
  ContentCategory(
    id: 'conspiracy_theories',
    name: 'Alternative Forschung',
    description: 'Verborgene Wahrheiten & alternative Perspektiven',
    icon: Icons.search,
    color: Colors.red,
    keywords: [
      'alternative theorien',
      'grenzwissenschaft',
      'deep state',
      'false flag',
      'kontrolle',
    ],
  ),
  ContentCategory(
    id: 'occult_mysticism',
    name: 'Okkultismus & Mystik',
    description: 'Verborgenes Wissen, Magie & Esoterik',
    icon: Icons.auto_fix_high,
    color: Colors.indigo,
    keywords: ['okkult', 'magie', 'esoterik', 'mystik', 'hermetik', 'alchemie'],
  ),
  ContentCategory(
    id: 'forbidden_history',
    name: 'Verbotene Geschichte',
    description: 'Unterdrückte historische Wahrheiten',
    icon: Icons.history_edu,
    color: Colors.brown,
    keywords: ['geschichte', 'tartaria', 'verboten', 'unterdrückt', 'history'],
  ),
  ContentCategory(
    id: 'spirituality',
    name: 'Spiritualität & Bewusstsein',
    description: 'Erwachen, Meditation & höheres Bewusstsein',
    icon: Icons.self_improvement,
    color: Colors.teal,
    keywords: [
      'spiritualität',
      'bewusstsein',
      'meditation',
      'erwachen',
      'chakra',
    ],
  ),
  ContentCategory(
    id: 'paranormal',
    name: 'Paranormales & Übernatürliches',
    description: 'Geister, PSI, unerklärliche Phänomene',
    icon: Icons.blur_on,
    color: Colors.purple,
    keywords: ['paranormal', 'geister', 'psi', 'telepathie', 'übernatürlich'],
  ),
];
