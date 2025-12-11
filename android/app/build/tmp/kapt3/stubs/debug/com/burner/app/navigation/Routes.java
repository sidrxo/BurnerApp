package com.burner.app.navigation;

/**
 * Navigation routes for the Burner app
 * Matching iOS NavigationCoordinator destinations
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0080\u0001\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u001f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\b6\u0018\u0000 \u000b2\u00020\u0001:\u001c\u0007\b\t\n\u000b\f\r\u000e\u000f\u0010\u0011\u0012\u0013\u0014\u0015\u0016\u0017\u0018\u0019\u001a\u001b\u001c\u001d\u001e\u001f !\"B\u000f\b\u0004\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004R\u0011\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0005\u0010\u0006\u0082\u0001\u001b#$%&\'()*+,-./0123456789:;<=\u00a8\u0006>"}, d2 = {"Lcom/burner/app/navigation/Routes;", "", "route", "", "(Ljava/lang/String;)V", "getRoute", "()Ljava/lang/String;", "AccountDetails", "Bookmarks", "BurnerModeLockScreen", "BurnerModeSetup", "Companion", "EventDetail", "Explore", "FAQ", "Main", "NotificationSettings", "Onboarding", "OnboardingComplete", "OnboardingGenres", "OnboardingLocation", "OnboardingNotifications", "OnboardingWelcome", "PaymentSettings", "PrivacyPolicy", "Scanner", "Search", "Settings", "SignIn", "SignUp", "Support", "TermsOfService", "TicketDetail", "TicketPurchase", "Tickets", "Lcom/burner/app/navigation/Routes$AccountDetails;", "Lcom/burner/app/navigation/Routes$Bookmarks;", "Lcom/burner/app/navigation/Routes$BurnerModeLockScreen;", "Lcom/burner/app/navigation/Routes$BurnerModeSetup;", "Lcom/burner/app/navigation/Routes$EventDetail;", "Lcom/burner/app/navigation/Routes$Explore;", "Lcom/burner/app/navigation/Routes$FAQ;", "Lcom/burner/app/navigation/Routes$Main;", "Lcom/burner/app/navigation/Routes$NotificationSettings;", "Lcom/burner/app/navigation/Routes$Onboarding;", "Lcom/burner/app/navigation/Routes$OnboardingComplete;", "Lcom/burner/app/navigation/Routes$OnboardingGenres;", "Lcom/burner/app/navigation/Routes$OnboardingLocation;", "Lcom/burner/app/navigation/Routes$OnboardingNotifications;", "Lcom/burner/app/navigation/Routes$OnboardingWelcome;", "Lcom/burner/app/navigation/Routes$PaymentSettings;", "Lcom/burner/app/navigation/Routes$PrivacyPolicy;", "Lcom/burner/app/navigation/Routes$Scanner;", "Lcom/burner/app/navigation/Routes$Search;", "Lcom/burner/app/navigation/Routes$Settings;", "Lcom/burner/app/navigation/Routes$SignIn;", "Lcom/burner/app/navigation/Routes$SignUp;", "Lcom/burner/app/navigation/Routes$Support;", "Lcom/burner/app/navigation/Routes$TermsOfService;", "Lcom/burner/app/navigation/Routes$TicketDetail;", "Lcom/burner/app/navigation/Routes$TicketPurchase;", "Lcom/burner/app/navigation/Routes$Tickets;", "app_debug"})
public abstract class Routes {
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String route = null;
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String EVENT_ID_KEY = "eventId";
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String TICKET_ID_KEY = "ticketId";
    @org.jetbrains.annotations.NotNull()
    public static final com.burner.app.navigation.Routes.Companion Companion = null;
    
    private Routes(java.lang.String route) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getRoute() {
        return null;
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$AccountDetails;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class AccountDetails extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.AccountDetails INSTANCE = null;
        
        private AccountDetails() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$Bookmarks;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class Bookmarks extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.Bookmarks INSTANCE = null;
        
        private Bookmarks() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$BurnerModeLockScreen;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class BurnerModeLockScreen extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.BurnerModeLockScreen INSTANCE = null;
        
        private BurnerModeLockScreen() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$BurnerModeSetup;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class BurnerModeSetup extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.BurnerModeSetup INSTANCE = null;
        
        private BurnerModeSetup() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\u0006"}, d2 = {"Lcom/burner/app/navigation/Routes$Companion;", "", "()V", "EVENT_ID_KEY", "", "TICKET_ID_KEY", "app_debug"})
    public static final class Companion {
        
        private Companion() {
            super();
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0004\u00a8\u0006\u0006"}, d2 = {"Lcom/burner/app/navigation/Routes$EventDetail;", "Lcom/burner/app/navigation/Routes;", "()V", "createRoute", "", "eventId", "app_debug"})
    public static final class EventDetail extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.EventDetail INSTANCE = null;
        
        private EventDetail() {
        }
        
        @org.jetbrains.annotations.NotNull()
        public final java.lang.String createRoute(@org.jetbrains.annotations.NotNull()
        java.lang.String eventId) {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$Explore;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class Explore extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.Explore INSTANCE = null;
        
        private Explore() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$FAQ;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class FAQ extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.FAQ INSTANCE = null;
        
        private FAQ() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$Main;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class Main extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.Main INSTANCE = null;
        
        private Main() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$NotificationSettings;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class NotificationSettings extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.NotificationSettings INSTANCE = null;
        
        private NotificationSettings() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$Onboarding;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class Onboarding extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.Onboarding INSTANCE = null;
        
        private Onboarding() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$OnboardingComplete;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class OnboardingComplete extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.OnboardingComplete INSTANCE = null;
        
        private OnboardingComplete() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$OnboardingGenres;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class OnboardingGenres extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.OnboardingGenres INSTANCE = null;
        
        private OnboardingGenres() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$OnboardingLocation;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class OnboardingLocation extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.OnboardingLocation INSTANCE = null;
        
        private OnboardingLocation() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$OnboardingNotifications;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class OnboardingNotifications extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.OnboardingNotifications INSTANCE = null;
        
        private OnboardingNotifications() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$OnboardingWelcome;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class OnboardingWelcome extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.OnboardingWelcome INSTANCE = null;
        
        private OnboardingWelcome() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$PaymentSettings;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class PaymentSettings extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.PaymentSettings INSTANCE = null;
        
        private PaymentSettings() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$PrivacyPolicy;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class PrivacyPolicy extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.PrivacyPolicy INSTANCE = null;
        
        private PrivacyPolicy() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$Scanner;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class Scanner extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.Scanner INSTANCE = null;
        
        private Scanner() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$Search;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class Search extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.Search INSTANCE = null;
        
        private Search() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$Settings;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class Settings extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.Settings INSTANCE = null;
        
        private Settings() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$SignIn;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class SignIn extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.SignIn INSTANCE = null;
        
        private SignIn() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$SignUp;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class SignUp extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.SignUp INSTANCE = null;
        
        private SignUp() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$Support;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class Support extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.Support INSTANCE = null;
        
        private Support() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$TermsOfService;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class TermsOfService extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.TermsOfService INSTANCE = null;
        
        private TermsOfService() {
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0004\u00a8\u0006\u0006"}, d2 = {"Lcom/burner/app/navigation/Routes$TicketDetail;", "Lcom/burner/app/navigation/Routes;", "()V", "createRoute", "", "ticketId", "app_debug"})
    public static final class TicketDetail extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.TicketDetail INSTANCE = null;
        
        private TicketDetail() {
        }
        
        @org.jetbrains.annotations.NotNull()
        public final java.lang.String createRoute(@org.jetbrains.annotations.NotNull()
        java.lang.String ticketId) {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u000e\u0010\u0003\u001a\u00020\u00042\u0006\u0010\u0005\u001a\u00020\u0004\u00a8\u0006\u0006"}, d2 = {"Lcom/burner/app/navigation/Routes$TicketPurchase;", "Lcom/burner/app/navigation/Routes;", "()V", "createRoute", "", "eventId", "app_debug"})
    public static final class TicketPurchase extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.TicketPurchase INSTANCE = null;
        
        private TicketPurchase() {
        }
        
        @org.jetbrains.annotations.NotNull()
        public final java.lang.String createRoute(@org.jetbrains.annotations.NotNull()
        java.lang.String eventId) {
            return null;
        }
    }
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0002\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002\u00a8\u0006\u0003"}, d2 = {"Lcom/burner/app/navigation/Routes$Tickets;", "Lcom/burner/app/navigation/Routes;", "()V", "app_debug"})
    public static final class Tickets extends com.burner.app.navigation.Routes {
        @org.jetbrains.annotations.NotNull()
        public static final com.burner.app.navigation.Routes.Tickets INSTANCE = null;
        
        private Tickets() {
        }
    }
}