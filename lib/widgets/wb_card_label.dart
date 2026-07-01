/// Unified micro-label for cards (e.g. "TAGESKARTE", "TOP ARTIKEL",
/// "KERN-TOOL"). Single source of truth so category labels share one weight
/// and letter-spacing across all worlds (Feature A3).
library;

import 'package:flutter/material.dart';

class WbCardLabel extends StatelessWidget {
  final String text;
  final Color color;

  const WbCardLabel(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    );
  }
}
