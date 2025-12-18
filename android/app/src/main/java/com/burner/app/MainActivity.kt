package com.burner.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import com.burner.app.ui.theme.BurnerTheme
import com.burner.app.navigation.BurnerNavHost
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Handle deep links for passwordless auth
        handleDeepLink(intent)

        setContent {
            BurnerTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = BurnerTheme.colors.background
                ) {
                    BurnerNavHost()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Handle deep links when app is already running
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent?) {
        intent?.data?.let { uri ->
            // Supabase automatically handles the auth callback from the deep link
            // The SDK listens for the redirect and completes authentication
            // No manual handling needed - just log for debugging
            android.util.Log.d("MainActivity", "Deep link received: $uri")
        }
    }
}
