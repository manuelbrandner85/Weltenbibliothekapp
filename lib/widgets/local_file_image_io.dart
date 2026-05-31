// Mobile-Implementation: echtes dart:io File → Image.file.
import 'dart:io' if (dart.library.html) '../stubs/dart_io_stub.dart';

import 'package:flutter/material.dart';

Widget localFileImage(
  String path, {
  BoxFit fit = BoxFit.cover,
  Widget? errorWidget,
}) {
  return Image.file(
    File(path),
    fit: fit,
    errorBuilder: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
  );
}
