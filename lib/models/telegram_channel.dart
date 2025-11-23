/// Telegram-Kanal Model
class TelegramChannel {
  final String id;
  final String name;
  final String description;
  final String url;
  final String emoji;
  final String category;

  TelegramChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.emoji,
    required this.category,
  });

  /// Die 6 offiziellen Weltenbibliothek Telegram-Kanäle
  static List<TelegramChannel> getOfficialChannels() {
    return [
      TelegramChannel(
        id: 'weltenbibliothekchat',
        name: 'Weltenbibliothek Chat',
        description: 'Hauptkanal für Diskussionen und Austausch',
        url: 'https://t.me/Weltenbibliothekchat',
        emoji: '💬',
        category: 'Chat',
      ),
      TelegramChannel(
        id: 'archivweltenbibliothek',
        name: 'Archiv Weltenbibliothek',
        description: 'Historische Dokumente und Archive',
        url: 'https://t.me/ArchivWeltenBibliothek',
        emoji: '📚',
        category: 'Archiv',
      ),
      TelegramChannel(
        id: 'weltenbibliothekpdf',
        name: 'Weltenbibliothek PDF',
        description: 'PDF-Dokumente, Bücher und Schriften',
        url: 'https://t.me/WeltenbibliothekPDF',
        emoji: '📄',
        category: 'Dokumente',
      ),
      TelegramChannel(
        id: 'weltenbibliothekbilder',
        name: 'Weltenbibliothek Bilder',
        description: 'Bildmaterial, Fotografien und Illustrationen',
        url: 'https://t.me/weltenbibliothekbilder',
        emoji: '🖼️',
        category: 'Bilder',
      ),
      TelegramChannel(
        id: 'weltenbibliothekwachauf',
        name: 'Weltenbibliothek Wachauf',
        description: 'Bewusstsein, Aufklärung und Wissen',
        url: 'https://t.me/WeltenbibliothekWachauf',
        emoji: '👁️',
        category: 'Bewusstsein',
      ),
      TelegramChannel(
        id: 'weltenbibliothekhoerbuch',
        name: 'Weltenbibliothek Hörbuch',
        description: 'Hörbücher, Audio-Inhalte und Podcasts',
        url: 'https://t.me/WeltenbibliothekHoerbuch',
        emoji: '🎧',
        category: 'Audio',
      ),
    ];
  }
}
