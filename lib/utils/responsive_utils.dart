import 'package:flutter/material.dart';

/// Responsive Design Utilities für Weltenbibliothek
/// Automatische Anpassung an verschiedene Bildschirmgrößen
class ResponsiveUtils {
  /// Bildschirmbreite
  final double screenWidth;
  
  /// Bildschirmhöhe
  final double screenHeight;
  
  /// Gerätegröße-Kategorie
  final DeviceSize deviceSize;

  ResponsiveUtils({
    required this.screenWidth,
    required this.screenHeight,
  }) : deviceSize = _getDeviceSize(screenWidth);

  /// Factory-Konstruktor aus BuildContext
  factory ResponsiveUtils.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return ResponsiveUtils(
      screenWidth: size.width,
      screenHeight: size.height,
    );
  }

  /// Bestimme Gerätegröße basierend auf Breite
  static DeviceSize _getDeviceSize(double width) {
    if (width < 600) return DeviceSize.small;  // Smartphones
    if (width < 1024) return DeviceSize.medium; // Tablets
    return DeviceSize.large;                    // Desktop/Web
  }

  // ==================== RESPONSIVE SCHRIFTGROSSEN ====================
  
  /// Titel-Schriftgröße (Hauptüberschriften)
  double get titleFontSize {
    switch (deviceSize) {
      case DeviceSize.small:
        return 24.0;
      case DeviceSize.medium:
        return 28.0;
      case DeviceSize.large:
        return 32.0;
    }
  }

  /// Große Überschrift
  double get headingLargeFontSize {
    switch (deviceSize) {
      case DeviceSize.small:
        return 20.0;
      case DeviceSize.medium:
        return 24.0;
      case DeviceSize.large:
        return 28.0;
    }
  }

  /// Mittlere Überschrift
  double get headingMediumFontSize {
    switch (deviceSize) {
      case DeviceSize.small:
        return 18.0;
      case DeviceSize.medium:
        return 20.0;
      case DeviceSize.large:
        return 22.0;
    }
  }

  /// Kleine Überschrift
  double get headingSmallFontSize {
    switch (deviceSize) {
      case DeviceSize.small:
        return 16.0;
      case DeviceSize.medium:
        return 18.0;
      case DeviceSize.large:
        return 20.0;
    }
  }

  /// Body-Text (Standard-Fließtext)
  double get bodyFontSize {
    switch (deviceSize) {
      case DeviceSize.small:
        return 14.0;
      case DeviceSize.medium:
        return 16.0;
      case DeviceSize.large:
        return 18.0;
    }
  }

  /// Kleiner Text (Labels, Metadaten)
  double get smallFontSize {
    switch (deviceSize) {
      case DeviceSize.small:
        return 12.0;
      case DeviceSize.medium:
        return 14.0;
      case DeviceSize.large:
        return 16.0;
    }
  }

  /// Extra kleiner Text (Timestamps, Hinweise)
  double get extraSmallFontSize {
    switch (deviceSize) {
      case DeviceSize.small:
        return 10.0;
      case DeviceSize.medium:
        return 12.0;
      case DeviceSize.large:
        return 14.0;
    }
  }

  // ==================== RESPONSIVE ABSTÄNDE ====================

  /// Extra kleiner Abstand
  double get spacingXs {
    switch (deviceSize) {
      case DeviceSize.small:
        return 4.0;
      case DeviceSize.medium:
        return 6.0;
      case DeviceSize.large:
        return 8.0;
    }
  }

  /// Kleiner Abstand
  double get spacingSm {
    switch (deviceSize) {
      case DeviceSize.small:
        return 8.0;
      case DeviceSize.medium:
        return 10.0;
      case DeviceSize.large:
        return 12.0;
    }
  }

  /// Mittlerer Abstand
  double get spacingMd {
    switch (deviceSize) {
      case DeviceSize.small:
        return 12.0;
      case DeviceSize.medium:
        return 16.0;
      case DeviceSize.large:
        return 20.0;
    }
  }

  /// Großer Abstand
  double get spacingLg {
    switch (deviceSize) {
      case DeviceSize.small:
        return 16.0;
      case DeviceSize.medium:
        return 20.0;
      case DeviceSize.large:
        return 24.0;
    }
  }

  /// Extra großer Abstand
  double get spacingXl {
    switch (deviceSize) {
      case DeviceSize.small:
        return 24.0;
      case DeviceSize.medium:
        return 32.0;
      case DeviceSize.large:
        return 40.0;
    }
  }

  // ==================== RESPONSIVE ELEVATIONS ====================
  
  /// Extra kleine Elevation (Subtle)
  double get elevationXs => 1.0;
  
  /// Kleine Elevation (Cards, Buttons)
  double get elevationSm => 2.0;
  
  /// Mittlere Elevation (Modal, Floating)
  double get elevationMd => 4.0;
  
  /// Große Elevation (Dialogs, Drawers)
  double get elevationLg => 8.0;
  
  /// Extra große Elevation (Special)
  double get elevationXl => 12.0;

  // ==================== RESPONSIVE ICON-GROSSEN ====================

  /// Extra kleine Icon-Größe
  double get iconSizeXs {
    switch (deviceSize) {
      case DeviceSize.small:
        return 12.0;
      case DeviceSize.medium:
        return 14.0;
      case DeviceSize.large:
        return 16.0;
    }
  }

  /// Kleine Icon-Größe
  double get iconSizeSm {
    switch (deviceSize) {
      case DeviceSize.small:
        return 16.0;
      case DeviceSize.medium:
        return 18.0;
      case DeviceSize.large:
        return 20.0;
    }
  }

  /// Mittlere Icon-Größe
  double get iconSizeMd {
    switch (deviceSize) {
      case DeviceSize.small:
        return 20.0;
      case DeviceSize.medium:
        return 24.0;
      case DeviceSize.large:
        return 28.0;
    }
  }

  /// Große Icon-Größe
  double get iconSizeLg {
    switch (deviceSize) {
      case DeviceSize.small:
        return 28.0;
      case DeviceSize.medium:
        return 32.0;
      case DeviceSize.large:
        return 36.0;
    }
  }

  /// Extra große Icon-Größe
  double get iconSizeXl {
    switch (deviceSize) {
      case DeviceSize.small:
        return 40.0;
      case DeviceSize.medium:
        return 48.0;
      case DeviceSize.large:
        return 56.0;
    }
  }

  /// 3XL Icon-Größe (Avatars, Large Icons)
  double get iconSize3Xl {
    switch (deviceSize) {
      case DeviceSize.small:
        return 48.0;
      case DeviceSize.medium:
        return 56.0;
      case DeviceSize.large:
        return 64.0;
    }
  }

  // ==================== RESPONSIVE BUTTON-GROSSEN ====================

  /// Button-Höhe (Standard)
  double get buttonHeight {
    switch (deviceSize) {
      case DeviceSize.small:
        return 44.0;  // Apple Human Interface Guidelines: min 44px
      case DeviceSize.medium:
        return 48.0;
      case DeviceSize.large:
        return 52.0;
    }
  }

  /// Kompakter Button (Small)
  double get buttonHeightSm {
    switch (deviceSize) {
      case DeviceSize.small:
        return 36.0;
      case DeviceSize.medium:
        return 40.0;
      case DeviceSize.large:
        return 44.0;
    }
  }

  /// Großer Button (z.B. CTA-Buttons)
  double get buttonHeightLg {
    switch (deviceSize) {
      case DeviceSize.small:
        return 52.0;
      case DeviceSize.medium:
        return 56.0;
      case DeviceSize.large:
        return 60.0;
    }
  }

  // ==================== RESPONSIVE BORDER RADIUS ====================

  /// Extra kleiner Border Radius
  double get borderRadiusXs {
    switch (deviceSize) {
      case DeviceSize.small:
        return 4.0;
      case DeviceSize.medium:
        return 6.0;
      case DeviceSize.large:
        return 8.0;
    }
  }

  /// Kleiner Border Radius
  double get borderRadiusSm {
    switch (deviceSize) {
      case DeviceSize.small:
        return 8.0;
      case DeviceSize.medium:
        return 10.0;
      case DeviceSize.large:
        return 12.0;
    }
  }

  /// Mittlerer Border Radius
  double get borderRadiusMd {
    switch (deviceSize) {
      case DeviceSize.small:
        return 12.0;
      case DeviceSize.medium:
        return 14.0;
      case DeviceSize.large:
        return 16.0;
    }
  }

  /// Großer Border Radius
  double get borderRadiusLg {
    switch (deviceSize) {
      case DeviceSize.small:
        return 16.0;
      case DeviceSize.medium:
        return 20.0;
      case DeviceSize.large:
        return 24.0;
    }
  }

  // ==================== RESPONSIVE CARD-GROSSEN ====================

  /// Card-Padding
  EdgeInsets get cardPadding {
    switch (deviceSize) {
      case DeviceSize.small:
        return const EdgeInsets.all(12.0);
      case DeviceSize.medium:
        return const EdgeInsets.all(16.0);
      case DeviceSize.large:
        return const EdgeInsets.all(20.0);
    }
  }

  /// List Item Höhe
  double get listItemHeight {
    switch (deviceSize) {
      case DeviceSize.small:
        return 72.0;
      case DeviceSize.medium:
        return 80.0;
      case DeviceSize.large:
        return 88.0;
    }
  }

  // ==================== RESPONSIVE PROZENTUALE BREITEN ====================

  /// Prozentuale Breite (0.0 - 1.0)
  double widthPercent(double percent) => screenWidth * percent;

  /// Prozentuale Höhe (0.0 - 1.0)
  double heightPercent(double percent) => screenHeight * percent;

  // ==================== HELPER METHODS ====================

  /// Ist kleines Gerät (Smartphone)?
  bool get isSmallDevice => deviceSize == DeviceSize.small;

  /// Ist mittleres Gerät (Tablet)?
  bool get isMediumDevice => deviceSize == DeviceSize.medium;

  /// Ist großes Gerät (Desktop)?
  bool get isLargeDevice => deviceSize == DeviceSize.large;

  /// Ist Portrait-Modus?
  bool get isPortrait => screenHeight > screenWidth;

  /// Ist Landscape-Modus?
  bool get isLandscape => screenWidth > screenHeight;

  /// Dynamische Skalierung basierend auf Bildschirmbreite
  /// Basis: 375px (iPhone SE/Standard-Smartphone)
  double scale(double value) => (screenWidth / 375.0) * value;

  /// Vertikale Skalierung basierend auf Bildschirmhöhe
  /// Basis: 812px (Standard-Smartphone-Höhe)
  double scaleVertical(double value) => (screenHeight / 812.0) * value;
}

/// Gerätegröße-Kategorien
enum DeviceSize {
  small,  // < 600px (Smartphones)
  medium, // 600-1023px (Tablets)
  large,  // >= 1024px (Desktop/Web)
}

/// Extension für einfachen Zugriff auf ResponsiveUtils
extension ResponsiveExtension on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils.of(this);
  
  /// Schnellzugriff: Bildschirmbreite
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Schnellzugriff: Bildschirmhöhe
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Schnellzugriff: Ist kleines Gerät?
  bool get isSmallDevice => ResponsiveUtils.of(this).isSmallDevice;
  
  /// Schnellzugriff: Ist mittleres Gerät?
  bool get isMediumDevice => ResponsiveUtils.of(this).isMediumDevice;
  
  /// Schnellzugriff: Ist großes Gerät?
  bool get isLargeDevice => ResponsiveUtils.of(this).isLargeDevice;
}
