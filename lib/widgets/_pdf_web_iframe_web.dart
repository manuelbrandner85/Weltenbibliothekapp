// Web-Implementierung: PDF via natives <iframe src="...pdf">. Browser
// rendert PDFs eingebaut (Chrome, Edge, Firefox PDF.js).
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

final Set<String> _registered = {};

Widget buildPdfIframe(String url) {
  final viewType = 'pdf-${url.hashCode}';
  if (!_registered.contains(viewType)) {
    _registered.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final el = html.IFrameElement()
        ..src = url
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%';
      return el;
    });
  }
  return HtmlElementView(viewType: viewType);
}
