// GENERATED SPLIT (TEIL 1B): part of world_admin_dashboard library.
// No logic changes -- structural extraction only.
part of '../world_admin_dashboard.dart';

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color accent;
  const _SectionLabel(this.text, this.icon, this.accent);

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, color: accent, size: 14),
        ),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                color: accent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 0.3)),
      ]);
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(children: [
            Icon(Icons.inbox_rounded, color: Colors.white24, size: 48),
            const SizedBox(height: 12),
            Text(text,
                style: const TextStyle(
                    color: Colors.white38, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ── Kompakter Toggle-Chip fuer Source-Filter / Sub-Filter ────────────────
class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final Color accentBright;
  final VoidCallback onTap;
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.accentBright,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? accent : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accentBright : Colors.white54,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── Wiederverwendbare Mini-Pille fuer Welt/Quelle/Status-Badges ──────────
class _MiniPill extends StatelessWidget {
  final String label;
  final Color color;
  final String? tooltip;
  const _MiniPill({required this.label, required this.color, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip!, child: pill);
    return pill;
  }
}

// ── Fehler-Banner mit Retry-Button (User-Tab + Audit-Tab) ────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.35)),
        ),
        child: Row(children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, height: 1.4),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Erneut'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      );
}

// ── Klickbare Statistik-Karte ─────────────────────────────────────────────
class _ClickableStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final VoidCallback onTap;
  const _ClickableStatCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              Icon(Icons.open_in_new_rounded,
                  color: color.withValues(alpha: 0.4), size: 12),
            ]),
            const SizedBox(height: 10),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
        ),
      );
}

// ── Quick Action Button ────────────────────────────────────────────────────
class _QuickActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
            Icon(Icons.arrow_forward_ios_rounded,
                color: color.withValues(alpha: 0.5), size: 12),
          ]),
        ),
      );
}

// ── Aktivitäts-Eintrag ────────────────────────────────────────────────────
class _ActivityTile extends StatelessWidget {
  final AuditLogEntry entry;
  const _ActivityTile({required this.entry});

  // dart2js stolpert über const Map<String, Record> → final Map mit
  // expliziten Tupel-Klassen umgangen.
  static final Map<String, (IconData, Color)> _icons = {
    'edit_message': (Icons.edit_rounded, const Color(0xFF1E88E5)),
    'delete_message': (Icons.delete_rounded, const Color(0xFFE53935)),
    'promote': (Icons.arrow_upward_rounded, const Color(0xFF43A047)),
    'demote': (Icons.arrow_downward_rounded, const Color(0xFFFB8C00)),
    'ban': (Icons.block_rounded, const Color(0xFFE53935)),
    'unban': (Icons.check_circle_rounded, const Color(0xFF00ACC1)),
  };

  static const _labels = {
    'edit_message': 'Nachricht bearbeitet',
    'delete_message': 'Nachricht gelöscht',
    'promote': 'Zum Admin befördert',
    'demote': 'Degradiert',
    'ban': 'Nutzer gesperrt',
    'unban': 'Sperre aufgehoben',
  };

  @override
  Widget build(BuildContext context) {
    final key = entry.action.toLowerCase();
    final iconData = _icons[key]?.$1 ?? Icons.info_outline_rounded;
    final color = _icons[key]?.$2 ?? Colors.grey;
    final label = _labels[key] ?? entry.action;
    final ts = _fmt(entry.timestamp);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(iconData, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            Text('${entry.adminUsername} → ${entry.targetUsername}',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ]),
        ),
        Text(ts, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ]),
    );
  }

  String _fmt(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }
}

