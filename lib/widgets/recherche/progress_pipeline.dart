/// 📊 PROGRESS PIPELINE WIDGET
/// 
/// Research progress visualization widget with:
/// - Real-time progress tracking (0.0 - 1.0)
/// - Mode-specific pipeline phases
/// - Animated progress indicators
/// - Current phase highlighting
/// - Estimated time remaining
/// - Cancel button integration
library;

import 'package:flutter/material.dart';
import '../../models/recherche_view_state.dart';

class ProgressPipeline extends StatelessWidget {
  final RechercheMode mode;
  final double progress;
  final DateTime? startedAt;
  final VoidCallback? onCancel;
  
  const ProgressPipeline({
    super.key,
    required this.mode,
    required this.progress,
    this.startedAt,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final phases = _getPhasesForMode(mode);
    final currentPhaseIndex = _getCurrentPhaseIndex(progress, phases.length);
    final elapsedSeconds = startedAt != null 
        ? DateTime.now().difference(startedAt!).inSeconds 
        : 0;
    final estimatedTotal = _estimateTotal(mode);
    final remainingSeconds = (estimatedTotal - elapsedSeconds).clamp(0, estimatedTotal);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with cancel button
          _buildHeader(context, remainingSeconds),
          
          // Progress bar
          _buildProgressBar(context),
          
          // Phases list
          _buildPhasesList(context, phases, currentPhaseIndex),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // HEADER
  // ==========================================================================
  
  Widget _buildHeader(BuildContext context, int remainingSeconds) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Spinning icon
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Title and time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recherche läuft...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  remainingSeconds > 0
                      ? 'Noch ca. ${remainingSeconds}s'
                      : 'Fast fertig...',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Cancel button
          if (onCancel != null)
            TextButton.icon(
              onPressed: onCancel,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Abbrechen'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red[700],
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
            ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // PROGRESS BAR
  // ==========================================================================
  
  Widget _buildProgressBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Progress percentage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Text(
                _getModeDisplayName(mode),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Animated progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // PHASES LIST
  // ==========================================================================
  
  Widget _buildPhasesList(
    BuildContext context,
    List<String> phases,
    int currentPhaseIndex,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pipeline-Phasen',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(phases.length, (index) {
            return _buildPhaseItem(
              context,
              phase: phases[index],
              index: index,
              currentPhaseIndex: currentPhaseIndex,
              isLast: index == phases.length - 1,
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildPhaseItem(
    BuildContext context, {
    required String phase,
    required int index,
    required int currentPhaseIndex,
    required bool isLast,
  }) {
    final isActive = index == currentPhaseIndex;
    final isCompleted = index < currentPhaseIndex;
    
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        children: [
          // Phase indicator
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted || isActive
                  ? Theme.of(context).primaryColor
                  : Colors.grey[300],
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : isActive
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
            ),
          ),
          const SizedBox(width: 12),
          
          // Phase text
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive
                    ? Theme.of(context).primaryColor
                    : isCompleted
                        ? Colors.grey[700]
                        : Colors.grey[500],
              ),
              child: Text(phase),
            ),
          ),
          
          // Active indicator
          if (isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
  
  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================
  
  List<String> _getPhasesForMode(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return [
          'Query verarbeiten',
          'Quellen sammeln',
          'Inhalte analysieren',
          'Zusammenfassung erstellen',
          'Finalisieren',
        ];
        
      case RechercheMode.advanced:
        return [
          'Query verarbeiten',
          'Primärquellen sammeln',
          'Kreuzreferenzen prüfen',
          'Tiefenanalyse',
          'Kontext anreichern',
          'Zusammenfassung erstellen',
          'Finalisieren',
        ];
        
      case RechercheMode.deep:
        return [
          'Query verarbeiten',
          'Oberflächenquellen',
          'Ebene 1 - Basis',
          'Ebene 2 - Vertiefung',
          'Ebene 3 - Details',
          'Muster erkennen',
          'Zusammenfassung erstellen',
          'Finalisieren',
        ];
        
      case RechercheMode.conspiracy:
        return [
          'Query verarbeiten',
          'Mainstream-Quellen',
          'Alternative Quellen',
          'Verbindungen erkennen',
          'Muster analysieren',
          'Zusammenfassung erstellen',
          'Finalisieren',
        ];
        
      case RechercheMode.historical:
        return [
          'Query verarbeiten',
          'Historische Dokumente',
          'Zeitliche Einordnung',
          'Kontext recherchieren',
          'Quellen verifizieren',
          'Zusammenfassung erstellen',
          'Finalisieren',
        ];
        
      case RechercheMode.scientific:
        return [
          'Query verarbeiten',
          'Peer-Review Quellen',
          'Studien analysieren',
          'Methodik prüfen',
          'Evidenz bewerten',
          'Zusammenfassung erstellen',
          'Finalisieren',
        ];
    }
  }
  
  int _getCurrentPhaseIndex(double progress, int totalPhases) {
    final index = (progress * totalPhases).floor();
    return index.clamp(0, totalPhases - 1);
  }
  
  int _estimateTotal(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return 15; // 15 Sekunden
      case RechercheMode.advanced:
        return 30; // 30 Sekunden
      case RechercheMode.deep:
        return 45; // 45 Sekunden
      case RechercheMode.conspiracy:
        return 35; // 35 Sekunden
      case RechercheMode.historical:
        return 40; // 40 Sekunden
      case RechercheMode.scientific:
        return 50; // 50 Sekunden
    }
  }
  
  String _getModeDisplayName(RechercheMode mode) {
    switch (mode) {
      case RechercheMode.simple:
        return 'Simple Recherche';
      case RechercheMode.advanced:
        return 'Advanced Recherche';
      case RechercheMode.deep:
        return 'Deep Dive Recherche';
      case RechercheMode.conspiracy:
        return 'Conspiracy Recherche';
      case RechercheMode.historical:
        return 'Historical Recherche';
      case RechercheMode.scientific:
        return 'Scientific Recherche';
    }
  }
}
