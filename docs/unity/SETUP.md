# Unity-Integration (flutter_unity_widget)

Dieses Dokument beschreibt die EINMALIGEN, lokalen Schritte, um echte
Unity-3D-Inhalte in die App zu bekommen. Die Flutter-Seite (Dependency +
`WbUnityView` Gating-Widget) ist bereits vorbereitet. Solange der
`unityLibrary`-Export FEHLT, zeigt `WbUnityView` auf jedem Geraet den
Fallback an -- die App baut und laeuft normal weiter.

> WICHTIG: Diese Schritte brauchen Unity Editor + Android SDK/Xcode lokal.
> Sie koennen NICHT im Cloud-Container erledigt werden. Bevor der
> Unity-Export gemacht ist, darf der Unity-PR NICHT auf `main` gemergt
> werden -- sonst schlaegt der Release-APK-Build fehl (`unityLibrary`
> fehlt) und die CI wird rot.

## 1. Unity-Projekt anlegen
- Unity Hub + Unity **2022.3 LTS** installieren.
- Neues 3D-(URP)-Projekt `weltenbibliothek_unity` anlegen.
- Package `flutter_unity_widget` Unity-Seite einbinden: das Repo
  https://github.com/juicycleff/flutter-unity-view-widget enthaelt unter
  `unity/` die `FlutterUnityIntegration` Unity-Assets -> in das
  Unity-Projekt importieren (Plugins/FlutterUnityIntegration).

## 2. Build Settings
- Platform auf **Android** (bzw. iOS) wechseln.
- Player Settings:
  - Scripting Backend: **IL2CPP**, Target Architectures: **ARM64** (+ ARMv7
    optional). KEIN x86.
  - Graphics: OpenGLES3 (oder Vulkan), Minify aktiv.
  - Stripping: High (kleinere Lib).
- Szene(n) bauen, die per `WbUnityView` geladen werden (z.B. `MentorAvatar`).

## 3. Export als Library
- Menue **Flutter > Export Android (Release)** ->
  exportiert nach `<flutter-projekt>/android/unityLibrary`.
- (iOS) **Flutter > Export iOS** -> `<flutter-projekt>/ios/UnityLibrary`.

## 4. Gradle/Xcode verdrahten
Android `android/settings.gradle`:
```
include ":unityLibrary"
project(":unityLibrary").projectDir = file("./unityLibrary")
```
`android/app/build.gradle` (dependencies):
```
implementation project(':unityLibrary')
```
Ggf. `android/build.gradle` flatDir-Repo fuer `unityLibrary/libs` ergaenzen
(siehe Plugin-README). iOS: `UnityFramework.framework` in Runner einbinden.

## 5. Build-Nummer / Release
- Unity = nativ -> kein OTA-Patch. Versions-NAME bumpen (z.B. `5.64.0`),
  dann Release via `build_apk.yml` (Tag-Push) -> `shorebird_release.yml`.
- APK waechst um ~20-40 MB (Unity-Runtime). Ggf. eigenen `3D`-Flavor
  erwaegen, damit das Lite-APK klein bleibt (siehe U9-Vorschlag).

## 6. Nutzung in Flutter
```dart
WbUnityView(
  // Nur auf High-Tier-Geraeten sichtbar; sonst dieser Fallback:
  fallback: const SomeLightweight2DWidget(),
  onCreated: (c) {
    // z.B. Lip-Sync-Amplitude an Unity senden:
    // c.postMessage('MentorAvatar', 'SetMouth', '0.7');
  },
)
```
`WbUnityView.allowed(context)` respektiert DeviceTier (`WbQuality.heavyEffects`),
Reduce-Motion und Web. `forceEnable: true` umgeht nur das Tier-Gate (nicht
Reduce-Motion/Web) -- z.B. fuer einen bewusst geoeffneten 3D-Screen.

## Geplante 3D-Features (Roadmap)
- U1 3D-Mentor-Avatar (Lip-Sync zur LiveKit-Stimme) -- Pilot.
- U2 Energie: interaktiver 3D-Chakren-Koerper.
- U3 Ursprung: 3D Heilige Geometrie / Gateway.
- U4 Materie: 3D-Machtnetz-Globus.
- U5 Vorhang: 3D-Buehne. U6 Meditation-Szenen. U7 3D-Trophaeen.
