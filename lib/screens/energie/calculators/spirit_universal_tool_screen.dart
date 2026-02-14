import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import '../../../models/energie_profile.dart';
import '../../../core/storage/unified_storage_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/spirit_calculations/all_spirit_tools_engine.dart';
import '../../../models/spirit_tool_results.dart';
import '../../../widgets/profile_required_widget.dart';

/// Universal Spirit-Tool Screen
/// Funktioniert für alle 10 neuen Tools
class SpiritUniversalToolScreen extends StatefulWidget {
  final String toolName;
  final IconData toolIcon;
  final Color toolColor;
  final String toolType; // 'energy_field', 'polarity', 'transformation', etc.

  const SpiritUniversalToolScreen({
    super.key,
    required this.toolName,
    required this.toolIcon,
    required this.toolColor,
    required this.toolType,
  });

  @override
  State<SpiritUniversalToolScreen> createState() => _SpiritUniversalToolScreenState();
}

class _SpiritUniversalToolScreenState extends State<SpiritUniversalToolScreen> {
  final StorageService _storage = StorageService();
  EnergieProfile? _profile;
  bool _isCalculating = false;
  dynamic _result; // Kann jeder Result-Typ sein

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    var profile = await _storage.loadEnergieProfile();
    
    // 🎯 AUTO-CREATE DEMO PROFILE if none exists
    if (profile == null) {
      profile = EnergieProfile(
        username: 'Manuel',
        firstName: 'Manuel',
        lastName: 'Brandner',
        birthDate: DateTime(1985, 6, 15), // Demo birth date
        birthPlace: 'Wien, Österreich',
        birthTime: '14:30',
      );
      
      // Save demo profile
      await _storage.saveEnergieProfile(profile);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demo Energie-Profil automatisch erstellt!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
    
    if (mounted) {
      setState(() {
        _profile = profile;
      });
    }
  }

