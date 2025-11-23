import 'package:flutter/material.dart';
import '../services/image_asset_service.dart';

/// Avatar mit Energy-Symbol (wird angezeigt wenn Kamera aus ist)
class EnergySymbolAvatar extends StatelessWidget {
  final String userId;
  final double size;
  final bool showBorder;

  const EnergySymbolAvatar({
    super.key,
    required this.userId,
    this.size = 120,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final symbolPath = ImageAssetService.getEnergySymbolForUser(userId);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: showBorder
            ? Border.all(
                color: const Color(0xFFFFD700), // Gold
                width: 3,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipOval(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            symbolPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.person, color: Color(0xFFFFD700), size: 48),
              );
            },
          ),
        ),
      ),
    );
  }
}
