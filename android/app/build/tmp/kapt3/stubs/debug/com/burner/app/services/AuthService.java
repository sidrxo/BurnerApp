package com.burner.app.services;

import android.content.Context;
import android.content.Intent;
import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.firebase.Timestamp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.auth.GoogleAuthProvider;
import com.google.firebase.firestore.FirebaseFirestore;
import com.burner.app.data.models.User;
import com.burner.app.data.models.UserPreferences;
import dagger.hilt.android.qualifiers.ApplicationContext;
import kotlinx.coroutines.flow.Flow;
import javax.inject.Inject;
import javax.inject.Singleton;

@javax.inject.Singleton()
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000l\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\u0006\n\u0002\u0010\u000e\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0002\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u000b\n\u0000\n\u0002\u0018\u0002\n\u0002\b\n\n\u0002\u0010$\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B!\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\b\b\u0001\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ\u001e\u0010\u0017\u001a\u00020\u00182\u0006\u0010\u0019\u001a\u00020\u000b2\u0006\u0010\u001a\u001a\u00020\u0012H\u0082@\u00a2\u0006\u0002\u0010\u001bJ\u0006\u0010\u001c\u001a\u00020\u001dJ\u0018\u0010\u001e\u001a\u0004\u0018\u00010\u001f2\u0006\u0010 \u001a\u00020\u0012H\u0086@\u00a2\u0006\u0002\u0010!J\u0010\u0010\"\u001a\u0004\u0018\u00010\u0012H\u0086@\u00a2\u0006\u0002\u0010#J\u0016\u0010$\u001a\u00020%2\u0006\u0010&\u001a\u00020\u0012H\u0086@\u00a2\u0006\u0002\u0010!J\u0006\u0010\'\u001a\u00020(J$\u0010)\u001a\b\u0012\u0004\u0012\u00020\u00180*2\u0006\u0010+\u001a\u00020\u0012H\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b,\u0010!J\u001e\u0010-\u001a\u00020%2\u0006\u0010+\u001a\u00020\u00122\u0006\u0010.\u001a\u00020\u0012H\u0086@\u00a2\u0006\u0002\u0010/J\u000e\u00100\u001a\u00020\u0018H\u0086@\u00a2\u0006\u0002\u0010#J\u001e\u00101\u001a\u00020%2\u0006\u0010+\u001a\u00020\u00122\u0006\u0010.\u001a\u00020\u0012H\u0086@\u00a2\u0006\u0002\u0010/J\u0016\u00102\u001a\u00020\u00182\u0006\u0010 \u001a\u00020\u0012H\u0082@\u00a2\u0006\u0002\u0010!J8\u00103\u001a\b\u0012\u0004\u0012\u00020\u00180*2\u0006\u0010 \u001a\u00020\u00122\u0012\u00104\u001a\u000e\u0012\u0004\u0012\u00020\u0012\u0012\u0004\u0012\u00020\u000105H\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b6\u00107R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0019\u0010\t\u001a\n\u0012\u0006\u0012\u0004\u0018\u00010\u000b0\n\u00a2\u0006\b\n\u0000\u001a\u0004\b\f\u0010\rR\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0013\u0010\u000e\u001a\u0004\u0018\u00010\u000b8F\u00a2\u0006\u0006\u001a\u0004\b\u000f\u0010\u0010R\u0013\u0010\u0011\u001a\u0004\u0018\u00010\u00128F\u00a2\u0006\u0006\u001a\u0004\b\u0013\u0010\u0014R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0010\u0010\u0015\u001a\u0004\u0018\u00010\u0016X\u0082\u000e\u00a2\u0006\u0002\n\u0000\u0082\u0002\u000b\n\u0002\b!\n\u0005\b\u00a1\u001e0\u0001\u00a8\u00068"}, d2 = {"Lcom/burner/app/services/AuthService;", "", "auth", "Lcom/google/firebase/auth/FirebaseAuth;", "firestore", "Lcom/google/firebase/firestore/FirebaseFirestore;", "context", "Landroid/content/Context;", "(Lcom/google/firebase/auth/FirebaseAuth;Lcom/google/firebase/firestore/FirebaseFirestore;Landroid/content/Context;)V", "authStateFlow", "Lkotlinx/coroutines/flow/Flow;", "Lcom/google/firebase/auth/FirebaseUser;", "getAuthStateFlow", "()Lkotlinx/coroutines/flow/Flow;", "currentUser", "getCurrentUser", "()Lcom/google/firebase/auth/FirebaseUser;", "currentUserId", "", "getCurrentUserId", "()Ljava/lang/String;", "googleSignInClient", "Lcom/google/android/gms/auth/api/signin/GoogleSignInClient;", "createUserProfile", "", "user", "provider", "(Lcom/google/firebase/auth/FirebaseUser;Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getGoogleSignInIntent", "Landroid/content/Intent;", "getUserProfile", "Lcom/burner/app/data/models/User;", "userId", "(Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getUserRole", "(Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "handleGoogleSignInResult", "Lcom/burner/app/services/AuthResult;", "idToken", "isAuthenticated", "", "sendPasswordReset", "Lkotlin/Result;", "email", "sendPasswordReset-gIAlu-s", "signInWithEmail", "password", "(Ljava/lang/String;Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "signOut", "signUpWithEmail", "updateLastLogin", "updateUserProfile", "updates", "", "updateUserProfile-0E7RQCE", "(Ljava/lang/String;Ljava/util/Map;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "app_debug"})
public final class AuthService {
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.auth.FirebaseAuth auth = null;
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.firestore.FirebaseFirestore firestore = null;
    @org.jetbrains.annotations.NotNull()
    private final android.content.Context context = null;
    @org.jetbrains.annotations.Nullable()
    private com.google.android.gms.auth.api.signin.GoogleSignInClient googleSignInClient;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.Flow<com.google.firebase.auth.FirebaseUser> authStateFlow = null;
    
    @javax.inject.Inject()
    public AuthService(@org.jetbrains.annotations.NotNull()
    com.google.firebase.auth.FirebaseAuth auth, @org.jetbrains.annotations.NotNull()
    com.google.firebase.firestore.FirebaseFirestore firestore, @dagger.hilt.android.qualifiers.ApplicationContext()
    @org.jetbrains.annotations.NotNull()
    android.content.Context context) {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.auth.FirebaseUser getCurrentUser() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getCurrentUserId() {
        return null;
    }
    
    public final boolean isAuthenticated() {
        return false;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.Flow<com.google.firebase.auth.FirebaseUser> getAuthStateFlow() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object signUpWithEmail(@org.jetbrains.annotations.NotNull()
    java.lang.String email, @org.jetbrains.annotations.NotNull()
    java.lang.String password, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super com.burner.app.services.AuthResult> $completion) {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object signInWithEmail(@org.jetbrains.annotations.NotNull()
    java.lang.String email, @org.jetbrains.annotations.NotNull()
    java.lang.String password, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super com.burner.app.services.AuthResult> $completion) {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final android.content.Intent getGoogleSignInIntent() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object handleGoogleSignInResult(@org.jetbrains.annotations.NotNull()
    java.lang.String idToken, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super com.burner.app.services.AuthResult> $completion) {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object signOut(@org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    private final java.lang.Object createUserProfile(com.google.firebase.auth.FirebaseUser user, java.lang.String provider, kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    private final java.lang.Object updateLastLogin(java.lang.String userId, kotlin.coroutines.Continuation<? super kotlin.Unit> $completion) {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object getUserProfile(@org.jetbrains.annotations.NotNull()
    java.lang.String userId, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super com.burner.app.data.models.User> $completion) {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object getUserRole(@org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super java.lang.String> $completion) {
        return null;
    }
}