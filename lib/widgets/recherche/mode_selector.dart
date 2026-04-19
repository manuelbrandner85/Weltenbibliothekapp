/// 🎯 MODE SELECTOR WIDGET
/// 
/// Recherche mode selection widget with:
/// - 6 different research modes (Simple, Advanced, Deep, Conspiracy, Historical, Scientific)
/// - Interactive Material Chips with icons
/// - Active mode highlighting with primary color
/// - Horizontal scrollbar support
/// - Integration with RechercheController
library;

import 'package:flutter/material.dart';
import '../../models/recherche_view_state.dart';

class ModeSelector extends StatelessWidget {
  final RechercheMode selectedMode;
  final ValueChanged<RechercheMode> onModeSelected;
  
  const ModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _buildModeChip(
            context,
            mode: RechercheMode.simple,
            icon: Icons.search,
            label: 'Simple',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            context,
            mode: RechercheMode.advanced,
            icon: Icons.auto_awesome,
            label: 'Advanced',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            context,
            mode: RechercheMode.deep,
            icon: Icons.psychology,
            label: 'Deep',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            context,
            mode: RechercheMode.conspiracy,
            icon: Icons.visibility,
            label: 'Conspiracy',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            context,
            mode: RechercheMode.historical,
            icon: Icons.history_edu,
            label: 'Historical',
          ),
          const SizedBox(width: 8),
          _buildModeChip(
            context,
            mode: RechercheMode.scientific,
            icon: Icons.science,
            label: 'Scientific',
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeChip(
    BuildContext context, {
    required RechercheMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = selectedMode == mode;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onModeSelected(mode),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? primaryColor
                  : Theme.of(context).dividerColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : Colors.grey[700],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
