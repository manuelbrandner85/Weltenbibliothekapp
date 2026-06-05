import 'package:flutter/widgets.dart';

/// Lightweight, dependency-free responsive helpers.
///
/// Goal: the same screen renders cleanly on a tiny 320pt phone, a normal
/// 390pt phone and a 600pt+ tablet — without per-device branches everywhere.
///
/// Usage:
///   context.rw(16)   -> width-scaled spacing/size (clamped)
///   context.rf(14)   -> font size (tighter clamp so text never explodes)
///   context.isTablet / context.isSmallPhone -> coarse breakpoints
///
/// The scaling is intentionally clamped: on very large screens sizes grow only
/// modestly (so a tablet doesn't get cartoonishly huge controls) and on tiny
/// screens they shrink just enough to stop overflow/clipping.
extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenW => MediaQuery.sizeOf(this).width;
  double get screenH => MediaQuery.sizeOf(this).height;
  double get shortestSide => MediaQuery.sizeOf(this).shortestSide;

  /// Tablet / large-screen breakpoint (Material guideline: 600dp shortest side).
  bool get isTablet => shortestSide >= 600;

  /// Very small phones (e.g. older/compact Androids) where fixed sizes clip.
  bool get isSmallPhone => screenW < 360;

  /// Reference design width (iPhone 13/14 logical width).
  double get _wFactor => (screenW / 390).clamp(0.82, 1.35);
  double get _fFactor => (screenW / 390).clamp(0.88, 1.18);

  /// Width-proportional size for paddings, gaps, icon boxes, etc.
  double rw(double value) => value * _wFactor;

  /// Font-size scaler (tighter clamp than [rw] so text stays readable).
  double rf(double value) => value * _fFactor;
}

/// Clamps the OS text-scale into a safe range. Huge system font settings are
/// the #1 cause of "text cut off / overflow" reports — this keeps layouts
/// intact while still honouring a reasonable accessibility boost.
///
/// Wrap the app content in `MaterialApp.builder`:
///   builder: (context, child) => clampTextScale(context, child)
Widget clampTextScale(BuildContext context, Widget child) {
  final mq = MediaQuery.of(context);
  final clamped = mq.textScaler.clamp(
    minScaleFactor: 0.85,
    maxScaleFactor: 1.30,
  );
  return MediaQuery(
    data: mq.copyWith(textScaler: clamped),
    child: child,
  );
}
