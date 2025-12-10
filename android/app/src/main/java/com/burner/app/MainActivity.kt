package com.burner.app

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
}