// ── Nutzer-Kachel ─────────────────────────────────────────────────────────
class _UserTile extends StatelessWidget {
  final WorldUser user;
  final bool isRootAdmin;
  // v100: Rolle des aktuell eingeloggten Admins. Bestimmt welche Aktionen
  // angezeigt werden (canBan, canDeleteMessages, canPromoteDemote ...).
  final String? actorRole;
  final Color accent, accentBright;
  final VoidCallback onBan, onUnban, onPromote, onDemote;
  final VoidCallback? onGrantXp;
  // v98: Hard-Delete -- nur Root-Admin sieht den Button.
  final VoidCallback? onDelete;
  // v115 Feature B/C: Verwarnen + interne Notizen.
  final VoidCallback? onWarn;
  final VoidCallback? onNotes;
  // v116: Modul-Freischaltung / -Sperre.
  final VoidCallback? onModuleAccess;
  // Additiv (v5.44.3+): feinere Rollen-Auswahl via PopupMenuButton.
  // Bleibt optional, damit andere Caller nicht brechen.
  final void Function(String newRole)? onChangeRole;
  final VoidCallback? onViewDetail;
  // v117: Granulare Bereichs-Sperren.
  final VoidCallback? onRestrict;
  // v123: Shadow-ban (root_admin only) + Temp-Mute (admin+).
  final VoidCallback? onShadowBan;
  final VoidCallback? onTempMute;
  const _UserTile({
    required this.user,
    required this.isRootAdmin,
    this.actorRole,
    required this.accent,
    required this.accentBright,
    required this.onBan,
    required this.onUnban,
    required this.onPromote,
    required this.onDemote,
    this.onGrantXp,
    this.onDelete,
    this.onWarn,
    this.onNotes,
    this.onModuleAccess,
    this.onChangeRole,
    this.onViewDetail,
    this.onRestrict,
    this.onShadowBan,
    this.onTempMute,
  });

  Color get _roleColor => switch (user.role) {
        'root_admin' => Colors.amber,
        'admin' => Colors.blue,
        'content_editor' => Colors.purpleAccent,
        'moderator' => Colors.tealAccent,
        _ => Colors.white38,
      };

  String get _roleLabel => switch (user.role) {
        'root_admin' => '👑 ROOT',
        'admin' => '🛡️ Admin',
        'content_editor' => '✍️ Editor',
        'moderator' => '🧹 Mod',
        _ => '👤 User',
      };

  // Erlaubte Rollen-Ziele abhaengig von Berechtigung. Root-Admin darf zu
  // 'admin' und 'root_admin' setzen; Standard-Admin nur user/moderator/
  // content_editor.
  List<String> get _availableRoles {
    final base = ['user', 'moderator', 'content_editor'];
    if (isRootAdmin) {
      base.addAll(['admin', 'root_admin']);
    }
    return base;
  }

