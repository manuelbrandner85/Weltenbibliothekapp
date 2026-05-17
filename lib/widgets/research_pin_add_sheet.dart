// ResearchPinAddSheet — Bottom-Sheet zum Erstellen eines neuen Map-Pins.
//
// Aufruf: ResearchPinAddSheet.show(context, lat, lng, world).
// Speichert via ResearchPinService und zeigt Toast-Feedback.

import 'package:flutter/material.dart';

import '../services/research_pin_service.dart';
import '../services/storage_service.dart';
import '../utils/wb_toast.dart';

class ResearchPinAddSheet {
  static Future<bool> show(
    BuildContext context, {
    required double lat,
    required double lng,
    required String world,
    Color accent = const Color(0xFF2979FF),
  }) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF0D0D1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PinForm(lat: lat, lng: lng, world: world, accent: accent),
    );
    return added ?? false;
  }
}

class _PinForm extends StatefulWidget {
  final double lat, lng;
  final String world;
  final Color accent;

  const _PinForm({
    required this.lat,
    required this.lng,
    required this.world,
    required this.accent,
  });

  @override
  State<_PinForm> createState() => _PinFormState();
}

class _PinFormState extends State<_PinForm> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      WBToast.error(context, 'Titel fehlt');
      return;
    }
    setState(() => _saving = true);
    final storage = StorageService();
    final profile = widget.world == 'materie'
        ? storage.getMaterieProfile()
        : storage.getEnergieProfile();
    final pin = await ResearchPinService.instance.add(
      world: widget.world,
      userId: profile?.userId ?? 'anonymous',
      username: profile?.username,
      lat: widget.lat,
      lng: widget.lng,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (pin != null) {
      WBToast.success(context, '📍 Pin gesetzt');
      Navigator.of(context).pop(true);
    } else {
      WBToast.error(context, 'Speichern fehlgeschlagen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: mq.viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.place_rounded, color: widget.accent),
              const SizedBox(width: 8),
              const Text(
                'Recherche-Pin setzen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.lat.toStringAsFixed(4)}, ${widget.lng.toStringAsFixed(4)}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Titel',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Beschreibung (optional)',
              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.check_rounded),
            label: const Text('Pin speichern'),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
