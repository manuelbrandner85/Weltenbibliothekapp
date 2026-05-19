import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../services/geocoding_service.dart';

/// Cinematic glassmorphism autocomplete field for selecting a birth place.
///
/// User types a city -> debounced search via [GeocodingService] hits the
/// OpenStreetMap Nominatim API -> a glassy dropdown shows up to 5 matches.
/// On tap, [onSelected] receives display name + lat/lng. If the user freely
/// edits the text without choosing a suggestion, [onSelected] is still
/// invoked on focus loss with `latitude == null && longitude == null`.
class BirthPlaceAutocomplete extends StatefulWidget {
  /// Initial value (e.g. from existing profile).
  final String initialPlace;
  final double? initialLatitude;
  final double? initialLongitude;

  /// World-specific accent color (used for border, glow, icons).
  final Color accentColor;

  /// Invoked when the user selects a suggestion OR loses focus with freely
  /// typed text. `latitude`/`longitude` are null when no geocoded match was
  /// chosen.
  final void Function(String place, double? latitude, double? longitude)
      onSelected;

  /// Optional label rendered above the field.
  final String? label;

  /// Hint text shown when the field is empty.
  final String hintText;

  const BirthPlaceAutocomplete({
    super.key,
    this.initialPlace = '',
    this.initialLatitude,
    this.initialLongitude,
    required this.accentColor,
    required this.onSelected,
    this.label,
    this.hintText = 'Stadt, Land...',
  });

  @override
  State<BirthPlaceAutocomplete> createState() => _BirthPlaceAutocompleteState();
}

