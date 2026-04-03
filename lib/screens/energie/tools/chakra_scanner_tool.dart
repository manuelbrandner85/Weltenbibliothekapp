import 'package:flutter/material.dart';

class ChakraScannerTool extends StatefulWidget {
  const ChakraScannerTool({super.key});
  @override
  State<ChakraScannerTool> createState() => _ChakraScannerToolState();
}

class _ChakraScannerToolState extends State<ChakraScannerTool> {
  final List<Map<String, dynamic>> _chakras = [
    {'name': 'Kronenchakra', 'color': Colors.purple, 'symbol': '👑', 'frequency': '963 Hz'},
    {'name': 'Stirnchakra', 'color': Colors.indigo, 'symbol': '👁️', 'frequency': '852 Hz'},
    {'name': 'Halschakra', 'color': Colors.blue, 'symbol': '🗣️', 'frequency': '741 Hz'},
    {'name': 'Herzchakra', 'color': Colors.green, 'symbol': '💚', 'frequency': '639 Hz'},
    {'name': 'Solarplexus', 'color': Colors.yellow, 'symbol': '☀️', 'frequency': '528 Hz'},
    {'name': 'Sakralchakra', 'color': Colors.orange, 'symbol': '🔥', 'frequency': '417 Hz'},
    {'name': 'Wurzelchakra', 'color': Colors.red, 'symbol': '🌱', 'frequency': '396 Hz'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🌈 Chakra-Scanner'), backgroundColor: Colors.purple),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chakras.length,
        itemBuilder: (context, index) {
          final chakra = _chakras[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: chakra['color'], child: Text(chakra['symbol'], style: const TextStyle(fontSize: 24))),
              title: Text(chakra['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text('Frequenz: ${chakra['frequency']}'),
              trailing: IconButton(icon: const Icon(Icons.info_outline), onPressed: () => _showChakraInfo(chakra)),
            ),
          );
        },
      ),
    );
  }

  void _showChakraInfo(Map<String, dynamic> chakra) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${chakra['symbol']} ${chakra['name']}'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Frequenz: ${chakra['frequency']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Meditation: Konzentriere dich auf dieses Energiezentrum und visualisiere seine Farbe.'),
        ]),
        actions: [ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: chakra['color']), child: const Text('OK'))],
      ),
    );
  }
}
