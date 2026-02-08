/// 🎛️ VOICE FILTERS PANEL
/// UI for selecting and configuring voice filters
library;

import 'package:flutter/material.dart';
import '../services/voice_filters_service.dart';

class VoiceFiltersPanel extends StatefulWidget {
  final VoiceFiltersService filtersService;

  const VoiceFiltersPanel({
    super.key,
    required this.filtersService,
  });

  @override
  State<VoiceFiltersPanel> createState() => _VoiceFiltersPanelState();
}

class _VoiceFiltersPanelState extends State<VoiceFiltersPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Text(
                '🎛️ Voice-Filter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Filter Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: VoiceFilter.values.length,
            itemBuilder: (context, index) {
              final filter = VoiceFilter.values[index];
              final isActive = widget.filtersService.currentFilter == filter;

              return GestureDetector(
                onTap: () async {
                  await widget.filtersService.applyFilter(filter);
                  setState(() {});
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.greenAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? Colors.greenAccent
                          : Colors.white.withValues(alpha: 0.1),
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.filtersService.getFilterIcon(filter),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.filtersService.getFilterName(filter),
                        style: TextStyle(
                          color: isActive ? Colors.greenAccent : Colors.white,
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Filter Settings (for active filter)
          if (widget.filtersService.currentFilter != VoiceFilter.none)
            _buildFilterSettings(),
        ],
      ),
    );
  }

  /// ⚙️ Filter Settings
  Widget _buildFilterSettings() {
    final filter = widget.filtersService.currentFilter;

    switch (filter) {
      case VoiceFilter.echo:
        return _buildEchoSettings();
      case VoiceFilter.bassBoost:
        return _buildBassSettings();
      case VoiceFilter.noiseGate:
        return _buildNoiseGateSettings();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 🔊 Echo Settings
  Widget _buildEchoSettings() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Echo Einstellungen',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSlider(
          label: 'Verzögerung',
          value: widget.filtersService.echoDelay,
          min: 0.1,
          max: 2.0,
          onChanged: (value) {
            widget.filtersService.setEchoParameters(
              delay: value,
              decay: widget.filtersService.echoDecay,
            );
            setState(() {});
          },
        ),
        _buildSlider(
          label: 'Wiederholung',
          value: widget.filtersService.echoDecay,
          min: 0.0,
          max: 1.0,
          onChanged: (value) {
            widget.filtersService.setEchoParameters(
              delay: widget.filtersService.echoDelay,
              decay: value,
            );
            setState(() {});
          },
        ),
      ],
    );
  }

  /// 🎸 Bass Settings
  Widget _buildBassSettings() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Bass Boost',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSlider(
          label: 'Verstärkung',
          value: widget.filtersService.bassGain,
          min: 1.0,
          max: 3.0,
          onChanged: (value) {
            widget.filtersService.setBassGain(value);
            setState(() {});
          },
        ),
      ],
    );
  }

  /// 🔇 Noise Gate Settings
  Widget _buildNoiseGateSettings() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Rauschunterdrückung',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSlider(
          label: 'Schwellenwert',
          value: widget.filtersService.noiseThreshold,
          min: 0.0,
          max: 0.1,
          onChanged: (value) {
            widget.filtersService.setNoiseThreshold(value);
            setState(() {});
          },
        ),
      ],
    );
  }

  /// 🎚️ Slider Widget
  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              value.toStringAsFixed(2),
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.greenAccent,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            thumbColor: Colors.greenAccent,
            overlayColor: Colors.greenAccent.withValues(alpha: 0.3),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// Show Panel
  static Future<void> show(
    BuildContext context,
    VoiceFiltersService filtersService,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => VoiceFiltersPanel(
        filtersService: filtersService,
      ),
    );
  }
}
