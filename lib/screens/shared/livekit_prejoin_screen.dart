/// 🛋️ LIVEKIT PRE-JOIN LOBBY (Bundle 5)
///
/// Wird ANSTELLE des direkten LiveKitGroupCallScreens geöffnet wenn
/// der User auf den Voice-Button tippt. Gibt ihm:
///   - Avatar + Name-Preview
///   - Mikrofon-Test (Permission-Status sichtbar + Audio-Level-Animation)
///   - Audio-Only-Switch (default an = spart Akku/Bandbreite)
///   - "Beitreten" + "Abbrechen"
///
/// Nach "Beitreten": pushReplacement → LiveKitGroupCallScreen mit
/// den gewählten Settings.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../config/wb_design.dart';
import 'livekit_group_call_screen.dart';

class LiveKitPreJoinScreen extends StatefulWidget {
  final String roomName;
  final String world;
  final String displayName;
  final String? avatarUrl;

  const LiveKitPreJoinScreen({
    super.key,
    required this.roomName,
    required this.world,
    required this.displayName,
    this.avatarUrl,
  });

  @override
  State<LiveKitPreJoinScreen> createState() => _LiveKitPreJoinScreenState();
}

class _LiveKitPreJoinScreenState extends State<LiveKitPreJoinScreen>
    with SingleTickerProviderStateMixin {
  bool _audioOnly = true; // default = sparsam
  bool _micEnabled = true; // default = Mikrofon an (User kann als Zuhörer deaktivieren)
  bool _micGranted = false;
  bool _camGranted = false;
  bool _checkingPerms = true;
  late final AnimationController _avatarPulse;

  @override
  void initState() {
    super.initState();
    _avatarPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _checkPermissions();
  }

  @override
  void dispose() {
    _avatarPulse.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final mic = await Permission.microphone.status;
    final cam = await Permission.camera.status;
    if (!mounted) return;
    setState(() {
      _micGranted = mic.isGranted;
      _camGranted = cam.isGranted;
      _checkingPerms = false;
    });
  }

  Future<void> _requestMic() async {
    final res = await Permission.microphone.request();
    if (!mounted) return;
    setState(() => _micGranted = res.isGranted);
  }

  String _roomDisplayName(String r) {
    final parts = r.split('-');
    if (parts.length >= 3) {
      final last = parts.skip(2).join(' ');
      return last.isNotEmpty
          ? '${last[0].toUpperCase()}${last.substring(1)}'
          : r;
    }
    return r;
  }

  void _join() {
    if (!_micGranted) {
      _requestMic();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => LiveKitGroupCallScreen(
          roomName: widget.roomName,
          world: widget.world,
          displayName: widget.displayName,
          avatarUrl: widget.avatarUrl,
          audioOnly: _audioOnly,
          initialMicEnabled: _micEnabled,
        ),
      ),
    );
  }

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final accent = WbDesign.accent(widget.world);
    final bg = WbDesign.background(widget.world);
    final isMaterie = widget.world == 'materie';

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // TopBar mit Schließen
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sprach-Anruf vorbereiten',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            )),
                        const SizedBox(height: 2),
                        Text(
                          'Raum: ${_roomDisplayName(widget.roomName)}',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.85),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _cancel,
                    icon: Icon(Icons.close_rounded,
                        color: WbDesign.textTertiary, size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Avatar-Preview mit Pulse
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _avatarPulse,
                  builder: (_, __) {
                    final t = _avatarPulse.value;
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withValues(alpha: 0.25 + t * 0.20),
                            blurRadius: 30 + t * 20,
                            spreadRadius: 4 + t * 4,
                          ),
                        ],
                      ),
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: WbDesign.hero(widget.world),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.6),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: (widget.avatarUrl != null &&
                                  widget.avatarUrl!.isNotEmpty)
                              ? Image.network(
                                  widget.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _initialsFallback(),
                                )
                              : _initialsFallback(),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Name + Welt
            Text(
              widget.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isMaterie ? 'Weltenbibliothek · Materie' : 'Weltenbibliothek · Energie',
              style: TextStyle(
                color: accent.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 26),

            // Permission + Modus-Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _checkingPerms
                  ? const SizedBox(
                      height: 70,
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Column(
                      children: [
                        _PermissionCard(
                          icon: _micGranted
                              ? Icons.mic_rounded
                              : Icons.mic_off_rounded,
                          label: 'Mikrofon',
                          status: _micGranted ? 'Bereit' : 'Tippen zum Erlauben',
                          ok: _micGranted,
                          accent: accent,
                          onTap: _micGranted ? null : _requestMic,
                        ),
                        if (_micGranted) ...[
                          const SizedBox(height: 10),
                          _MicToggleCard(
                            value: _micEnabled,
                            onChanged: (v) => setState(() => _micEnabled = v),
                            accent: accent,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _AudioOnlyToggleCard(
                          value: _audioOnly,
                          onChanged: (v) => setState(() => _audioOnly = v),
                          accent: accent,
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 24),

            // Beitreten-Button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _checkingPerms ? null : _join,
                  icon: Icon(
                    _micGranted && _micEnabled
                        ? Icons.mic_rounded
                        : Icons.mic_off_rounded,
                    size: 22,
                  ),
                  label: Text(
                    !_micGranted
                        ? 'Mikrofon-Berechtigung erlauben'
                        : (_micEnabled
                            ? 'Mit Mikrofon beitreten'
                            : 'Als Zuhörer beitreten'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: accent.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(WbDesign.radiusLarge),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initialsFallback() {
    final parts = widget.displayName.trim().split(RegExp(r'\s+'));
    String initials = '?';
    if (parts.isNotEmpty && parts.first.isNotEmpty) {
      initials = parts.length == 1
          ? parts.first[0].toUpperCase()
          : '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return Container(
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 50,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String status;
  final bool ok;
  final Color accent;
  final VoidCallback? onTap;

  const _PermissionCard({
    required this.icon,
    required this.label,
    required this.status,
    required this.ok,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WbDesign.radiusLarge),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(WbDesign.radiusLarge),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: WbDesign.surface('').withValues(alpha: 0.6),
                border: Border.all(
                  color: ok
                      ? accent.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: ok
                          ? accent.withValues(alpha: 0.18)
                          : Colors.white.withValues(alpha: 0.06),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon,
                        size: 20,
                        color: ok ? accent : WbDesign.textTertiary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            )),
                        Text(status,
                            style: TextStyle(
                              color: ok
                                  ? accent.withValues(alpha: 0.85)
                                  : WbDesign.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            )),
                      ],
                    ),
                  ),
                  Icon(
                    ok ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                    color:
                        ok ? const Color(0xFF4CAF50) : WbDesign.textTertiary,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MicToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accent;

  const _MicToggleCard({
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WbDesign.radiusLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: WbDesign.surface('').withValues(alpha: 0.6),
            border: Border.all(
              color: value
                  ? accent.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: value
                      ? accent.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value ? Icons.mic_rounded : Icons.mic_off_rounded,
                  size: 20,
                  color: value ? accent : WbDesign.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mikrofon beim Beitreten',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(
                      value
                          ? 'Mikrofon ist an — andere hören dich'
                          : 'Stummgeschaltet — du hörst nur zu',
                      style: TextStyle(
                        color: value
                            ? accent.withValues(alpha: 0.85)
                            : WbDesign.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AudioOnlyToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color accent;

  const _AudioOnlyToggleCard({
    required this.value,
    required this.onChanged,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(WbDesign.radiusLarge),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: WbDesign.surface('').withValues(alpha: 0.6),
            border: Border.all(
              color: value
                  ? accent.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: value
                      ? accent.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value ? Icons.headset_rounded : Icons.videocam_rounded,
                  size: 20,
                  color: value ? accent : WbDesign.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Audio-Only-Modus',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        )),
                    Text(
                      value
                          ? 'Spart ~80% Akku & Daten'
                          : 'Video möglich (mehr Akku/Daten)',
                      style: TextStyle(
                        color: value
                            ? accent.withValues(alpha: 0.85)
                            : WbDesign.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeThumbColor: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
