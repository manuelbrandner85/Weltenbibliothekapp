import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/wb_cinematic_tokens.dart';

enum WBGlowButtonVariant { primary, secondary, ghost }

/// CTA-Button im cinematic Welt-Stil.
///
/// • `primary`   — gefüllter Welt-Gradient + Glow-Shadow
/// • `secondary` — Glass-Background + Welt-Stroke
/// • `ghost`     — nur Welt-Text, transparenter Background
///
/// Press-Feedback: scale 0.98 + Glow-Boost + light haptic.
class WBGlowButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final WBWorld world;
  final WBGlowButtonVariant variant;
  final bool fullWidth;
  final EdgeInsetsGeometry padding;

  const WBGlowButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.world = WBWorld.neutral,
    this.variant = WBGlowButtonVariant.primary,
    this.fullWidth = false,
    this.padding =
        const EdgeInsets.symmetric(horizontal: WBSpace.xxl, vertical: 14),
  });

  @override
  State<WBGlowButton> createState() => _WBGlowButtonState();
}

class _WBGlowButtonState extends State<WBGlowButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed != v) setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final wb = context.wb;
    final palette = wb.palette(widget.world);
    final disabled = widget.onPressed == null;

    final BoxDecoration deco;
    final Color textColor;

    switch (widget.variant) {
      case WBGlowButtonVariant.primary:
        deco = BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.primary,
              palette.deep,
            ],
          ),
          borderRadius: BorderRadius.circular(WBRadius.md),
          boxShadow: disabled
              ? const []
              : [
                  BoxShadow(
                    color: palette.primary
                        .withValues(alpha: _pressed ? 0.65 : 0.40),
                    blurRadius: _pressed ? 36 : 24,
                    spreadRadius: _pressed ? 2 : 0,
                    offset: const Offset(0, 6),
                  ),
                ],
        );
        textColor = Colors.white;
        break;
      case WBGlowButtonVariant.secondary:
        deco = BoxDecoration(
          color: wb.glassBase,
          borderRadius: BorderRadius.circular(WBRadius.md),
          border: Border.all(
              color:
                  palette.primary.withValues(alpha: _pressed ? 0.85 : 0.55),
              width: 1.2),
          boxShadow: disabled || !_pressed
              ? const []
              : [
                  BoxShadow(
                    color: palette.primary.withValues(alpha: 0.30),
                    blurRadius: 18,
                  ),
                ],
        );
        textColor = palette.label;
        break;
      case WBGlowButtonVariant.ghost:
        deco = BoxDecoration(
          color: _pressed ? palette.primary.withValues(alpha: 0.10) : null,
          borderRadius: BorderRadius.circular(WBRadius.md),
        );
        textColor = palette.label;
        break;
    }

    final content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: textColor, size: 18),
          const SizedBox(width: WBSpace.sm),
        ],
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 13,
            letterSpacing: 1.6,
            color: textColor.withValues(alpha: disabled ? 0.40 : 1.0),
          ),
        ),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => _setPressed(true),
      onTapCancel: disabled ? null : () => _setPressed(false),
      onTap: disabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              _setPressed(false);
              widget.onPressed!();
            },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: WBMotion.press,
        curve: WBMotion.enterCurve,
        child: AnimatedContainer(
          duration: WBMotion.press,
          curve: WBMotion.enterCurve,
          padding: widget.padding,
          decoration: deco,
          child: content,
        ),
      ),
    );
  }
}
