package com.burner.app.services

import android.content.Context
import android.content.Intent
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInClient
import com.google.android.gms.auth.api.signin.GoogleSignInOptions
import com.google.firebase.Timestamp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.GoogleAuthProvider
import com.google.firebase.firestore.FirebaseFirestore
import com.burner.app.data.models.User
import com.burner.app.data.models.UserPreferences
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.tasks.await
import javax.inject.Inject
import javax.inject.Singleton

sealed class AuthResult {
    data class Success(val user: FirebaseUser) : AuthResult()
    data class Error(val message: String) : AuthResult()
}

@Singleton
class AuthService @Inject constructor(
    private val auth: FirebaseAuth,
    private val firestore: FirebaseFirestore,
    @ApplicationContext private val context: Context
) {
    private var googleSignInClient: GoogleSignInClient? = null

    val currentUser: FirebaseUser?
        get() = auth.currentUser

    val currentUserId: String?
        get() = auth.currentUser?.uid

    fun isAuthenticated(): Boolean = auth.currentUser != null

    val authStateFlow: Flow<FirebaseUser?> = callbackFlow {
        val listener = FirebaseAuth.AuthStateListener { auth ->
            trySend(auth.currentUser)
        }
        auth.addAuthStateListener(listener)
        awaitClose { auth.removeAuthStateListener(listener) }
    }

    // Email/Password Sign Up
    suspend fun signUpWithEmail(email: String, password: String): AuthResult {
        return try {
            val result = auth.createUserWithEmailAndPassword(email, password).await()
            result.user?.let { user ->
                createUserProfile(user, "email")
                AuthResult.Success(user)
            } ?: AuthResult.Error("Failed to create account")
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Sign up failed")
        }
    }

    // Email/Password Sign In
    suspend fun signInWithEmail(email: String, password: String): AuthResult {
        return try {
            val result = auth.signInWithEmailAndPassword(email, password).await()
            result.user?.let { user ->
                updateLastLogin(user.uid)
                AuthResult.Success(user)
            } ?: AuthResult.Error("Failed to sign in")
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Sign in failed")
        }
    }

    // Google Sign In - Initialize
    fun getGoogleSignInIntent(): Intent {
        val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
            .requestIdToken("8577865405-5368q7lnrrjalobo3t99j7mlrv8t3ssm.apps.googleusercontent.com") // Replace with actual Web Client ID
            .requestEmail()
            .build()

        googleSignInClient = GoogleSignIn.getClient(context, gso)
        return googleSignInClient!!.signInIntent
    }

    // Google Sign In - Handle Result
    suspend fun handleGoogleSignInResult(idToken: String): AuthResult {
        return try {
            val credential = GoogleAuthProvider.getCredential(idToken, null)
            val result = auth.signInWithCredential(credential).await()
            result.user?.let { user ->
                val isNewUser = result.additionalUserInfo?.isNewUser == true
                if (isNewUser) {
                    createUserProfile(user, "google")
                } else {
                    updateLastLogin(user.uid)
                }
                AuthResult.Success(user)
            } ?: AuthResult.Error("Failed to sign in with Google")
        } catch (e: Exception) {
            AuthResult.Error(e.message ?: "Google sign in failed")
        }
    }

    // Sign Out
    suspend fun signOut() {
        auth.signOut()
        googleSignInClient?.signOut()?.await()
    }

    // Password Reset
    suspend fun sendPasswordReset(email: String): Result<Unit> {
        return try {
            auth.sendPasswordResetEmail(email).await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Create user profile in Firestore
    private suspend fun createUserProfile(user: FirebaseUser, provider: String) {
        val userDoc = User(
            uid = user.uid,
            email = user.email ?: "",
            displayName = user.displayName,
            provider = provider,
            createdAt = Timestamp.now(),
            lastLoginAt = Timestamp.now(),
            preferences = UserPreferences()
        )

        firestore.collection("users")
            .document(user.uid)
            .set(userDoc)
            .await()
    }

    // Update last login timestamp
    private suspend fun updateLastLogin(userId: String) {
        firestore.collection("users")
            .document(userId)
            .update("lastLoginAt", Timestamp.now())
            .await()
    }

    // Get user profile
    suspend fun getUserProfile(userId: String): User? {
        return try {
            firestore.collection("users")
                .document(userId)
                .get()
                .await()
                .toObject(User::class.java)
        } catch (e: Exception) {
            null
        }
    }

    // Update user profile
    suspend fun updateUserProfile(userId: String, updates: Map<String, Any>): Result<Unit> {
        return try {
            firestore.collection("users")
                .document(userId)
                .update(updates)
                .await()
            Result.success(Unit)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    // Get user role from custom claims (authoritative source)
    suspend fun getUserRole(): String? {
        return try {
            val user = auth.currentUser ?: return null
            val tokenResult = user.getIdToken(false).await()
            tokenResult.claims["role"] as? String
        } catch (e: Exception) {
            null
        }
    }
}