  Future<void> _calculate() async {
    if (kDebugMode) {
      debugPrint('🔍 _calculate() called with toolType: ${widget.toolType}');
    }
    
    if (_profile == null) {
      if (kDebugMode) {
        debugPrint('❌ _calculate() aborted: _profile is null');
      }
      return;
    }

    if (kDebugMode) {
      debugPrint('✅ Profile exists: ${_profile!.firstName} ${_profile!.lastName}');
    }

    setState(() {
      _isCalculating = true;
    });

    if (kDebugMode) {
      debugPrint('🔄 _isCalculating set to true');
    }

    try {
      dynamic result;
      switch (widget.toolType) {
        case 'energy_field':
          if (kDebugMode) {
            debugPrint('📊 Calculating energy_field...');
          }
          result = AllSpiritToolsEngine.calculateEnergyField(_profile!);
          if (kDebugMode) {
            debugPrint('✅ Energy field calculated: $result');
          }
          break;
        case 'polarity':
          result = AllSpiritToolsEngine.calculatePolarity(_profile!);
          break;
        case 'transformation':
          result = AllSpiritToolsEngine.calculateTransformation(_profile!);
          break;
        case 'unconscious':
          result = AllSpiritToolsEngine.calculateUnconscious(_profile!);
          break;
        case 'inner_maps':
          result = AllSpiritToolsEngine.calculateInnerMaps(_profile!);
          break;
        case 'cycles':
          result = AllSpiritToolsEngine.calculateCycles(_profile!);
          break;
        case 'orientation':
          result = AllSpiritToolsEngine.calculateOrientation(_profile!);
          break;
        case 'meta_mirror':
          result = AllSpiritToolsEngine.calculateMetaMirror(_profile!);
          break;
        case 'perception':
          result = AllSpiritToolsEngine.calculatePerception(_profile!);
          break;
        case 'self_observation':
          result = AllSpiritToolsEngine.calculateSelfObservation(_profile!);
          break;
      }

      if (kDebugMode) {
        debugPrint('✅ Result calculated successfully!');
        debugPrint('Result type: ${result?.runtimeType}');
        debugPrint('Result: $result');
      }

      if (mounted) {
        setState(() {
          _result = result;
          _isCalculating = false;
        });
        
        if (kDebugMode) {
          debugPrint('✅ UI updated with result');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ ERROR in _calculate(): $e');
        debugPrint('Stack trace: ${StackTrace.current}');
      }
      
      if (mounted) {
        setState(() {
          _isCalculating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler bei der Berechnung: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Icon(widget.toolIcon, color: widget.toolColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.toolName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: _profile == null
            ? ProfileRequiredWidget(
                worldType: 'energie',
                message: 'Energie-Profil erforderlich',
                onProfileCreated: _loadProfile,
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.toolColor.withValues(alpha: 0.2), widget.toolColor.withValues(alpha: 0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: widget.toolColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: widget.toolColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(widget.toolIcon, color: widget.toolColor, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.toolName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_profile!.firstName} ${_profile!.lastName}',
                                  style: TextStyle(
                                    color: widget.toolColor.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Berechnen-Button mit DEBUG INFO
                    if (_result == null)
                      Column(
                        children: [
                          // 🔍 DEBUG INFO CARD (nur im Debug-Modus sichtbar)
                          if (kDebugMode)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.yellow.withValues(alpha: 0.5), width: 2),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.bug_report, color: Colors.yellow, size: 20),
                                      const SizedBox(width: 8),
                                      Text('DEBUG INFO', style: TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDebugRow('Profile', _profile != null ? '✅ ${_profile!.firstName} ${_profile!.lastName}' : '❌ NULL'),
                                  _buildDebugRow('IsCalculating', _isCalculating ? '🔄 TRUE (Button disabled)' : '⏸️ FALSE (Button enabled)'),
                                  _buildDebugRow('Result', _result != null ? '✅ EXISTS' : '❌ NULL'),
                                  _buildDebugRow('ToolType', widget.toolType),
                                  _buildDebugRow('Mounted', mounted ? '✅ TRUE' : '❌ FALSE'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '👆 Klicke den Button und beobachte die Console (F12)',
                                    style: TextStyle(color: Colors.yellow.withValues(alpha: 0.7), fontSize: 11, fontStyle: FontStyle.italic),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          
                          // Button mit vollständiger Syntax
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                          onPressed: () {
                            if (kDebugMode) {
                              debugPrint('\n════════════════════════════════════════');
                              debugPrint('🖱️  BUTTON CLICKED!');
                              debugPrint('════════════════════════════════════════');
                              debugPrint('  Time: ${DateTime.now().toIso8601String()}');
                              debugPrint('  _isCalculating: $_isCalculating');
                              debugPrint('  _profile: ${_profile?.firstName} ${_profile?.lastName}');
                              debugPrint('  _result: ${_result?.runtimeType ?? "NULL"}');
                              debugPrint('  widget.toolType: ${widget.toolType}');
                              debugPrint('  mounted: $mounted');
                              debugPrint('════════════════════════════════════════\n');
                            }
                            
                            if (_isCalculating) {
                              if (kDebugMode) {
                                debugPrint('⚠️  BUTTON CLICK IGNORED: Already calculating');
                              }
                              return;
                            }
                            
                            if (_profile == null) {
                              if (kDebugMode) {
                                debugPrint('⚠️  BUTTON CLICK IGNORED: Profile is NULL');
                              }
                              return;
                            }
                            
                            if (kDebugMode) {
                              debugPrint('✅ Calling _calculate()...');
                            }
                            _calculate();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.toolColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isCalculating
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(widget.toolIcon, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Berechnung starten',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      ],
                    ),

                    // Ergebnis
                    if (_result != null) ...[
                      _buildResultSection(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _calculate,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: widget.toolColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.refresh, color: widget.toolColor, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Neu berechnen',
                                style: TextStyle(color: widget.toolColor, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Interpretation (hervorgehoben)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.toolColor.withValues(alpha: 0.2), widget.toolColor.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.toolColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: widget.toolColor, size: 24),
                  const SizedBox(width: 8),
                  const Text(
                    'Interpretation',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _getInterpretation(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Details
        _buildDetailCards(),
      ],
    );
  }

  String _getInterpretation() {
    if (_result is EnergyFieldToolResult) return _result.interpretation;
    if (_result is PolarityToolResult) return _result.interpretation;
    if (_result is TransformationToolResult) return _result.interpretation;
    if (_result is UnconsciousToolResult) return _result.interpretation;
    if (_result is InnerMapsToolResult) return _result.interpretation;
    if (_result is CyclesToolResult) return _result.interpretation;
    if (_result is OrientationToolResult) return _result.interpretation;
    if (_result is MetaMirrorToolResult) return _result.interpretation;
    if (_result is PerceptionToolResult) return _result.interpretation;
    if (_result is SelfObservationToolResult) return _result.interpretation;
    return 'Keine Interpretation verfügbar';
  }

  Widget _buildDetailCards() {
    switch (widget.toolType) {
      case 'energy_field':
        return _buildEnergyFieldDetails();
      case 'polarity':
        return _buildPolarityDetails();
      case 'transformation':
        return _buildTransformationDetails();
      case 'unconscious':
        return _buildUnconsciousDetails();
      case 'inner_maps':
        return _buildInnerMapsDetails();
      case 'cycles':
        return _buildCyclesDetails();
      case 'orientation':
        return _buildOrientationDetails();
      case 'meta_mirror':
        return _buildMetaMirrorDetails();
      case 'perception':
        return _buildPerceptionDetails();
      case 'self_observation':
        return _buildSelfObservationDetails();
      default:
        return const SizedBox();
    }
  }

  Widget _buildEnergyFieldDetails() {
    final result = _result as EnergyFieldToolResult;
    return Column(
      children: [
        _buildValueCard('Gesamt-Feldstärke', '${result.overallFieldStrength.toStringAsFixed(0)}%', Icons.bolt),
        _buildValueCard('Feldqualität', result.fieldQuality, Icons.graphic_eq),
        _buildValueCard('Kohärenz', '${result.coherence.toStringAsFixed(0)}%', Icons.sync),
        _buildValueCard('Stabilität', result.stabilityLevel, Icons.shield),
        _buildValueCard('Energiefluss', result.energyFlow, Icons.water_drop),
        if (result.resonantPoints.isNotEmpty) _buildListCard('Resonanzpunkte', result.resonantPoints, Icons.star),
        if (result.activeZones.isNotEmpty) _buildListCard('Aktive Zonen', result.activeZones, Icons.flash_on),
      ],
    );
  }

  Widget _buildPolarityDetails() {
    final result = _result as PolarityToolResult;
    return Column(
      children: [
        _buildValueCard('Yin-Anteil', '${result.yinScore.toStringAsFixed(0)}%', Icons.nights_stay),
        _buildValueCard('Yang-Anteil', '${result.yangScore.toStringAsFixed(0)}%', Icons.wb_sunny),
        _buildValueCard('Balance-Verhältnis', '${(result.balanceRatio * 100).toStringAsFixed(0)}%', Icons.balance),
        _buildValueCard('Dominanter Pol', result.dominantPole, Icons.adjust),
        _buildValueCard('Balance-Zustand', result.balanceState, Icons.analytics),
        if (result.tensionPoints.isNotEmpty) _buildListCard('Spannungsachsen', result.tensionPoints, Icons.warning_amber),
      ],
    );
  }

  Widget _buildTransformationDetails() {
    final result = _result as TransformationToolResult;
    return Column(
      children: [
        _buildValueCard('Aktuelle Stufe', '${result.currentStage} - ${result.stageName}', Icons.stairs),
        _buildValueCard('Fortschritt', '${result.stageProgress.toStringAsFixed(0)}%', Icons.trending_up),
        _buildValueCard('Reifegrad', result.maturityLevel, Icons.psychology),
        _buildValueCard('Prozessintensität', result.processIntensity, Icons.speed),
        if (result.transitionMarkers.isNotEmpty) _buildListCard('Übergangsmarker', result.transitionMarkers, Icons.flag),
        if (result.recurrentThemes.isNotEmpty) _buildListCard('Wiederkehrende Themen', result.recurrentThemes, Icons.loop),
      ],
    );
  }

  Widget _buildUnconsciousDetails() {
    final result = _result as UnconsciousToolResult;
    return Column(
      children: [
        _buildValueCard('Schatten-Stufe', '${result.shadowStage} - ${result.stageName}', Icons.dark_mode),
        _buildValueCard('Integration', '${result.integrationLevel.toStringAsFixed(0)}%', Icons.compress),
        _buildValueCard('Bewusstseinsgrad', result.awarenessLevel, Icons.visibility),
        if (result.repeatingPatterns.isNotEmpty) _buildListCard('Wiederkehrende Muster', result.repeatingPatterns, Icons.loop),
        if (result.projectionThemes.isNotEmpty) _buildListCard('Projektionsthemen', result.projectionThemes, Icons.theater_comedy),
        if (result.resistancePoints.isNotEmpty) _buildListCard('Widerstandspunkte', result.resistancePoints, Icons.block),
        if (result.integrationOpportunities.isNotEmpty) _buildListCard('Integrationschancen', result.integrationOpportunities, Icons.check_circle),
      ],
    );
  }

  Widget _buildInnerMapsDetails() {
    final result = _result as InnerMapsToolResult;
    return Column(
      children: [
        _buildValueCard('Spiralposition', '${result.spiralPosition.toStringAsFixed(0)}%', Icons.track_changes),
        _buildValueCard('Aktuelle Übung', result.currentExercise, Icons.explore),
        _buildValueCard('Navigations-Zustand', result.navigationState, Icons.explore),
        if (result.developmentAxes.isNotEmpty) _buildListCard('Entwicklungsachsen', result.developmentAxes, Icons.timeline),
        if (result.transitionZones.isNotEmpty) _buildListCard('Übergangszonen', result.transitionZones, Icons.merge_type),
        if (result.stillnessAreas.isNotEmpty) _buildListCard('Ruhebereiche', result.stillnessAreas, Icons.self_improvement),
        if (result.movementAreas.isNotEmpty) _buildListCard('Bewegungsbereiche', result.movementAreas, Icons.directions_run),
      ],
    );
  }

  Widget _buildCyclesDetails() {
    final result = _result as CyclesToolResult;
    return Column(
      children: [
        _buildValueCard('7-Jahres-Zyklus', 'Jahr ${result.cycle7Year}', Icons.calendar_today),
        _buildValueCard('Saturn-Phase', result.saturnPhase, Icons.public),
        _buildValueCard('Persönliches Jahr', '${result.personalYear}', Icons.event),
        _buildValueCard('Zyklus-Übereinstimmung', '${result.cycleAlignment.toStringAsFixed(0)}%', Icons.sync),
        _buildValueCard('Zeitqualität', result.timeQuality, Icons.access_time),
        _buildValueCard('Rhythmus-Zustand', result.rhythmState, Icons.graphic_eq),
        if (result.overlappingCycles.isNotEmpty) _buildListCard('Überlappende Zyklen', result.overlappingCycles, Icons.layers),
      ],
    );
  }

  Widget _buildOrientationDetails() {
    final result = _result as OrientationToolResult;
    return Column(
      children: [
        _buildValueCard('Entwicklungslevel', '${result.developmentLevel} - ${result.levelName}', Icons.trending_up),
        _buildValueCard('Fortschritt', '${result.levelProgress.toStringAsFixed(0)}%', Icons.show_chart),
        _buildValueCard('Stabilitäts-Zustand', result.stabilityState, Icons.shield),
        _buildValueCard('Prozessintensität', result.processIntensity, Icons.speed),
        if (result.pastLevels.isNotEmpty) _buildListCard('Durchlaufene Stufen', result.pastLevels, Icons.check),
        if (result.umbruchMarkers.isNotEmpty) _buildListCard('Umbruch-Marker', result.umbruchMarkers, Icons.change_circle),
      ],
    );
  }

  Widget _buildMetaMirrorDetails() {
    final result = _result as MetaMirrorToolResult;
    return Column(
      children: [
        _buildValueCard('Resonanzstärke', '${result.resonanceStrength.toStringAsFixed(0)}%', Icons.vibration),
        _buildValueCard('Fokus-Indikator', result.focusIndicator, Icons.center_focus_strong),
        _buildValueCard('Spiegel-Qualität', result.mirrorQuality, Icons.image_aspect_ratio),
        if (result.systemMirrors.isNotEmpty) _buildListCard('System-Spiegel', result.systemMirrors, Icons.grid_view),
        if (result.themeOverlays.isNotEmpty) _buildListCard('Themen-Überlagerungen', result.themeOverlays, Icons.layers),
        if (result.contradictions.isNotEmpty) _buildListCard('Widersprüche', result.contradictions, Icons.compare_arrows),
        if (result.amplifiedThemes.isNotEmpty) _buildListCard('Verstärkte Themen', result.amplifiedThemes, Icons.volume_up),
      ],
    );
  }

  Widget _buildPerceptionDetails() {
    final result = _result as PerceptionToolResult;
    return Column(
      children: [
        _buildValueCard('Wahrnehmungs-Stufe', '${result.perceptionStage} - ${result.stageName}', Icons.remove_red_eye),
        _buildValueCard('Flexibilitätsgrad', '${result.flexibilityDegree.toStringAsFixed(0)}%', Icons.settings_ethernet),
        _buildValueCard('Perspektiven-Reichweite', result.perspectiveRange, Icons.panorama),
        if (result.activeFilters.isNotEmpty) _buildListCard('Aktive Filter', result.activeFilters, Icons.filter_alt),
        if (result.interpretationPatterns.isNotEmpty) _buildListCard('Interpretations-Muster', result.interpretationPatterns, Icons.pattern),
        if (result.fixationPoints.isNotEmpty) _buildListCard('Fixierungspunkte', result.fixationPoints, Icons.push_pin),
      ],
    );
  }

  Widget _buildSelfObservationDetails() {
    final result = _result as SelfObservationToolResult;
    return Column(
      children: [
        _buildValueCard('Gesamt-Einträge', '${result.totalEntries}', Icons.list_alt),
        _buildValueCard('Beobachtungs-Qualität', result.observationQuality, Icons.remove_red_eye),
        _buildValueCard('Meta-kognitives Level', '${result.metacognitiveLevel.toStringAsFixed(0)}%', Icons.psychology),
        if (result.patternLog.isNotEmpty) _buildListCard('Muster-Log', result.patternLog, Icons.list),
        if (result.cycleNotes.isNotEmpty) _buildListCard('Zyklus-Notizen', result.cycleNotes, Icons.event_note),
        if (result.symbolTracker.isNotEmpty) _buildListCard('Symbol-Tracker', result.symbolTracker, Icons.tag),
        if (result.trackingFocus.isNotEmpty) _buildListCard('Tracking-Fokus', result.trackingFocus, Icons.center_focus_strong),
      ],
    );
  }

  Widget _buildValueCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.toolColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: widget.toolColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(String title, List<String> items, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.toolColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: widget.toolColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 36, bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle, color: widget.toolColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // 🔍 DEBUG: Helper Widget für Debug-Info-Zeilen
  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
