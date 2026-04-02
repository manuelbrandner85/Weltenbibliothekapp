import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Responsive Spacing Widgets
/// Automatische Anpassung von Abständen an Bildschirmgröße
class ResponsiveSpacing {
  /// Vertikaler Abstand (SizedBox)
  static Widget verticalXs(BuildContext context) => SizedBox(
        height: ResponsiveUtils.of(context).spacingXs,
      );

  static Widget verticalSm(BuildContext context) => SizedBox(
        height: ResponsiveUtils.of(context).spacingSm,
      );

  static Widget verticalMd(BuildContext context) => SizedBox(
        height: ResponsiveUtils.of(context).spacingMd,
      );

  static Widget verticalLg(BuildContext context) => SizedBox(
        height: ResponsiveUtils.of(context).spacingLg,
      );

  static Widget verticalXl(BuildContext context) => SizedBox(
        height: ResponsiveUtils.of(context).spacingXl,
      );

  /// Horizontaler Abstand (SizedBox)
  static Widget horizontalXs(BuildContext context) => SizedBox(
        width: ResponsiveUtils.of(context).spacingXs,
      );

  static Widget horizontalSm(BuildContext context) => SizedBox(
        width: ResponsiveUtils.of(context).spacingSm,
      );

  static Widget horizontalMd(BuildContext context) => SizedBox(
        width: ResponsiveUtils.of(context).spacingMd,
      );

  static Widget horizontalLg(BuildContext context) => SizedBox(
        width: ResponsiveUtils.of(context).spacingLg,
      );

  static Widget horizontalXl(BuildContext context) => SizedBox(
        width: ResponsiveUtils.of(context).spacingXl,
      );

  /// Custom vertikaler Abstand
  static Widget verticalCustom(BuildContext context, double multiplier) =>
      SizedBox(
        height: ResponsiveUtils.of(context).spacingMd * multiplier,
      );

  /// Custom horizontaler Abstand
  static Widget horizontalCustom(BuildContext context, double multiplier) =>
      SizedBox(
        width: ResponsiveUtils.of(context).spacingMd * multiplier,
      );
}

/// Extension für einfachen Zugriff auf Spacing
extension SpacingExtension on BuildContext {
  /// Vertikale Abstände
  Widget get vSpaceXs => ResponsiveSpacing.verticalXs(this);
  Widget get vSpaceSm => ResponsiveSpacing.verticalSm(this);
  Widget get vSpaceMd => ResponsiveSpacing.verticalMd(this);
  Widget get vSpaceLg => ResponsiveSpacing.verticalLg(this);
  Widget get vSpaceXl => ResponsiveSpacing.verticalXl(this);

  /// Horizontale Abstände
  Widget get hSpaceXs => ResponsiveSpacing.horizontalXs(this);
  Widget get hSpaceSm => ResponsiveSpacing.horizontalSm(this);
  Widget get hSpaceMd => ResponsiveSpacing.horizontalMd(this);
  Widget get hSpaceLg => ResponsiveSpacing.horizontalLg(this);
  Widget get hSpaceXl => ResponsiveSpacing.horizontalXl(this);

  /// Custom Abstände
  Widget vSpace(double multiplier) =>
      ResponsiveSpacing.verticalCustom(this, multiplier);
  Widget hSpace(double multiplier) =>
      ResponsiveSpacing.horizontalCustom(this, multiplier);
}

/// Responsive Padding Helper
class ResponsivePadding {
  /// EdgeInsets basierend auf Spacing-Level
  static EdgeInsets all(BuildContext context, SpacingLevel level) {
    final spacing = _getSpacing(context, level);
    return EdgeInsets.all(spacing);
  }

  static EdgeInsets symmetric(
    BuildContext context, {
    SpacingLevel? horizontal,
    SpacingLevel? vertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: horizontal != null ? _getSpacing(context, horizontal) : 0,
      vertical: vertical != null ? _getSpacing(context, vertical) : 0,
    );
  }

  static EdgeInsets only(
    BuildContext context, {
    SpacingLevel? left,
    SpacingLevel? top,
    SpacingLevel? right,
    SpacingLevel? bottom,
  }) {
    return EdgeInsets.only(
      left: left != null ? _getSpacing(context, left) : 0,
      top: top != null ? _getSpacing(context, top) : 0,
      right: right != null ? _getSpacing(context, right) : 0,
      bottom: bottom != null ? _getSpacing(context, bottom) : 0,
    );
  }

  /// Helper: Spacing-Wert abrufen
  static double _getSpacing(BuildContext context, SpacingLevel level) {
    final responsive = ResponsiveUtils.of(context);
    switch (level) {
      case SpacingLevel.xs:
        return responsive.spacingXs;
      case SpacingLevel.sm:
        return responsive.spacingSm;
      case SpacingLevel.md:
        return responsive.spacingMd;
      case SpacingLevel.lg:
        return responsive.spacingLg;
      case SpacingLevel.xl:
        return responsive.spacingXl;
    }
  }
}

/// Spacing-Level Enum
enum SpacingLevel { xs, sm, md, lg, xl }

/// Extension für einfachen Zugriff auf Padding
extension PaddingExtension on BuildContext {
  /// Padding helper
  EdgeInsets paddingAll(SpacingLevel level) =>
      ResponsivePadding.all(this, level);

  EdgeInsets paddingSymmetric({
    SpacingLevel? horizontal,
    SpacingLevel? vertical,
  }) =>
      ResponsivePadding.symmetric(
        this,
        horizontal: horizontal,
        vertical: vertical,
      );

  EdgeInsets paddingOnly({
    SpacingLevel? left,
    SpacingLevel? top,
    SpacingLevel? right,
    SpacingLevel? bottom,
  }) =>
      ResponsivePadding.only(
        this,
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      );

  /// Schnellzugriff für häufig verwendete Paddings
  EdgeInsets get paddingXs => ResponsivePadding.all(this, SpacingLevel.xs);
  EdgeInsets get paddingSm => ResponsivePadding.all(this, SpacingLevel.sm);
  EdgeInsets get paddingMd => ResponsivePadding.all(this, SpacingLevel.md);
  EdgeInsets get paddingLg => ResponsivePadding.all(this, SpacingLevel.lg);
  EdgeInsets get paddingXl => ResponsivePadding.all(this, SpacingLevel.xl);

  EdgeInsets get paddingHorizontalMd => ResponsivePadding.symmetric(
        this,
        horizontal: SpacingLevel.md,
      );

  EdgeInsets get paddingVerticalMd => ResponsivePadding.symmetric(
        this,
        vertical: SpacingLevel.md,
      );
}
