import 'package:flutter/material.dart';

class HeilfrequenzPlayerTool extends StatefulWidget {
  const HeilfrequenzPlayerTool({super.key});
  @override
  State<HeilfrequenzPlayerTool> createState() => _HeilfrequenzPlayerToolState();
}

class _HeilfrequenzPlayerToolState extends State<HeilfrequenzPlayerTool> {
  final List<Map<String, dynamic>> _frequencies = [
    {'name': '963 Hz - Göttliche Verbindung', 'color': Colors.purple, 'description': 'Kronenchakra, spirituelle Erleuchtung'},
    {'name': '852 Hz - Intuition', 'color': Colors.indigo, 'description': 'Stirnchakra, innere Weisheit'},
    {'name': '741 Hz - Ausdruck', 'color': Colors.blue, 'description': 'Halschakra, Selbstausdruck'},
    {'name': '639 Hz - Liebe & Harmonie', 'color': Colors.green, 'description': 'Herzchakra, Beziehungen'},
    {'name': '528 Hz - Transformation', 'color': Colors.yellow, 'description': 'Solarplexus, DNA-Heilung'},
    {'name': '417 Hz - Veränderung', 'color': Colors.orange, 'description': 'Sakralchakra, Kreativität'},
    {'name': '396 Hz - Befreiung', 'color': Colors.red, 'description': 'Wurzelchakra, Angst loslassen'},
    {'name': '432 Hz - Universalfrequenz', 'color': Colors.teal, 'description': 'Harmonie mit dem Universum'},
  ];

  String? _selectedFrequency;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎵 Heilfrequenz-Player'), backgroundColor: Colors.green),
      body: Column(
        children: [
          if (_selectedFrequency != null)
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.green[50],
              child: Column(children: [
                const Icon(Icons.graphic_eq, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                Text(_selectedFrequency!, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('🎵 Wird abgespielt...', style: TextStyle(color: Colors.green)),
                const SizedBox(height: 16),
                ElevatedButton.icon(onPressed: () => setState(() => _selectedFrequency = null), icon: const Icon(Icons.stop), label: const Text('Stopp'), style: ElevatedButton.styleFrom(backgroundColor: Colors.red)),
              ]),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _frequencies.length,
              itemBuilder: (context, index) {
                final freq = _frequencies[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: freq['color'], child: const Icon(Icons.music_note, color: Colors.white)),
                    title: Text(freq['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(freq['description']),
                    trailing: IconButton(icon: const Icon(Icons.play_arrow, color: Colors.green), onPressed: () => setState(() => _selectedFrequency = freq['name'])),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
