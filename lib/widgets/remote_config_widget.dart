import 'package:flutter/material.dart';
import '../services/openclaw_live_update_service.dart';

/// 🎨 REMOTE CONFIG WIDGET
/// 
/// Ermöglicht dynamische UI-Elemente basierend auf OpenClaw Remote Config:
/// - Texte können remote geändert werden
/// - Farben können remote angepasst werden
/// - Buttons können an/aus geschaltet werden
/// - Layouts können dynamisch angepasst werden
/// 
/// USAGE:
/// ```dart
/// RemoteConfigText(
///   configKey: 'home_title',
///   defaultText: 'Willkommen',
/// )
/// 
/// RemoteConfigButton(
///   configKey: 'premium_feature',
///   child: Text('Premium freischalten'),
///   onPressed: () => navigateToPremium(),
/// )
/// ```

class RemoteConfigText extends StatefulWidget {
  final String configKey;
  final String defaultText;
  final TextStyle? style;

  const RemoteConfigText({
    super.key,
    required this.configKey,
    required this.defaultText,
    this.style,
  });

  @override
  State<RemoteConfigText> createState() => _RemoteConfigTextState();
}

class _RemoteConfigTextState extends State<RemoteConfigText> {
  final _liveUpdate = OpenClawLiveUpdateService();
  late String _text;

  @override
  void initState() {
    super.initState();
    _text = _liveUpdate.getString(widget.configKey, defaultValue: widget.defaultText);
    
    // Live-Updates abonnieren
    _liveUpdate.updateStream.listen((_) {
      if (mounted) {
        setState(() {
          _text = _liveUpdate.getString(widget.configKey, defaultValue: widget.defaultText);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(_text, style: widget.style);
  }
}

/// 🔘 Remote Config Button - kann remote an/aus geschaltet werden
class RemoteConfigButton extends StatefulWidget {
  final String configKey;
  final Widget child;
  final VoidCallback? onPressed;
  final ButtonStyle? style;

  const RemoteConfigButton({
    super.key,
    required this.configKey,
    required this.child,
    this.onPressed,
    this.style,
  });

  @override
  State<RemoteConfigButton> createState() => _RemoteConfigButtonState();
}

class _RemoteConfigButtonState extends State<RemoteConfigButton> {
  final _liveUpdate = OpenClawLiveUpdateService();
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = _liveUpdate.isFeatureEnabled(widget.configKey);
    
    // Live-Updates abonnieren
    _liveUpdate.updateStream.listen((_) {
      if (mounted) {
        setState(() {
          _isEnabled = _liveUpdate.isFeatureEnabled(widget.configKey);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) return const SizedBox.shrink();
    
    return ElevatedButton(
      onPressed: widget.onPressed,
      style: widget.style,
      child: widget.child,
    );
  }
}

/// 🎨 Remote Config Color - Farbe remote änderbar
class RemoteConfigColor {
  static Color getColor(String configKey, {Color defaultColor = Colors.blue}) {
    final liveUpdate = OpenClawLiveUpdateService();
    final colorString = liveUpdate.getString(configKey, defaultValue: '');
    
    if (colorString.isEmpty) return defaultColor;
    
    // Parse Hex-Color (z.B. "#FF5733")
    if (colorString.startsWith('#')) {
      try {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        return defaultColor;
      }
    }
    
    return defaultColor;
  }
}

/// 🎭 Remote Config Widget - Zeigt/versteckt Widget basierend auf Feature-Flag
class RemoteConfigFeature extends StatefulWidget {
  final String featureName;
  final Widget child;
  final Widget? fallback;

  const RemoteConfigFeature({
    super.key,
    required this.featureName,
    required this.child,
    this.fallback,
  });

  @override
  State<RemoteConfigFeature> createState() => _RemoteConfigFeatureState();
}

class _RemoteConfigFeatureState extends State<RemoteConfigFeature> {
  final _liveUpdate = OpenClawLiveUpdateService();
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = _liveUpdate.isFeatureEnabled(widget.featureName);
    
    // Live-Updates abonnieren
    _liveUpdate.updateStream.listen((_) {
      if (mounted) {
        setState(() {
          _isEnabled = _liveUpdate.isFeatureEnabled(widget.featureName);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isEnabled) {
      return widget.child;
    }
    return widget.fallback ?? const SizedBox.shrink();
  }
}
