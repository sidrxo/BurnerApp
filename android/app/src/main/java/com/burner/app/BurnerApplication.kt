package com.burner.app

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import com.stripe.android.PaymentConfiguration
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class BurnerApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Initialize Stripe
        PaymentConfiguration.init(
            applicationContext,
            STRIPE_PUBLISHABLE_KEY
        )

        // Create notification channel
        createNotificationChannel()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Burner Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Event notifications and updates"
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    companion object {
        const val STRIPE_PUBLISHABLE_KEY = "pk_test_51SKOqrFxXnVDuRLXw30ABLXPF9QyorMesOCHN9sMbRAIokEIL8gptsxxX4APRJSO0b8SRGvyAUBNzBZqCCgOSvVI00fxiHOZNe"
        const val NOTIFICATION_CHANNEL_ID = "burner_notifications"
        const val FIREBASE_REGION = "europe-west2"
    }
}
