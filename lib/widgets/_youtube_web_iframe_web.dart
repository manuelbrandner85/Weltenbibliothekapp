// Web-Implementierung des YouTube-Iframe via HtmlElementView.
// Wird nur über conditional import geladen wenn dart:html verfügbar ist.
// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

final Set<String> _registered = {};

Widget buildYoutubeIframe(String videoId, {double aspectRatio = 16 / 9}) {
  final viewType = 'yt-iframe-$videoId';
  if (!_registered.contains(viewType)) {
    _registered.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final el = html.IFrameElement()
        ..src =
            'https://www.youtube.com/embed/$videoId?rel=0&modestbranding=1&playsinline=1'
        ..style.border = '0'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allow = 'autoplay; encrypted-media; picture-in-picture'
        ..allowFullscreen = true;
      return el;
    });
  }
  return AspectRatio(
    aspectRatio: aspectRatio,
    child: HtmlElementView(viewType: viewType),
  );
}
