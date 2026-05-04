// 🟢 RELEASE UPDATE SCREEN – Fullscreen-Update-Gate
//
// Wird angezeigt wenn eine neue APK-Version verfügbar ist. Sperrt die App
// komplett (PopScope canPop:false bei Force-Update), bis der User die neue
// APK heruntergeladen und installiert hat.
//
// Flow:
//   1. Info-Ansicht: aktuelle vs. neue Version + Changelog + Download-Button
//   2. Download: Progress-Bar (MB / Gesamt / %), cancel möglich
//   3. Fertig: Android PackageInstaller öffnet sich automatisch
//
// Signatur-Mismatch-Schutz (ab v5.36.0):
//   Wenn die Installation wiederholt fehlschlägt (>=2 Versuche), zeigen wir
//   eine klare "Deinstallieren & Neuinstallieren"-Anleitung und aktivieren
//   einen Notausgang ("App trotzdem weiter nutzen"). Sonst säße ein User
//   mit alter Debug-Key-APK in einer Endlosschleife fest.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/apk_download_service.dart';
import '../services/update_service.dart';
import '../utils/changelog_translator.dart';

enum _UpdateStage { idle, downloading, downloaded, installing, error }

class ReleaseUpdateScreen extends StatefulWidget {
  final UpdateCheckResult info;
  const ReleaseUpdateScreen({super.key, required this.info});

  @override
  State<ReleaseUpdateScreen> createState() => _ReleaseUpdateScreenState();
}

class _ReleaseUpdateScreenState extends State<ReleaseUpdateScreen> {
  // Home-Dashboard-Farben
  static const Color _bg = Color(0xFF04080F);
  static const Color _card = Color(0xFF0A1020);
  static const Color _blue = Color(0xFF2979FF);
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _red = Color(0xFFE53935);
  static const Color _green = Color(0xFF2ECC71);

