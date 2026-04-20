package com.weltenbibliothek.v49

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "weltenbibliothek/restart"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                if (call.method == "restartApp") {
                    scheduleRestart()
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }

    // Schedules the app to restart via AlarmManager after 500 ms, then kills the process.
    // AlarmManager.set() requires no special permission on any Android version.
    private fun scheduleRestart() {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: return
        launchIntent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_NEW_TASK)

        val pendingIntent = PendingIntent.getActivity(
            this, 0, launchIntent,
            PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        alarmManager.set(AlarmManager.RTC, System.currentTimeMillis() + 500, pendingIntent)

        // Small delay so result.success() is delivered to Dart before the process dies.
        android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
            System.exit(0)
        }, 50)
    }
}
