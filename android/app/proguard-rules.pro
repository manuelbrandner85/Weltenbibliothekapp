# 🎥 Agora RTC Engine ProGuard Rules
# Keep all Agora classes
-keep class io.agora.**{*;}
-keep class io.agora.rtc.** { *; }
-keep class io.agora.rtc2.** { *; }
-keep class io.agora.base.** { *; }
-keep class io.agora.media.** { *; }
-keep class io.agora.audio.** { *; }
-keep class io.agora.video.** { *; }

# Keep Google Desugar (für R8 Kompatibilität)
-keep class com.google.devtools.build.android.desugar.runtime.** { *; }
-dontwarn com.google.devtools.build.android.desugar.runtime.**

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Ignore Google Play Store Split Compatibility (optional dependency)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-ignorewarnings