  static String _roleMenuLabel(String r) => switch (r) {
        'root_admin' => '👑 Root-Admin',
        'admin' => '🛡️ Admin',
        'content_editor' => '✍️ Content-Editor',
        'moderator' => '🧹 Moderator',
        'user' => '👤 User',
        _ => r,
      };

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _roleColor.withValues(alpha: 0.15),
                child: Text(
                  user.avatarEmoji?.isNotEmpty == true
                      ? user.avatarEmoji!
                      : (user.username.isEmpty
                          ? '?'
                          : user.username[0].toUpperCase()),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              // 🟢 Online-Status-Dot rechts unten am Avatar
              Positioned(
                right: -2,
                bottom: -2,
                child: _OnlineDot(lastSeenAtIso: user.lastSeenAt),
              ),
            ],
          ),
          title: Text(user.displayName ?? user.username,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          subtitle: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('@${user.username}',
                  style: TextStyle(
                      color: accent.withValues(alpha: 0.7), fontSize: 11)),
              if (user.world != null)
                _MiniPill(
                  // AUDIT-FIX C7: Symbol + Buchstabe statt nur color/letter
                  // damit Farbenblinde die Welt erkennen.
                  label: user.world == 'materie' ? '🌍 M' : '✨ E',
                  color: user.world == 'materie' ? Colors.orange : Colors.teal,
                  tooltip:
                      user.world == 'materie' ? 'Materie-Welt' : 'Energie-Welt',
                ),
              // 🔑 Herkunfts-Badge: Web (Supabase-Auth) vs. App (InvisibleAuth)
              if (user.isWebOnly)
                const _MiniPill(
                  label: '🌐 Web-Antrag',
                  color: Color(0xFFC9A84C),
                  tooltip: 'Web-Zugang genehmigt, noch kein vollstaendiges '
                      'Profil. User-Aktionen greifen hier nicht.',
                )
              else if (user.source == 'web')
                const _MiniPill(
                  label: '🌐 Web',
                  color: Color(0xFF4FC3F7),
                  tooltip: 'Profil ueber Web-Anmeldung erstellt',
                )
              else if (user.source == 'app')
                const _MiniPill(
                  label: '📱 App',
                  color: Color(0xFF81C784),
                  tooltip: 'Profil ueber die Flutter-App erstellt',
                ),
              // v115: Gesperrt-Badge
              if (user.isSuspended)
                const _MiniPill(
                  label: '🚫 Gesperrt',
                  color: Colors.redAccent,
                  tooltip: 'Dieser Nutzer ist aktuell gesperrt',
                ),
              // v123: Shadow-ban Badge
              if (user.isShadowBanned)
                const _MiniPill(
                  label: '👻 Shadow',
                  color: Color(0xFF9C27B0),
                  tooltip: 'Shadow-gesperrt: Nutzer sieht eigene Posts, andere nicht',
                ),
              // v123: Mute Badge
              if (user.isMuted)
                _MiniPill(
                  label: '🔇 Stumm',
                  color: Colors.blueGrey,
                  tooltip: 'Stumm bis ${user.mutedUntil?.toLocal().toString().substring(0, 16) ?? '?'}',
                ),
              // v123: Bot-Verdacht Badge
              if (user.isBotSuspect)
                const _MiniPill(
                  label: '🤖 Bot?',
                  color: Color(0xFFFF6F00),
                  tooltip: 'Konto < 24h alt mit hoher Post-Frequenz',
                ),
              // v115 (Feature B): Verwarnungs-Badge mit Count
              if (user.warningCount > 0)
                _MiniPill(
                  label: '⚠️ ${user.warningCount}/3',
                  color:
                      user.warningCount >= 3 ? Colors.red : Colors.orangeAccent,
                  tooltip: '${user.warningCount} Verwarnung(en)',
                ),
            ],
          ),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (onChangeRole != null && !user.isWebOnly)
              PopupMenuButton<String>(
                tooltip: 'Rolle aendern',
                color: const Color(0xFF12121E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: accent.withValues(alpha: 0.25)),
                ),
                position: PopupMenuPosition.under,
                onSelected: (r) => onChangeRole!(r),
                itemBuilder: (ctx) => _availableRoles.map((r) {
                  final isCurrent = r == user.role;
                  return PopupMenuItem<String>(
                    value: r,
                    enabled: !isCurrent,
                    child: Row(children: [
                      Text(_roleMenuLabel(r),
                          style: TextStyle(
                              color: isCurrent ? Colors.white38 : Colors.white,
                              fontWeight:
                                  isCurrent ? FontWeight.w400 : FontWeight.w600,
                              fontSize: 13)),
                      if (isCurrent) ...[
                        const Spacer(),
                        const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white38),
                      ],
                    ]),
                  );
                }).toList(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: _roleColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(_roleLabel,
                        style: TextStyle(
                            color: _roleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 3),
                    Icon(Icons.arrow_drop_down_rounded,
                        size: 14, color: _roleColor),
                  ]),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _roleColor.withValues(alpha: 0.3)),
                ),
                child: Text(_roleLabel,
                    style: TextStyle(
                        color: _roleColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more_rounded,
                color: Colors.white38, size: 18),
          ]),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(children: [
                const Divider(color: Colors.white10, height: 16),
                _InfoRow(Icons.access_time_rounded,
                    'Erstellt: ${_fmtDate(user.createdAt)}'),
                const SizedBox(height: 4),
                _InfoRow(Icons.fingerprint_rounded,
                    'ID: ${user.userId.isEmpty ? "Unbekannt" : user.userId}'),
                const SizedBox(height: 12),
                if (user.isWebOnly)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Web-Zugangs-Antrag -- noch kein vollstaendiges Profil erstellt.\nAktionen sind nicht verfuegbar.',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    // v100: Promote/Demote nur fuer Admin+ (canPromoteDemote).
                    if (AppRoles.canPromoteDemote(actorRole) && !user.isAdmin)
                      _ActionBtn(Icons.arrow_upward_rounded, 'Befoerdern',
                          Colors.green, onPromote),
                    if (AppRoles.canPromoteDemote(actorRole) &&
                        user.isAdmin &&
                        !user.isRootAdmin)
                      _ActionBtn(Icons.arrow_downward_rounded, 'Degradieren',
                          Colors.orange, onDemote),
                    // Ban/Unban fuer Moderator+.
                    if (AppRoles.canBanUsers(actorRole))
                      _ActionBtn(
                          Icons.block_rounded, 'Sperren', Colors.red, onBan),
                    if (AppRoles.canBanUsers(actorRole))
                      _ActionBtn(Icons.check_circle_outline_rounded,
                          'Entsperren', Colors.teal, onUnban),
                    // v117: Granulare Bereichs-Sperren (Chat/Live/XP ...).
                    if (onRestrict != null && AppRoles.canBanUsers(actorRole))
                      _ActionBtn(Icons.tune_rounded, 'Bereiche',
                          const Color(0xFFEF6C9A), onRestrict!),
                    // v115 (Feature B): Verwarnen -- Moderator+.
                    if (onWarn != null && AppRoles.canBanUsers(actorRole))
                      _ActionBtn(Icons.warning_amber_rounded, 'Verwarnen',
                          Colors.orangeAccent, onWarn!),
                    // v115 (Feature C): Interne Notizen -- Moderator+.
                    if (onNotes != null && AppRoles.canViewUserList(actorRole))
                      _ActionBtn(Icons.sticky_note_2_rounded, 'Notizen',
                          const Color(0xFF9575CD), onNotes!),
                    if (onModuleAccess != null &&
                        AppRoles.canBanUsers(actorRole))
                      _ActionBtn(Icons.school_rounded, 'Module',
                          const Color(0xFF26C6DA), onModuleAccess!),
                    if (onGrantXp != null)
                      _ActionBtn(Icons.auto_awesome_rounded, 'XP vergeben',
                          const Color(0xFFFFC107), onGrantXp!),
                    if (onViewDetail != null)
                      _ActionBtn(Icons.person_search_rounded, 'Detail',
                          const Color(0xFF42A5F5), onViewDetail!),
                    // v123: Shadow-ban (root_admin only)
                    if (onShadowBan != null)
                      _ActionBtn(
                        Icons.visibility_off_rounded,
                        user.isShadowBanned ? 'Shadow auf' : 'Shadow-Ban',
                        const Color(0xFF9C27B0),
                        onShadowBan!,
                      ),
                    // v123: Temp-Mute (admin+)
                    if (onTempMute != null)
                      _ActionBtn(
                        Icons.volume_off_rounded,
                        user.isMuted ? 'Entmuten' : 'Stumm',
                        Colors.blueGrey,
                        onTempMute!,
                      ),
                    if (onDelete != null)
                      _ActionBtn(Icons.delete_forever_rounded, 'Loeschen',
                          Colors.redAccent, onDelete!),
                  ]),
              ]),
            ),
          ],
        ),
      );

  String _fmtDate(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return '–';
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 12, color: Colors.white38),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white38, fontSize: 11),
                overflow: TextOverflow.ellipsis)),
      ]);
}

