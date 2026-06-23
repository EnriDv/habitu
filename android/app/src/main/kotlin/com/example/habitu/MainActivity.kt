package com.example.habitu

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "habitu/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "updateTodaySummary") {
                    val prefs = getSharedPreferences("habitu_widget", Context.MODE_PRIVATE)
                    prefs.edit()
                        .putInt("completedCount", call.argument<Int>("completedCount") ?: 0)
                        .putInt("totalCount", call.argument<Int>("totalCount") ?: 0)
                        .putString("routineId", call.argument<String>("routineId"))
                        .putString("routineTitle", call.argument<String>("routineTitle"))
                        .putString("pendingHabitId", call.argument<String>("pendingHabitId"))
                        .putString("pendingHabitTitle", call.argument<String>("pendingHabitTitle"))
                        .apply()

                    val manager = AppWidgetManager.getInstance(this)
                    val provider = ComponentName(this, HabituTodayWidgetProvider::class.java)
                    val ids = manager.getAppWidgetIds(provider)
                    val updateIntent = Intent(this, HabituTodayWidgetProvider::class.java).apply {
                        action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    }
                    sendBroadcast(updateIntent)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