class _BirthPlaceAutocompleteState extends State<BirthPlaceAutocomplete>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  Timer? _debounceTimer;
  bool _loading = false;
  List<GeocodedPlace> _suggestions = const [];
  String? _error;
  bool _showSuggestions = false;

  // Track whether the currently displayed text is backed by valid coords.
  double? _selectedLat;
  double? _selectedLng;
  String _lastCommittedText = '';

  // Used to discard out-of-order async responses.
  int _searchSeq = 0;

  static const int _minQueryLength = 2;
  static const int _maxResults = 5;
  static const Duration _debounceDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPlace);
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);

    _selectedLat = widget.initialLatitude;
    _selectedLng = widget.initialLongitude;
    _lastCommittedText = widget.initialPlace;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Field lost focus: commit free-typed text if it differs from the
      // last suggestion the user picked.
      final txt = _controller.text.trim();
      if (txt != _lastCommittedText) {
        _lastCommittedText = txt;
        widget.onSelected(txt, null, null);
        _selectedLat = null;
        _selectedLng = null;
      }
      _hideSuggestions();
    } else if (_suggestions.isNotEmpty) {
      _showSuggestionsList();
    }
  }

  void _onTextChanged(String value) {
    final query = value.trim();

    // If the text changes after a selection, the coordinates become stale.
    if (_selectedLat != null && query != _lastCommittedText) {
      setState(() {
        _selectedLat = null;
        _selectedLng = null;
      });
    }

    _debounceTimer?.cancel();

    if (query.length < _minQueryLength) {
      setState(() {
        _suggestions = const [];
        _error = null;
        _loading = false;
      });
      _hideSuggestions();
      return;
    }

    _debounceTimer = Timer(_debounceDuration, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    final mySeq = ++_searchSeq;
    setState(() {
      _loading = true;
      _error = null;
    });

    List<GeocodedPlace> results = const [];
    String? errorMsg;
    try {
      results = await GeocodingService.instance.searchPlace(query);
    } catch (_) {
      // Fall back to a direct Nominatim call if the service is unavailable
      // or throws (e.g. service not yet built or transient backend error).
      try {
        results = await _fallbackNominatimSearch(query);
      } catch (_) {
        errorMsg =
            'Suche aktuell nicht verfuegbar - du kannst auch frei tippen';
      }
    }

    if (!mounted || mySeq != _searchSeq) return;
    setState(() {
      _loading = false;
      _error = errorMsg;
      _suggestions = results.take(_maxResults).toList(growable: false);
    });

    if (_focusNode.hasFocus && (_suggestions.isNotEmpty || _error != null)) {
      _showSuggestionsList();
    } else {
      _hideSuggestions();
    }
  }

  /// Direct fallback to OSM Nominatim if the service layer is unavailable.
  Future<List<GeocodedPlace>> _fallbackNominatimSearch(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'json',
      'limit': '$_maxResults',
      'addressdetails': '1',
      'accept-language': 'de',
    });
    final resp = await http.get(
      uri,
      headers: const {
        'User-Agent': 'Weltenbibliothek/1.0 (geocoding-fallback)',
      },
    ).timeout(const Duration(seconds: 6));
    if (resp.statusCode != 200) {
      throw Exception('Nominatim ${resp.statusCode}');
    }
    final body = jsonDecode(resp.body);
    if (body is! List) return const [];
    final out = <GeocodedPlace>[];
    for (final raw in body) {
      if (raw is! Map) continue;
      final lat = double.tryParse('${raw['lat']}');
      final lon = double.tryParse('${raw['lon']}');
      final name = raw['display_name']?.toString();
      if (lat == null || lon == null || name == null || name.isEmpty) {
        continue;
      }
      final addr = raw['address'];
      String? country;
      String? region;
      if (addr is Map) {
        country = addr['country']?.toString();
        region =
            (addr['state'] ?? addr['region'] ?? addr['county'])?.toString();
      }
      out.add(GeocodedPlace(
        displayName: name,
        latitude: lat,
        longitude: lon,
        country: country,
        region: region,
      ));
    }
    return out;
  }

  void _showSuggestionsList() {
    if (_showSuggestions) return;
    setState(() => _showSuggestions = true);
    _animController.forward();
  }

  void _hideSuggestions() {
    if (!_showSuggestions) return;
    _animController.reverse().then((_) {
      if (!mounted) return;
      setState(() => _showSuggestions = false);
    });
  }

  void _onSuggestionTap(GeocodedPlace place) {
    HapticFeedback.selectionClick();
    _controller.text = place.displayName;
    _controller.selection = TextSelection.collapsed(
      offset: place.displayName.length,
    );
    _selectedLat = place.latitude;
    _selectedLng = place.longitude;
    _lastCommittedText = place.displayName;
    widget.onSelected(place.displayName, place.latitude, place.longitude);
    _hideSuggestions();
    _focusNode.unfocus();
  }

  void _onClear() {
    HapticFeedback.selectionClick();
    _controller.clear();
    setState(() {
      _suggestions = const [];
      _error = null;
      _selectedLat = null;
      _selectedLng = null;
    });
    _lastCommittedText = '';
    widget.onSelected('', null, null);
    _hideSuggestions();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor;
    final hasText = _controller.text.isNotEmpty;
    final coordsStale =
        _selectedLat == null && hasText && widget.initialLatitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              widget.label!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
        _buildTextField(accent, hasText),
        if (coordsStale)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline,
                    size: 12, color: Colors.amber.withValues(alpha: 0.9)),
                const SizedBox(width: 4),
                Text(
                  'Koordinaten zuruecksetzen?',
                  style: TextStyle(
                    color: Colors.amber.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        if (_showSuggestions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: _buildSuggestionsPanel(accent),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(Color accent, bool hasText) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.12),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            onTapOutside: (_) {
              if (_focusNode.hasFocus) _focusNode.unfocus();
            },
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: accent,
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.35),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: accent.withValues(alpha: 0.85),
                size: 22,
              ),
              suffixIcon: _buildSuffix(accent, hasText),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffix(Color accent, bool hasText) {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(accent),
          ),
        ),
      );
    }
    if (hasText) {
      return IconButton(
        icon: Icon(
          Icons.close_rounded,
          size: 18,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        onPressed: _onClear,
        splashRadius: 18,
        tooltip: 'Loeschen',
      );
    }
    return null;
  }

  Widget _buildSuggestionsPanel(Color accent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accent.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: _buildSuggestionsContent(accent),
        ),
      ),
    );
  }

  Widget _buildSuggestionsContent(Color accent) {
    if (_error != null) {
      return _buildInfoRow(
        icon: Icons.cloud_off_rounded,
        color: Colors.orangeAccent,
        text: _error!,
      );
    }
    if (_suggestions.isEmpty) {
      if (_loading) {
        return _buildInfoRow(
          icon: Icons.search_rounded,
          color: accent,
          text: 'Suche laeuft...',
        );
      }
      return _buildInfoRow(
        icon: Icons.travel_explore_rounded,
        color: Colors.white.withValues(alpha: 0.7),
        text: 'Keine Orte gefunden - tippe genauer oder waehle frei',
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _suggestions.length; i++) ...[
          _buildSuggestionTile(_suggestions[i], accent),
          if (i < _suggestions.length - 1)
            Divider(
              height: 1,
              thickness: 0.5,
              color: Colors.white.withValues(alpha: 0.08),
              indent: 16,
              endIndent: 16,
            ),
        ],
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionTile(GeocodedPlace place, Color accent) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onSuggestionTap(place),
        splashColor: accent.withValues(alpha: 0.15),
        highlightColor: accent.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.place_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      place.displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatLatLng(place.latitude, place.longitude),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLatLng(double lat, double lng) {
    final latStr = '${lat.abs().toStringAsFixed(2)}°${lat >= 0 ? 'N' : 'S'}';
    final lngStr = '${lng.abs().toStringAsFixed(2)}°${lng >= 0 ? 'E' : 'W'}';
    return '$latStr, $lngStr';
  }
}
