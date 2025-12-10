package com.burner.app.services

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import com.burner.app.BurnerApplication
import com.burner.app.MainActivity
import com.burner.app.R

class BurnerFirebaseMessagingService : FirebaseMessagingService() {

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        // Send token to server for push notifications
        // In a real app, you would save this to Firestore
    }

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        super.onMessageReceived(remoteMessage)

        remoteMessage.notification?.let { notification ->
            showNotification(
                title = notification.title ?: "Burner",
                body = notification.body ?: ""
            )
        }

        // Handle data payload
        remoteMessage.data.let { data ->
            if (data.isNotEmpty()) {
                handleDataMessage(data)
            }
        }
    }

    private fun showNotification(title: String, body: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, BurnerApplication.NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(System.currentTimeMillis().toInt(), notification)
    }

    private fun handleDataMessage(data: Map<String, String>) {
        // Handle different message types
        when (data["type"]) {
            "event_reminder" -> {
                val eventId = data["eventId"]
                val eventName = data["eventName"]
                showNotification(
                    title = "Event Reminder",
                    body = "$eventName starts soon!"
                )
            }
            "ticket_purchased" -> {
                val ticketId = data["ticketId"]
                showNotification(
                    title = "Ticket Confirmed",
                    body = "Your ticket has been confirmed!"
                )
            }
        }
    }
}
