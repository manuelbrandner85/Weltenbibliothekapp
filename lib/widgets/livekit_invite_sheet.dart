/// 🎙️ LIVEKIT INVITE SHEET
///
/// Modal bottom sheet to invite users into an active LiveKit room:
///   - Share a deep-link invite text via the system share dialog.
///   - Push-invite app users that are online right now (multi-select).
///
/// Dark glassmorphic styling, accent passed in by the caller.
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../services/livestream_invite_service.dart';

/// Shows the invite bottom sheet for [roomName] in [world].
///
/// [fromName] is the inviter's display name, [excludeUserId] is omitted from
/// the online-user list (typically the inviter), [accent] is the world accent.
Future<void> showLivekitInviteSheet(
  BuildContext context, {
  required String roomName,
  required String world,
  required String fromName,
  String? excludeUserId,
  required Color accent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _InviteSheet(
      roomName: roomName,
      world: world,
      fromName: fromName,
      excludeUserId: excludeUserId,
      accent: accent,
    ),
  );
}

class _InviteSheet extends StatefulWidget {
  final String roomName;
  final String world;
  final String fromName;
  final String? excludeUserId;
  final Color accent;

  const _InviteSheet({
    required this.roomName,
    required this.world,
    required this.fromName,
    required this.excludeUserId,
    required this.accent,
  });

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  late Future<List<InviteUser>> _usersFuture;
  final Set<String> _selected = <String>{};
  final TextEditingController _searchCtrl = TextEditingController();
  bool _sending = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _usersFuture = LivestreamInviteService.instance
        .getOnlineUsers(excludeUserId: widget.excludeUserId);
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() {
        _searching = false;
        _usersFuture = LivestreamInviteService.instance
            .getOnlineUsers(excludeUserId: widget.excludeUserId);
      });
    } else {
      setState(() {
        _searching = true;
        _usersFuture = LivestreamInviteService.instance
            .searchUsers(q, excludeUserId: widget.excludeUserId);
      });
    }
  }

  Future<void> _shareLink() async {
    final text = LivestreamInviteService.instance.buildShareText(
      roomName: widget.roomName,
      world: widget.world,
      fromName: widget.fromName,
    );
    await Share.share(text);
  }

  Future<void> _sendInvites() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (_selected.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Niemand ausgewählt')),
      );
      return;
    }
    setState(() => _sending = true);
    final ok = await LivestreamInviteService.instance.invite(
      roomName: widget.roomName,
      world: widget.world,
      fromName: widget.fromName,
      userIds: _selected.toList(),
    );
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? 'Einladung gesendet' : 'Einladung fehlgeschlagen'),
      ),
    );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border(
              top: BorderSide(color: accent.withValues(alpha: 0.25), width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Title ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Icon(Icons.person_add_alt_1_rounded,
                          color: accent, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        'Zum Live-Call einladen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Share-link button ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: _shareLink,
                      icon: const Icon(Icons.ios_share_rounded, size: 18),
                      label: const Text('Per Link teilen'),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent.withValues(alpha: 0.18),
                        foregroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: accent.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // ── Search field ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    cursorColor: accent,
                    decoration: InputDecoration(
                      hintText: 'Mitglied suchen...',
                      hintStyle:
                          const TextStyle(color: Colors.white38, fontSize: 14),
                      prefixIcon:
                          Icon(Icons.search_rounded, color: accent, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded,
                                  color: Colors.white38, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.07),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Section label ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _searching ? 'Suchergebnisse' : 'Online-Mitglieder',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // ── Users list ─────────────────────────────────────────
                Flexible(
                  child: FutureBuilder<List<InviteUser>>(
                    future: _usersFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: CircularProgressIndicator(color: accent),
                          ),
                        );
                      }
                      final users = snapshot.data ?? const <InviteUser>[];
                      if (users.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              _searching
                                  ? 'Kein Ergebnis für "${_searchCtrl.text}"'
                                  : 'Gerade ist niemand online',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: users.length,
                        itemBuilder: (context, i) {
                          final u = users[i];
                          final checked = _selected.contains(u.userId);
                          return CheckboxListTile(
                            value: checked,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selected.add(u.userId);
                                } else {
                                  _selected.remove(u.userId);
                                }
                              });
                            },
                            activeColor: accent,
                            checkColor: Colors.black,
                            controlAffinity:
                                ListTileControlAffinity.trailing,
                            secondary: _Avatar(user: u, accent: accent),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    u.username,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (u.isOnline)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                // ── Invite button ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _sending ? null : _sendInvites,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text('Einladen (${_selected.length})'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Avatar with image fallback to username initials.
class _Avatar extends StatelessWidget {
  final InviteUser user;
  final Color accent;

  const _Avatar({required this.user, required this.accent});

  @override
  Widget build(BuildContext context) {
    final url = user.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 18,
        backgroundColor: accent.withValues(alpha: 0.2),
        backgroundImage: NetworkImage(url),
      );
    }
    final name = user.username;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 18,
      backgroundColor: accent.withValues(alpha: 0.2),
      child: Text(
        initials,
        style: TextStyle(
          color: accent,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}
