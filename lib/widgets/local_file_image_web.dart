// Web-Implementation: dart:io.File existiert nicht. Lokale Datei-Pfade lassen
// sich im Browser ohnehin nicht direkt anzeigen — daher Platzhalter.
import 'package:flutter/material.dart';

Widget localFileImage(String path,
    {BoxFit fit = BoxFit.cover, Widget? errorWidget}) {
  return errorWidget ??
      Container(
        color: const Color(0xFF1A1A2E),
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              color: Colors.white24, size: 48),
        ),
      );
}
