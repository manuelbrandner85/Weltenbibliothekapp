package com.myapp.mobile

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val pipChannel = "weltenbibliothek/pip"
    private val restartChannel = "weltenbibliothek/restart"
    private var pipMethodChannel: MethodChannel? = null
    private var inPipMode = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── PiP-Channel ────────────────────────────────────────────────────
        pipMethodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            pipChannel,
        )
        pipMethodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enterPip" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val params = PictureInPictureParams.Builder()
                            .setAspectRatio(Rational(9, 16))
                            .build()
                        enterPictureInPictureMode(params)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                "isSupported" -> {
                    result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                }
                else -> result.notImplemented()
            }
        }

        // ── Restart-Channel (Phase 2 — bereits vorhanden) ──────────────────
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            restartChannel,
        ).setMethodCallHandler { call, result ->
            if (call.method == "restartApp") {
                val intent = packageManager.getLaunchIntentForPackage(packageName)
                val delay = call.argument<Int>("delayMs")?.toLong() ?: 500L
                val alarmMgr =
                    getSystemService(ALARM_SERVICE) as android.app.AlarmManager
                val pi = android.app.PendingIntent.getActivity(
                    this, 0, intent!!,
                    android.app.PendingIntent.FLAG_CANCEL_CURRENT or
                            android.app.PendingIntent.FLAG_IMMUTABLE,
                )
                alarmMgr.set(
                    android.app.AlarmManager.RTC,
                    System.currentTimeMillis() + delay,
                    pi,
                )
                android.os.Handler(android.os.Looper.getMainLooper()).postDelayed(
                    { System.exit(0) }, 50,
                )
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    // Wenn User Home-Taste drückt während Call aktiv → Flutter informieren
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            pipMethodChannel?.invokeMethod("onUserLeaveHint", null)
        }
    }

    // PiP-Modus gewechselt → Flutter informieren
    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        inPipMode = isInPictureInPictureMode
        pipMethodChannel?.invokeMethod(
            "onPipModeChanged",
            mapOf("active" to isInPictureInPictureMode),
        )
    }

    override fun onStop() {
        super.onStop()
        if (inPipMode) {
            pipMethodChannel?.invokeMethod("onPipModeChanged", mapOf("active" to false))
            inPipMode = false
        }
    }
}
