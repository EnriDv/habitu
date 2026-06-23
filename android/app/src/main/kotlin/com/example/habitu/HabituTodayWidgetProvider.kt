package com.example.habitu

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.widget.RemoteViews

class HabituTodayWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val prefs = context.getSharedPreferences("habitu_widget", Context.MODE_PRIVATE)
            val completedCount = prefs.getInt("completedCount", 0)
            val totalCount = prefs.getInt("totalCount", 0)
            val routineId = prefs.getString("routineId", null)
            val routineTitle = prefs.getString("routineTitle", null)
            val pendingHabitId = prefs.getString("pendingHabitId", null)
            val pendingHabitTitle = prefs.getString("pendingHabitTitle", null)

            val views = RemoteViews(context.packageName, R.layout.habitu_today_widget)
            views.setTextViewText(R.id.widget_summary, "$completedCount / $totalCount completados")
            views.setTextViewText(
                R.id.widget_routine,
                if (routineTitle.isNullOrBlank()) "Sin rutina activa" else routineTitle
            )
            views.setTextViewText(
                R.id.widget_pending,
                pendingHabitTitle ?: "Abre Habitu para ver tus pendientes"
            )

            views.setOnClickPendingIntent(
                R.id.widget_root,
                deepLinkPendingIntent(
                    context,
                    if (routineId.isNullOrBlank()) "habitu://today" else "habitu://routine/$routineId",
                    10
                )
            )
            views.setOnClickPendingIntent(
                R.id.widget_routine,
                deepLinkPendingIntent(
                    context,
                    if (routineId.isNullOrBlank()) "habitu://today" else "habitu://routine/$routineId",
                    12
                )
            )

            val habitDeepLink = if (pendingHabitId.isNullOrBlank()) "habitu://today" else "habitu://habit/$pendingHabitId"
            views.setOnClickPendingIntent(
                R.id.widget_pending_button,
                deepLinkPendingIntent(context, habitDeepLink, 11)
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun deepLinkPendingIntent(context: Context, deepLink: String, requestCode: Int): PendingIntent {
            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(deepLink), context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, HabituTodayWidgetProvider::class.java))
            ids.forEach { updateWidget(context, manager, it) }
        }
    }
}
