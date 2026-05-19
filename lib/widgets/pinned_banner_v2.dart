// PinnedBannerV2 — sticky Banner oben im Chat, basiert auf
// PinnedMessageService (Supabase pinned_messages-Tabelle, v79).
//
// Neuer Name verhindert Kollision mit dem älteren
// PinnedMessageBanner aus pinned_message_banner.dart (Cloudflare-basiert).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/pinned_message_service.dart';

class PinnedBannerV2 extends StatefulWidget {
  final String roomId;
  final Color accent;
  final void Function(PinnedMessage)? onTap;
  const PinnedBannerV2({
    super.key,
    required this.roomId,
    required this.accent,
    this.onTap,
  });

  @override
  State<PinnedBannerV2> createState() => _PinnedBannerV2State();
}

class _PinnedBannerV2State extends State<PinnedBannerV2> {
  List<PinnedMessage> _pins = const [];
  RealtimeChannel? _channel;
  Timer? _refresh;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
    _refresh = Timer.periodic(const Duration(minutes: 2), (_) => _load());
  }

  @override
  void didUpdateWidget(covariant PinnedBannerV2 old) {
    super.didUpdateWidget(old);
    if (old.roomId != widget.roomId) {
      _channel?.unsubscribe();
      _activeIndex = 0;
      _load();
      _subscribe();
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list =
          await PinnedMessageService.instance.listForRoom(widget.roomId);
      if (mounted) {
        setState(() {
          _pins = list;
          if (_activeIndex >= list.length) _activeIndex = 0;
        });
      }
    } catch (_) {}
  }

  void _subscribe() {
    _channel = PinnedMessageService.instance.subscribe(
      widget.roomId,
      onChange: _load,
    );
  }

  void _cyclePin() {
    if (_pins.length < 2) return;
    setState(() {
      _activeIndex = (_activeIndex + 1) % _pins.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_pins.isEmpty) return const SizedBox.shrink();
    final pin = _pins[_activeIndex];
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_pins.length > 1) {
            _cyclePin();
          } else {
            widget.onTap?.call(pin);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.accent.withValues(alpha: 0.08),
            border: Border(
              bottom: BorderSide(
                color: widget.accent.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.accent.withValues(alpha: 0.18),
                ),
                child: Icon(
                  Icons.push_pin_rounded,
                  color: widget.accent,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'ANGEPINNT',
                          style: TextStyle(
                            color: widget.accent,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        if (_pins.length > 1) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${_activeIndex + 1}/${_pins.length}',
                            style: TextStyle(
                              color: widget.accent.withValues(alpha: 0.7),
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pin.preview ?? '(Nachricht)',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pins.length > 1)
                Icon(Icons.chevron_right_rounded,
                    color: widget.accent.withValues(alpha: 0.7), size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