class _InfoRow2 extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow2(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, size: 14, color: Colors.white54),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ]);
}

// ── Aktions-Button ────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(this.icon, this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}

// ── Bulk-Action-Bar (schwebt am unteren Rand, wenn Nutzer angehakt sind) ──
class _BulkActionBar extends StatelessWidget {
  final int count;
  final Color accent;
  final Color accentBright;
  final VoidCallback onPromote;
  final VoidCallback onDemote;
  final VoidCallback onBan;
  final VoidCallback onUnban;
  final VoidCallback onClear;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDelete;
  final VoidCallback? onWarn;
  final VoidCallback? onRoleChange;
  const _BulkActionBar({
    required this.count,
    required this.accent,
    required this.accentBright,
    required this.onPromote,
    required this.onDemote,
    required this.onBan,
    required this.onUnban,
    required this.onClear,
    this.onSelectAll,
    this.onDelete,
    this.onWarn,
    this.onRoleChange,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0817).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: accentBright.withValues(alpha: 0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.35),
              blurRadius: 22,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentBright.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count ausgewählt',
                  style: TextStyle(
                      color: accentBright,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 8),
            if (onSelectAll != null) ...[
              TextButton.icon(
                onPressed: onSelectAll,
                icon: const Icon(Icons.select_all_rounded,
                    size: 16, color: Colors.white70),
                label: const Text('Alle waehlen',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(0, 28),
                ),
              ),
              const SizedBox(width: 4),
            ],
            _ActionBtn(
                Icons.arrow_upward, 'Befördern', Colors.green, onPromote),
            const SizedBox(width: 6),
            _ActionBtn(
                Icons.arrow_downward, 'Degradieren', Colors.orange, onDemote),
            const SizedBox(width: 6),
            _ActionBtn(Icons.block, 'Bannen', Colors.red, onBan),
            const SizedBox(width: 6),
            _ActionBtn(Icons.lock_open, 'Entbannen', Colors.teal, onUnban),
            if (onWarn != null) ...[
              const SizedBox(width: 6),
              _ActionBtn(Icons.warning_amber_rounded, 'Verwarnen',
                  Colors.orangeAccent, onWarn!),
            ],
            if (onRoleChange != null) ...[
              const SizedBox(width: 6),
              _ActionBtn(Icons.manage_accounts_rounded, 'Rolle aendern',
                  Colors.blueAccent, onRoleChange!),
            ],
            if (onDelete != null) ...[
              const SizedBox(width: 6),
              _ActionBtn(
                  Icons.delete_forever, 'Löschen', Colors.redAccent, onDelete!),
            ],
            const SizedBox(width: 10),
            IconButton(
              tooltip: 'Auswahl aufheben',
              icon: const Icon(Icons.close, color: Colors.white60, size: 18),
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Chat-Nachrichten-Kachel ───────────────────────────────────────────────
class _ChatMsgTile extends StatelessWidget {
  final Map<String, dynamic> msg;
  final Color accent, accentBright;
  final VoidCallback onDelete, onBan;
  const _ChatMsgTile(
      {required this.msg,
      required this.accent,
      required this.accentBright,
      required this.onDelete,
      required this.onBan});

  @override
  Widget build(BuildContext context) {
    final username = (msg['username'] ?? 'Anonym').toString();
    final content = (msg['content'] ?? msg['message'] ?? '').toString();
    final ts = _fmt(msg['created_at'] ?? msg['timestamp'] ?? '');
    final emoji =
        (msg['avatarEmoji'] ?? msg['avatar_emoji'] ?? '👤').toString();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              // FIX (#9): langer Username darf den Timestamp nicht
              // rausdruecken / Overflow verursachen -> Expanded + ellipsis.
              Expanded(
                child: Text(username,
                    style: TextStyle(
                        color: accentBright,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text(ts,
                  style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
            const SizedBox(height: 4),
            Text(content,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.4),
                maxLines: 5,
                overflow: TextOverflow.ellipsis),
          ]),
        ),
        const SizedBox(width: 6),
        Column(children: [
          IconButton(
            icon: const Icon(Icons.delete_rounded,
                color: Colors.redAccent, size: 20),
            tooltip: 'Nachricht löschen',
            onPressed: onDelete,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(height: 4),
          IconButton(
            icon:
                const Icon(Icons.block_rounded, color: Colors.orange, size: 20),
            tooltip: 'Sender sperren',
            onPressed: onBan,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
          ),
        ]),
      ]),
    );
  }

  String _fmt(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

// ── Klickbare Service-Zeile ───────────────────────────────────────────────
class _ClickableServiceRow extends StatelessWidget {
  final String name;
  final ServiceHealth health;
  final Color statusColor;
  final VoidCallback onTap;
  const _ClickableServiceRow(
      {required this.name,
      required this.health,
      required this.statusColor,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF12121E),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Row(children: [
            Container(
              width: 10,
              height: 10,
              decoration:
                  BoxDecoration(color: statusColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(name,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${health.latencyMs} ms',
                  style: TextStyle(
                      color: statusColor.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text(health.statusText,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: Colors.white24, size: 16),
          ]),
        ),
      );
}

// ── Klickbare Metrik-Karte ────────────────────────────────────────────────
class _ClickableMetricCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ClickableMetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Column(children: [
            Icon(icon, color: color.withValues(alpha: 0.8), size: 18),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ── Online-Status-Dot am Avatar ────────────────────────────────────
class _OnlineDotState {
  final Color color;
  final String tooltip;
  const _OnlineDotState(this.color, this.tooltip);
}

class _OnlineDot extends StatelessWidget {
  final String? lastSeenAtIso;
  const _OnlineDot({required this.lastSeenAtIso});

  _OnlineDotState _state() {
    if (lastSeenAtIso == null) {
      return _OnlineDotState(Colors.grey.shade700, 'Nie online');
    }
    final t = DateTime.tryParse(lastSeenAtIso!);
    if (t == null) {
      return _OnlineDotState(Colors.grey.shade700, 'Offline');
    }
    final delta = DateTime.now().toUtc().difference(t.toUtc());
    if (delta.inMinutes < 2) {
      return const _OnlineDotState(Color(0xFF4CAF50), 'Online');
    }
    if (delta.inMinutes < 15) {
      return _OnlineDotState(
          const Color(0xFFFFC107), 'Vor ${delta.inMinutes} Min');
    }
    final h = delta.inHours;
    if (h < 24) {
      return _OnlineDotState(Colors.grey.shade500, 'Vor ${h}h');
    }
    return _OnlineDotState(Colors.grey.shade700, 'Vor ${delta.inDays} Tagen');
  }

  @override
  Widget build(BuildContext context) {
    final s = _state();
    return Tooltip(
      message: s.tooltip,
      child: Container(
        width: 13,
        height: 13,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: s.color,
          border: Border.all(color: const Color(0xFF12121E), width: 2),
          boxShadow: s.color == const Color(0xFF4CAF50)
              ? [
                  BoxShadow(
                    color: s.color.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// ── 🟢 Live-Online-Roster: zeigt User aktiv in den letzten 5/15 min
class _OnlineNowBlock extends StatefulWidget {
  final Color accent;
  final Color accentBright;
  const _OnlineNowBlock({required this.accent, required this.accentBright});

  @override
  State<_OnlineNowBlock> createState() => _OnlineNowBlockState();
}

class _OnlineNowBlockState extends State<_OnlineNowBlock> {
  List<WorldUser> _all = const [];
  bool _loading = true;
  Timer? _t;
  // Cutoff in Minuten — "Online jetzt"
  static const _onlineCutoffMin = 5;
  static const _recentCutoffMin = 15;

  @override
  void initState() {
    super.initState();
    _load();
    _t = Timer.periodic(const Duration(seconds: 45), (_) => _load());
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    try {
      final users = await WorldAdminService.getAllUsers();
      if (mounted) {
        setState(() {
          _all = users;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Liefert Delta in Minuten (oder null bei kein lastSeen).
  int? _ageMin(WorldUser u) {
    if (u.lastSeenAt == null) return null;
    final t = DateTime.tryParse(u.lastSeenAt!);
    if (t == null) return null;
    return DateTime.now().toUtc().difference(t.toUtc()).inMinutes;
  }

  void _showFullList() {
    final online = _all.where((u) {
      final a = _ageMin(u);
      return a != null && a < _onlineCutoffMin;
    }).toList()
      ..sort((a, b) => (_ageMin(a) ?? 99999).compareTo(_ageMin(b) ?? 99999));
    final recent = _all.where((u) {
      final a = _ageMin(u);
      return a != null && a >= _onlineCutoffMin && a < _recentCutoffMin;
    }).toList()
      ..sort((a, b) => (_ageMin(a) ?? 99999).compareTo(_ageMin(b) ?? 99999));

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0A0A18),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Icon(Icons.bolt_rounded, color: widget.accent, size: 20),
              const SizedBox(width: 8),
              Text('Live-Roster',
                  style: TextStyle(
                      color: widget.accentBright,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const Spacer(),
              Text('< $_onlineCutoffMin min: ${online.length}',
                  style:
                      const TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
            ]),
            const SizedBox(height: 14),
            if (online.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Niemand aktuell online.',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              )
            else
              ...online.map((u) => _rosterTile(u, isOnline: true)),
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                  'Vor $_onlineCutoffMin–$_recentCutoffMin min · ${recent.length}',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 6),
              ...recent.map((u) => _rosterTile(u, isOnline: false)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _rosterTile(WorldUser u, {required bool isOnline}) {
    final age = _ageMin(u);
    final String worldLabel;
    final Color worldColor;
    if (u.world == 'materie') {
      worldLabel = 'M';
      worldColor = Colors.orange;
    } else if (u.world == 'energie') {
      worldLabel = 'E';
      worldColor = Colors.teal;
    } else {
      worldLabel = '?';
      worldColor = Colors.white24;
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOnline
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : Colors.white12,
        ),
      ),
      child: Row(children: [
        Stack(clipBehavior: Clip.none, children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: widget.accent.withValues(alpha: 0.18),
            child: Text(
              u.avatarEmoji?.isNotEmpty == true
                  ? u.avatarEmoji!
                  : (u.username.isEmpty ? '?' : u.username[0].toUpperCase()),
              style: const TextStyle(fontSize: 14, color: Colors.white),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: _OnlineDot(lastSeenAtIso: u.lastSeenAt),
          ),
        ]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u.displayName ?? u.username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
              Text('@${u.username}',
                  style: TextStyle(
                      color: widget.accent.withValues(alpha: 0.7),
                      fontSize: 10),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: worldColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: worldColor.withValues(alpha: 0.4)),
          ),
          child: Text(worldLabel,
              style: TextStyle(
                  color: worldColor, fontSize: 9, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        if (age != null)
          Text(age < 1 ? 'jetzt' : '${age}m',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 92,
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Center(
            child: CircularProgressIndicator(
                color: widget.accent, strokeWidth: 2)),
      );
    }

    final onlineNow = _all.where((u) {
      final a = _ageMin(u);
      return a != null && a < _onlineCutoffMin;
    }).toList()
      ..sort((a, b) => (_ageMin(a) ?? 99999).compareTo(_ageMin(b) ?? 99999));

    final byWorld = <String, int>{'energie': 0, 'materie': 0, 'andere': 0};
    for (final u in onlineNow) {
      final w = u.world;
      if (w == 'energie') {
        byWorld['energie'] = byWorld['energie']! + 1;
      } else if (w == 'materie') {
        byWorld['materie'] = byWorld['materie']! + 1;
      } else {
        byWorld['andere'] = byWorld['andere']! + 1;
      }
    }

    final preview = onlineNow.take(6).toList();

    return GestureDetector(
      onTap: _showFullList,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4CAF50).withValues(alpha: 0.10),
              widget.accent.withValues(alpha: 0.04),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4CAF50),
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x884CAF50),
                        blurRadius: 6,
                        spreadRadius: 1),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text('${onlineNow.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              const Text('online',
                  style: TextStyle(color: Colors.white60, fontSize: 13)),
              const Spacer(),
              Text('E ${byWorld['energie']}  ·  M ${byWorld['materie']}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38, size: 18),
            ]),
            const SizedBox(height: 10),
            if (preview.isEmpty)
              const Text('Niemand aktiv in den letzten 5 Minuten.',
                  style: TextStyle(color: Colors.white54, fontSize: 12))
            else
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: preview.map((u) {
                  final ageMin = _ageMin(u);
                  final initial =
                      u.username.isEmpty ? '?' : u.username[0].toUpperCase();
                  return Tooltip(
                    message:
                        '@${u.username} · ${ageMin == null ? "?" : ageMin < 1 ? "jetzt" : "${ageMin}m"}',
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        CircleAvatar(
                          radius: 9,
                          backgroundColor: widget.accent.withValues(alpha: 0.2),
                          child: Text(
                            u.avatarEmoji?.isNotEmpty == true
                                ? u.avatarEmoji!
                                : initial,
                            style: const TextStyle(
                                fontSize: 9, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(u.username,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            if (onlineNow.length > preview.length) ...[
              const SizedBox(height: 6),
              Text(
                  '+${onlineNow.length - preview.length} weitere · Tippen für Liste',
                  style: TextStyle(color: widget.accent, fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}

// ── M2: Live-Aktivitäts-Heatmap (Welt × Stunde) ────────────────────
class _ActivityHeatmapBlock extends StatefulWidget {
  final Color accent;
  const _ActivityHeatmapBlock({required this.accent});

  @override
  State<_ActivityHeatmapBlock> createState() => _ActivityHeatmapBlockState();
}

class _ActivityHeatmapBlockState extends State<_ActivityHeatmapBlock> {
  ActivityHeatmap? _data;
  bool _loading = true;

  static const _worldColors = {
    'materie': Color(0xFF3B82F6),
    'energie': Color(0xFFA855F7),
    'vorhang': Color(0xFFC9A84C),
    'ursprung': Color(0xFF00D4AA),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final d = await ActivityHeatmapService.instance.compute(days: 7);
    if (mounted) {
      setState(() {
        _data = d;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF12121E),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child:
              CircularProgressIndicator(color: widget.accent, strokeWidth: 2),
        ),
      );
    }
    final data = _data!;
    final maxVal = data.data.values
        .expand((row) => row)
        .fold<int>(0, (m, v) => v > m ? v : m);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF12121E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accent.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: widget.accent, size: 14),
              const SizedBox(width: 6),
              Text(
                '${data.totalMessages} Nachrichten · ${data.fromTime.day}.${data.fromTime.month}. bis heute',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // X-Achse: Stunden 0-23 (alle 6h beschriftet)
          Padding(
            padding: const EdgeInsets.only(left: 70),
            child: Row(
              children: List.generate(24, (h) {
                return Expanded(
                  child: Text(
                    h % 6 == 0 ? '$h' : '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 4),
          // Heatmap-Zeilen pro Welt
          for (final w in const ['materie', 'energie', 'vorhang', 'ursprung'])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 70,
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _worldColors[w],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          w[0].toUpperCase() + w.substring(1, 3),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: List.generate(24, (h) {
                        final v = data.data[w]?[h] ?? 0;
                        final intensity = maxVal == 0 ? 0.0 : v / maxVal;
                        return Expanded(
                          child: Tooltip(
                            message: '$w · ${h}h: $v Msg',
                            child: Container(
                              height: 22,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 0.5),
                              decoration: BoxDecoration(
                                color: _worldColors[w]!.withValues(
                                    alpha: 0.08 + (intensity * 0.85)),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
