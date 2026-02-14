/// 🧪 MODE SELECTOR TEST SCREEN
/// 
/// Simple test screen to preview ModeSelector widget
library;

import 'package:flutter/material.dart';
import '../models/recherche_view_state.dart';
import '../widgets/recherche/mode_selector.dart';

class ModeSelectorTestScreen extends StatefulWidget {
  const ModeSelectorTestScreen({super.key});

  @override
  State<ModeSelectorTestScreen> createState() => _ModeSelectorTestScreenState();
}

class _ModeSelectorTestScreenState extends State<ModeSelectorTestScreen> {
  RechercheMode _selectedMode = RechercheMode.simple;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎯 Mode Selector Test'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Mode Selector Widget
          ModeSelector(
            selectedMode: _selectedMode,
            onModeSelected: (mode) {
              setState(() {
                _selectedMode = mode;
              });
            },
          ),
          
          // Display selected mode info
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getModeIcon(_selectedMode),
                    size: 64,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Selected Mode:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getModeDisplayName(_selectedMode),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _getModeDescription(_selectedMode),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getModeIcon(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return Icons.search;
      case RechercheMode.advanced:
        return Icons.auto_awesome;
      case RechercheMode.deep:
        return Icons.psychology;
      case RechercheMode.conspiracy:
        return Icons.visibility;
      case RechercheMode.historical:
        return Icons.history_edu;
      case RechercheMode.scientific:
        return Icons.science;
    }
  }

  String _getModeDisplayName(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return 'Simple Search';
      case RechercheMode.advanced:
        return 'Advanced Research';
      case RechercheMode.deep:
        return 'Deep Dive';
      case RechercheMode.conspiracy:
        return 'Conspiracy Mode';
      case RechercheMode.historical:
        return 'Historical Research';
      case RechercheMode.scientific:
        return 'Scientific Research';
    }
  }

  String _getModeDescription(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return 'Quick and straightforward search with basic results';
      case RechercheMode.advanced:
        return 'Extended research with advanced filters and cross-referencing';
      case RechercheMode.deep:
        return 'Deep dive research with multiple layers and comprehensive analysis';
      case RechercheMode.conspiracy:
        return 'Explore alternative theories and hidden connections';
      case RechercheMode.historical:
        return 'Research historical documents and events';
      case RechercheMode.scientific:
        return 'Academic research with peer-reviewed sources';
    }
  }
}