  _UpdateStage _stage = _UpdateStage.idle;
  ApkDownloadProgress? _progress;
  String? _errorMsg;
  File? _apkFile;
  // APK-Größe für den Download-Button (via HEAD-Request beim Screen-Start)
  Future<int?>? _apkSizeFuture;
  // Zähler für fehlgeschlagene Installationsversuche — nach 2 aktivieren wir
  // den Notausgang (Signatur-Mismatch-Schutz).
  int _installAttempts = 0;
  // Auto-Retry bei 404: Countdown-Sekunden bis zum nächsten Versuch.
  int? _retryCountdown;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    final url = widget.info.apkDownloadUrl;
    if (url != null && url.isNotEmpty) {
      _apkSizeFuture = ApkDownloadService.instance.getApkFileSize(url);
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  void _startRetryCountdown() {
    _retryTimer?.cancel();
    setState(() => _retryCountdown = 60);
    _retryTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _retryCountdown = (_retryCountdown ?? 1) - 1;
        if (_retryCountdown! <= 0) {
          t.cancel();
          _retryCountdown = null;
          _startDownload();
        }
      });
    });
  }

  void _cancelRetryCountdown() {
    _retryTimer?.cancel();
    setState(() => _retryCountdown = null);
  }

  Future<void> _startDownload() async {
    final url = widget.info.apkDownloadUrl;
    final version = widget.info.latestVersion;
    if (url == null || url.isEmpty || version == null) {
      setState(() {
        _stage = _UpdateStage.error;
        _errorMsg = 'Kein Download-Link verfügbar.';
      });
      return;
    }

    _cancelRetryCountdown();
    setState(() {
      _stage = _UpdateStage.downloading;
      _errorMsg = null;
    });

    try {
      final file = await ApkDownloadService.instance.downloadApk(
        url: url,
        version: version,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _progress = p);
        },
      );
      if (!mounted) return;
      setState(() {
        _stage = _UpdateStage.downloaded;
        _apkFile = file;
      });
      // Automatisch Installer öffnen
      await _installApk();
    } catch (e) {
      if (!mounted) return;
      final msg = _friendlyError(e);
      setState(() {
        _stage = _UpdateStage.error;
        _errorMsg = msg;
      });
      // Bei 404: APK noch nicht fertig → automatisch in 60s wiederholen
      if (e is DioException &&
          e.type == DioExceptionType.badResponse &&
          e.response?.statusCode == 404) {
        _startRetryCountdown();
      }
    }
  }

  static String _friendlyError(Object e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return 'Zeitüberschreitung beim Download.\nBitte Verbindung prüfen und erneut versuchen.';
        case DioExceptionType.connectionError:
          return 'Keine Internetverbindung.\nBitte WLAN oder Mobilfunk prüfen.';
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          if (status == 404) {
            return 'Update-Datei noch nicht verfügbar.\nBitte in einigen Minuten erneut versuchen.';
          }
          if (status != null && status >= 500) {
            return 'Server-Fehler (HTTP $status).\nBitte später erneut versuchen.';
          }
          return 'Download fehlgeschlagen (HTTP $status).\nBitte erneut versuchen.';
        case DioExceptionType.cancel:
          return 'Download abgebrochen.';
        default:
          break;
      }
    }
    return 'Download fehlgeschlagen.\nBitte Verbindung prüfen und erneut versuchen.';
  }

  Future<void> _installApk() async {
    final file = _apkFile;
    if (file == null) return;
    _installAttempts++;
    setState(() => _stage = _UpdateStage.installing);
    final ok = await ApkDownloadService.instance.installApk(file);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _stage = _UpdateStage.error;
        if (_installAttempts >= 2) {
          // Wahrscheinlich Signatur-Mismatch (alte Debug-Key-APK).
          // Klare Anleitung + Notausgang wird im Build unten aktiviert.
          _errorMsg = 'Die Installation schlägt wiederholt fehl. '
              'Wahrscheinlich wurde deine aktuelle Version mit einem '
              'anderen Signatur-Schlüssel gebaut.\n\n'
              'Lösung: App deinstallieren → neue APK installieren.\n'
              '(Hinweis: Lokale Daten gehen dabei verloren, '
              'aber dein Profil wird automatisch wiederhergestellt.)';
        } else {
          _errorMsg = 'Installer konnte nicht geöffnet werden. '
              'Bitte in Einstellungen "Aus unbekannten Quellen installieren" '
              'für die Weltenbibliothek erlauben.';
        }
      });
    }
    // Bei ok: User bleibt im installing-State, Android übernimmt.
  }

  void _cancelDownload() {
    ApkDownloadService.instance.cancel();
    setState(() {
      _stage = _UpdateStage.idle;
      _progress = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Notausgang erlauben sobald 2+ Installationsversuche fehlgeschlagen sind
    // (typisch für Signatur-Mismatch bei alten Debug-Key-APKs).
    final allowEscape =
        _stage == _UpdateStage.error && _installAttempts >= 2;
    final canPop = !widget.info.isForced || allowEscape;

    return PopScope(
      canPop: canPop,
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 48),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    _buildHero(),
                    const SizedBox(height: 32),
                    if ((widget.info.changelog ?? '').trim().isNotEmpty)
                      _buildChangelog(),
                    const Spacer(),
                    _buildActionArea(),
                    const SizedBox(height: 24),
                    _buildFooter(canPop),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────────────── HERO (Icon + Version-Pills) ─────────────────────

  Widget _buildHero() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_blue, _cyan.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.4),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.system_update_alt,
              color: Colors.white, size: 52),
        ),
        const SizedBox(height: 24),
        const Text('Update verfügbar',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2)),
        const SizedBox(height: 10),
        Text(
          'Eine neue Version der Weltenbibliothek ist bereit.\n'
          'Bitte jetzt aktualisieren.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              height: 1.45),
        ),
        const SizedBox(height: 24),
        _buildVersionPills(),
      ],
    );
  }

  Widget _buildVersionPills() {
    return Row(
      children: [
        Expanded(
          child: _pill(
            'Installiert',
            widget.info.currentVersion ?? '—',
            Colors.white.withValues(alpha: 0.06),
            Colors.white.withValues(alpha: 0.7),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.arrow_forward, color: _cyan.withValues(alpha: 0.8)),
        ),
        Expanded(
          child: _pill(
            'Neu',
            widget.info.latestVersion ?? '—',
            _blue.withValues(alpha: 0.22),
            Colors.white,
            highlight: true,
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, String value, Color bg, Color textColor,
      {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: highlight
            ? Border.all(color: _blue.withValues(alpha: 0.6))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: textColor.withValues(alpha: 0.6), fontSize: 11)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ───────────────────────── Changelog ─────────────────────────

  Widget _buildChangelog() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: _cyan, size: 18),
              const SizedBox(width: 8),
              const Text('Was ist neu?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          // User-freundliche Changelog-Übersetzung — keine technischen
          // Commit-Messages mehr, sondern verständliche Beschreibungen
          // gruppiert nach Neue Funktionen / Verbessert / Behoben.
          _FriendlyChangelogView(raw: widget.info.changelog!.trim()),
        ],
      ),
    );
  }

  // ───────────────────────── Action-Area (je nach Stage) ─────────────────────

  Widget _buildActionArea() {
    switch (_stage) {
      case _UpdateStage.idle:
        return _buildDownloadButton();
      case _UpdateStage.downloading:
        return _buildDownloadProgress();
      case _UpdateStage.downloaded:
      case _UpdateStage.installing:
        return _buildInstallingInfo();
      case _UpdateStage.error:
        return _buildErrorState();
    }
  }

  Widget _buildDownloadButton() {
    return FutureBuilder<int?>(
      future: _apkSizeFuture,
      builder: (context, snap) {
        final sizeLabel = snap.hasData && snap.data != null
            ? ' (~${_formatBytes(snap.data!)})'
            : '';
        return SizedBox(
          height: 58,
          child: ElevatedButton.icon(
            onPressed: _startDownload,
            icon: const Icon(Icons.download_rounded, size: 24),
            label: Text(
              'Herunterladen & installieren$sizeLabel',
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadProgress() {
    final p = _progress;
    final percent = p?.percent ?? 0;
    final received = _formatBytes(p?.receivedBytes ?? 0);
    final total = p != null && p.totalBytes > 0
        ? _formatBytes(p.totalBytes)
        : '…';
    final speed = p != null && p.speedBytesPerSec > 0
        ? '${_formatBytes(p.speedBytesPerSec.toInt())}/s'
        : '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _blue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Wird heruntergeladen…',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              Text('${percent.toStringAsFixed(0)} %',
                  style: const TextStyle(
                      color: _cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent > 0 ? percent / 100 : null,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation(_cyan),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('$received / $total',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12)),
              const Spacer(),
              if (speed.isNotEmpty)
                Text(speed,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12)),
            ],
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: _cancelDownload,
            style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.7)),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallingInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _green.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: _green, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text('Download abgeschlossen',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Der Android-Installer öffnet sich automatisch. '
            'Bitte auf "Installieren" tippen, um das Update abzuschließen.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.45),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _stage == _UpdateStage.installing ? null : _installApk,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Installer erneut öffnen'),
            style: TextButton.styleFrom(foregroundColor: _green),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final showEscape = _installAttempts >= 2;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _red.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.error_outline, color: _red, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Update fehlgeschlagen',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _errorMsg ?? 'Unbekannter Fehler.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.45),
          ),
          const SizedBox(height: 16),
          if (_retryCountdown != null) ...[
            // Countdown: APK noch nicht fertig, automatischer Retry
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: _retryCountdown! / 60,
                      strokeWidth: 2.5,
                      color: _cyan,
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Automatischer Neuversuch in ${_retryCountdown}s…',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _cancelRetryCountdown();
                      _startDownload();
                    },
                    style: TextButton.styleFrom(
                        foregroundColor: _cyan,
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 8)),
                    child: const Text('Sofort', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _startDownload,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
          if (showEscape) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.75),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'App trotzdem weiter nutzen',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────── Footer ─────────────────────────

  Widget _buildFooter(bool canPop) {
    return Column(
      children: [
        Text(
          canPop
              ? 'Tipp: Du kannst die App weiter nutzen und später updaten.'
              : 'Dieses Update ist erforderlich, um die App weiter nutzen zu können.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 11.5,
              height: 1.4),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            if (canPop) {
              Navigator.of(context).maybePop();
            } else {
              SystemNavigator.pop();
            }
          },
          style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.5),
              minimumSize: const Size(0, 36)),
          child: Text(
            canPop ? 'Später' : 'App beenden',
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ───────────────────────── Helpers ─────────────────────────

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}

/// Rendert einen rohen Changelog-String (Git-Commits) als 3 Kategorien
/// mit nutzerfreundlichen Texten (Neue Funktionen / Verbessert / Behoben).
class _FriendlyChangelogView extends StatelessWidget {
  final String raw;
  const _FriendlyChangelogView({required this.raw});

  @override
  Widget build(BuildContext context) {
    final friendly = parseFriendlyChangelog(raw);
    if (friendly.isEmpty) {
      return Text(
        'Keine sichtbaren Änderungen für diese Version.',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cat in friendly.categories)
          if (!cat.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 6),
              child: Row(
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    cat.title,
                    style: TextStyle(
                      color: cat.color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            for (final item in cat.items)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 4),
                child: Text(
                  '•  $item',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 6),
          ],
      ],
    );
  }
}
