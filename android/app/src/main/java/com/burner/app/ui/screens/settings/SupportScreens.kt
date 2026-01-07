package com.burner.app.ui.screens.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Email
import androidx.compose.material.icons.filled.ExpandMore
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.burner.app.ui.components.*
import com.burner.app.ui.theme.BurnerColors
import com.burner.app.ui.theme.BurnerDimensions
import com.burner.app.ui.theme.BurnerTypography

@Composable
fun SupportScreen(onBackClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        BurnerTopBar(
            title = "SUPPORT",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(BurnerDimensions.paddingScreen)
        ) {
            Text(
                text = "Need help? We're here for you.",
                style = BurnerTypography.sectionHeader,
                color = BurnerColors.White
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))

            Text(
                text = "Contact us and we'll get back to you as soon as possible.",
                style = BurnerTypography.body,
                color = BurnerColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXl))

            PrimaryButton(
                text = "CONTACT SUPPORT",
                onClick = { /* Open email client */ },
                icon = Icons.Filled.Email
            )

            Spacer(modifier = Modifier.height(BurnerDimensions.spacingXxl))

            Text(
                text = "support@burnerapp.com",
                style = BurnerTypography.body,
                color = BurnerColors.TextTertiary
            )
        }
    }
}

@Composable
fun FAQScreen(onBackClick: () -> Unit) {
    val faqs = listOf(
        "How do I purchase tickets?" to "Browse events on the Explore or Search tabs, tap on an event, and click 'Get Tickets' to complete your purchase.",
        "What is Burner Mode?" to "Burner Mode helps you stay present at events by limiting phone distractions. It's an optional feature you can enable before each event.",
        "How do I get a refund?" to "Refund policies vary by event. Contact support or check the event details for specific refund information.",
        "Can I transfer tickets?" to "Ticket transfers are available for most events. Go to your ticket and tap 'Transfer' to send it to a friend.",
        "Why isn't my ticket showing?" to "Make sure you're signed into the account you used for the purchase. If issues persist, contact support.",
        "How do I update my payment method?" to "Go to Settings > Payment Methods to add, remove, or update your saved payment information."
    )

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        BurnerTopBar(
            title = "FAQ",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(BurnerDimensions.paddingScreen)
        ) {
            faqs.forEach { (question, answer) ->
                FAQItem(question = question, answer = answer)
                Spacer(modifier = Modifier.height(BurnerDimensions.spacingSm))
            }
        }
    }
}

@Composable
private fun FAQItem(question: String, answer: String) {
    var expanded by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                BurnerColors.CardBackground,
                shape = RoundedCornerShape(BurnerDimensions.radiusMd)
            )
            .clickable { expanded = !expanded }
            .padding(BurnerDimensions.spacingLg)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Text(
                text = question,
                style = BurnerTypography.body,
                color = BurnerColors.White,
                modifier = Modifier.weight(1f)
            )
            Icon(
                imageVector = Icons.Filled.ExpandMore,
                contentDescription = if (expanded) "Collapse" else "Expand",
                tint = BurnerColors.TextSecondary,
                modifier = Modifier.size(24.dp)
            )
        }

        if (expanded) {
            Spacer(modifier = Modifier.height(BurnerDimensions.spacingMd))
            Text(
                text = answer,
                style = BurnerTypography.secondary,
                color = BurnerColors.TextTertiary
            )
        }
    }
}

@Composable
fun TermsOfServiceScreen(onBackClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        BurnerTopBar(
            title = "TERMS OF SERVICE",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(BurnerDimensions.paddingScreen)
        ) {
            Text(
                text = """
                    TERMS OF SERVICE

                    Last updated: December 2024

                    Welcome to Burner. By using our app, you agree to these terms.

                    1. USE OF SERVICE
                    Burner provides a platform for discovering and purchasing event tickets. You must be at least 18 years old to use this service.

                    2. ACCOUNT
                    You are responsible for maintaining the security of your account. Do not share your login credentials.

                    3. PURCHASES
                    All ticket purchases are subject to availability. Prices are displayed in GBP and include all applicable fees.

                    4. REFUNDS
                    Refund policies are determined by individual event organizers. Contact support for assistance with refunds.

                    5. BURNER MODE
                    Burner Mode is an optional feature. We are not responsible for any missed notifications while this feature is active.

                    6. PRIVACY
                    Your privacy is important to us. Please review our Privacy Policy for details on how we collect and use your data.

                    7. CHANGES
                    We may update these terms from time to time. Continued use of the app constitutes acceptance of updated terms.

                    8. CONTACT
                    For questions about these terms, contact support@burnerapp.com
                """.trimIndent(),
                style = BurnerTypography.secondary,
                color = BurnerColors.TextTertiary
            )
        }
    }
}

@Composable
fun PrivacyPolicyScreen(onBackClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(BurnerColors.Background)
    ) {
        BurnerTopBar(
            title = "PRIVACY POLICY",
            onBackClick = onBackClick
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(BurnerDimensions.paddingScreen)
        ) {
            Text(
                text = """
                    PRIVACY POLICY

                    Last updated: December 2024

                    1. INFORMATION WE COLLECT
                    - Account information (email, name)
                    - Payment information (processed securely by Stripe)
                    - Location data (with your permission)
                    - Usage data and preferences

                    2. HOW WE USE YOUR DATA
                    - To provide and improve our services
                    - To process transactions
                    - To send relevant notifications
                    - To personalize your experience

                    3. DATA SHARING
                    We do not sell your personal data. We may share data with:
                    - Event organizers (for ticket purchases)
                    - Payment processors (Stripe)
                    - Service providers (hosting, analytics)

                    4. DATA SECURITY
                    We use industry-standard security measures to protect your data.

                    5. YOUR RIGHTS
                    You have the right to:
                    - Access your data
                    - Request deletion
                    - Opt out of marketing
                    - Export your data

                    6. COOKIES
                    We use cookies and similar technologies to improve your experience.

                    7. CHILDREN
                    Our service is not intended for users under 18.

                    8. CONTACT
                    For privacy concerns, contact privacy@burnerapp.com
                """.trimIndent(),
                style = BurnerTypography.secondary,
                color = BurnerColors.TextTertiary
            )
        }
    }
}
