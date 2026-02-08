/// WELTENBIBLIOTHEK v5.9 – USER-PROFIL-EINSTELLUNGEN
/// 
/// UI für personalisierte Recherche-Einstellungen
library;

import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class UserProfileSettingsDialog extends StatefulWidget {
  final UserProfile initialProfile;
  
  const UserProfileSettingsDialog({
    super.key,
    required this.initialProfile,
  });
  
  @override
  State<UserProfileSettingsDialog> createState() => _UserProfileSettingsDialogState();
}

class _UserProfileSettingsDialogState extends State<UserProfileSettingsDialog> {
  late String _selectedDepth;
  late List<String> _selectedSources;
  late String _selectedView;
  late Map<String, double> _weights;
  
  @override
  void initState() {
    super.initState();
    _selectedDepth = widget.initialProfile.preferredDepth;
    _selectedSources = List.from(widget.initialProfile.preferredSources);
    _selectedView = widget.initialProfile.preferredView;
    _weights = Map.from(widget.initialProfile.interactionWeights);
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[700]!, Colors.blue[900]!],
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'BENUTZER-PROFIL',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // RECHERCHE-TIEFE
                    _buildSectionHeader('Recherche-Tiefe'),
                    const SizedBox(height: 12),
                    _buildDepthSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // BEVORZUGTE QUELLEN
                    _buildSectionHeader('Bevorzugte Quellen'),
                    const SizedBox(height: 12),
                    _buildSourceSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // BEVORZUGTE SICHTWEISE
                    _buildSectionHeader('Bevorzugte Sichtweise'),
                    const SizedBox(height: 12),
                    _buildViewSelector(),
                    
                    const SizedBox(height: 24),
                    
                    // GEWICHTUNGEN (Optional)
                    _buildSectionHeader('Erweiterte Gewichtungen (Optional)'),
                    const SizedBox(height: 12),
                    _buildWeightsEditor(),
                    
                    const SizedBox(height: 24),
                    
                    // VORDEFINIERTE PROFILE
                    _buildSectionHeader('Vordefinierte Profile'),
                    const SizedBox(height: 12),
                    _buildPresetProfiles(),
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Abbrechen'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Speichern'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }
  
  Widget _buildDepthSelector() {
    return Column(
      children: ResearchDepth.values.map((depth) {
        final isSelected = _selectedDepth == depth.label.toLowerCase();
        return RadioListTile<String>(
          title: Text(depth.label),
          subtitle: Text(depth.description),
          value: depth.label.toLowerCase(),
          groupValue: _selectedDepth,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedDepth = value);
            }
          },
          selected: isSelected,
          activeColor: Colors.blue[700],
        );
      }).toList(),
    );
  }
  
  Widget _buildSourceSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SourceType.values.map((source) {
        final sourceKey = source.label.toLowerCase();
        final isSelected = _selectedSources.contains(sourceKey);
        
        return FilterChip(
          label: Text(source.label),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedSources.add(sourceKey);
              } else {
                _selectedSources.remove(sourceKey);
              }
            });
          },
          selectedColor: Colors.blue[100],
          checkmarkColor: Colors.blue[700],
        );
      }).toList(),
    );
  }
  
  Widget _buildViewSelector() {
    return Column(
      children: ViewPreference.values.map((view) {
        final isSelected = _selectedView == view.label.toLowerCase();
        return RadioListTile<String>(
          title: Text(view.label),
          subtitle: Text(view.description),
          value: view.label.toLowerCase(),
          groupValue: _selectedView,
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedView = value);
            }
          },
          selected: isSelected,
          activeColor: Colors.blue[700],
        );
      }).toList(),
    );
  }
  
  Widget _buildWeightsEditor() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interaktions-Gewichtungen (1.0 = Standard)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          ...SourceType.values.map((source) {
            final sourceKey = source.label.toLowerCase();
            final weight = _weights[sourceKey] ?? 1.0;
            
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        source.label,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Slider(
                        value: weight,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: weight.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _weights[sourceKey] = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(
                      width: 50,
                      child: Text(
                        weight.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildPresetProfiles() {
    return Column(
      children: [
        _buildPresetButton(
          'Standard-Profil',
          'Ausgewogene Einstellungen',
          Icons.balance,
          UserProfile.defaultProfile(),
        ),
        const SizedBox(height: 8),
        _buildPresetButton(
          'Tiefe Recherche',
          'Für umfassende Analysen',
          Icons.search,
          UserProfile.deepResearchProfile(),
        ),
        const SizedBox(height: 8),
        _buildPresetButton(
          'Schnelle Übersicht',
          'Für rasche Informationen',
          Icons.speed,
          UserProfile.quickOverviewProfile(),
        ),
      ],
    );
  }
  
  Widget _buildPresetButton(
    String title,
    String description,
    IconData icon,
    UserProfile preset,
  ) {
    return OutlinedButton(
      onPressed: () {
        setState(() {
          _selectedDepth = preset.preferredDepth;
          _selectedSources = List.from(preset.preferredSources);
          _selectedView = preset.preferredView;
          _weights = Map.from(preset.interactionWeights);
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _saveProfile() {
    final newProfile = UserProfile(
      preferredDepth: _selectedDepth,
      preferredSources: _selectedSources,
      preferredView: _selectedView,
      interactionWeights: _weights,
    );
    
    Navigator.of(context).pop(newProfile);
  }
}

/// Profil-Badge Widget (zeigt aktuelles Profil)
class UserProfileBadge extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onTap;
  
  const UserProfileBadge({
    super.key,
    required this.profile,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 16, color: Colors.blue[700]),
            const SizedBox(width: 6),
            Text(
              _getProfileLabel(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.blue[700]),
          ],
        ),
      ),
    );
  }
  
  String _getProfileLabel() {
    // Bestimme Label basierend auf Einstellungen
    if (profile.preferredDepth == 'tief' && 
        profile.preferredSources.contains('archive')) {
      return 'Tiefe Recherche';
    } else if (profile.preferredDepth == 'oberflächlich') {
      return 'Schnellübersicht';
    }
    return 'Standard';
  }
}
