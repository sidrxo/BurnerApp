package com.burner.app.data.models;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.DocumentId;
import com.google.firebase.firestore.PropertyName;

/**
 * User profile model
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00002\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\b\u0016\n\u0002\u0010\u000b\n\u0002\b\u0002\n\u0002\u0010\b\n\u0002\b\u0002\b\u0086\b\u0018\u00002\u00020\u0001B_\u0012\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0005\u001a\u0004\u0018\u00010\u0003\u0012\b\b\u0002\u0010\u0006\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0007\u001a\u00020\u0003\u0012\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\t\u0012\n\b\u0002\u0010\n\u001a\u0004\u0018\u00010\t\u0012\n\b\u0002\u0010\u000b\u001a\u0004\u0018\u00010\f\u00a2\u0006\u0002\u0010\rJ\u000b\u0010\u0019\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\t\u0010\u001a\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010\u001b\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\t\u0010\u001c\u001a\u00020\u0003H\u00c6\u0003J\t\u0010\u001d\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010\u001e\u001a\u0004\u0018\u00010\tH\u00c6\u0003J\u000b\u0010\u001f\u001a\u0004\u0018\u00010\tH\u00c6\u0003J\u000b\u0010 \u001a\u0004\u0018\u00010\fH\u00c6\u0003Jc\u0010!\u001a\u00020\u00002\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00032\n\b\u0002\u0010\u0005\u001a\u0004\u0018\u00010\u00032\b\b\u0002\u0010\u0006\u001a\u00020\u00032\b\b\u0002\u0010\u0007\u001a\u00020\u00032\n\b\u0002\u0010\b\u001a\u0004\u0018\u00010\t2\n\b\u0002\u0010\n\u001a\u0004\u0018\u00010\t2\n\b\u0002\u0010\u000b\u001a\u0004\u0018\u00010\fH\u00c6\u0001J\u0013\u0010\"\u001a\u00020#2\b\u0010$\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010%\u001a\u00020&H\u00d6\u0001J\t\u0010\'\u001a\u00020\u0003H\u00d6\u0001R\u0018\u0010\b\u001a\u0004\u0018\u00010\t8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u000e\u0010\u000fR\u0018\u0010\u0005\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u0010\u0011R\u0011\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0012\u0010\u0011R\u0018\u0010\n\u001a\u0004\u0018\u00010\t8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0013\u0010\u000fR\u0013\u0010\u000b\u001a\u0004\u0018\u00010\f\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0014\u0010\u0015R\u0011\u0010\u0007\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0016\u0010\u0011R\u0011\u0010\u0006\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0017\u0010\u0011R\u0018\u0010\u0002\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0018\u0010\u0011\u00a8\u0006("}, d2 = {"Lcom/burner/app/data/models/User;", "", "uid", "", "email", "displayName", "role", "provider", "createdAt", "Lcom/google/firebase/Timestamp;", "lastLoginAt", "preferences", "Lcom/burner/app/data/models/UserPreferences;", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/google/firebase/Timestamp;Lcom/google/firebase/Timestamp;Lcom/burner/app/data/models/UserPreferences;)V", "getCreatedAt", "()Lcom/google/firebase/Timestamp;", "getDisplayName", "()Ljava/lang/String;", "getEmail", "getLastLoginAt", "getPreferences", "()Lcom/burner/app/data/models/UserPreferences;", "getProvider", "getRole", "getUid", "component1", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "copy", "equals", "", "other", "hashCode", "", "toString", "app_debug"})
public final class User {
    @com.google.firebase.firestore.DocumentId()
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String uid = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String email = null;
    @com.google.firebase.firestore.PropertyName(value = "displayName")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String displayName = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String role = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String provider = null;
    @com.google.firebase.firestore.PropertyName(value = "createdAt")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp createdAt = null;
    @com.google.firebase.firestore.PropertyName(value = "lastLoginAt")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp lastLoginAt = null;
    @org.jetbrains.annotations.Nullable()
    private final com.burner.app.data.models.UserPreferences preferences = null;
    
    public User(@org.jetbrains.annotations.Nullable()
    java.lang.String uid, @org.jetbrains.annotations.NotNull()
    java.lang.String email, @org.jetbrains.annotations.Nullable()
    java.lang.String displayName, @org.jetbrains.annotations.NotNull()
    java.lang.String role, @org.jetbrains.annotations.NotNull()
    java.lang.String provider, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp createdAt, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp lastLoginAt, @org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.UserPreferences preferences) {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getUid() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getEmail() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getDisplayName() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getRole() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getProvider() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getCreatedAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getLastLoginAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.UserPreferences getPreferences() {
        return null;
    }
    
    public User() {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component1() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component2() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component3() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component5() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component6() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component7() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.burner.app.data.models.UserPreferences component8() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.data.models.User copy(@org.jetbrains.annotations.Nullable()
    java.lang.String uid, @org.jetbrains.annotations.NotNull()
    java.lang.String email, @org.jetbrains.annotations.Nullable()
    java.lang.String displayName, @org.jetbrains.annotations.NotNull()
    java.lang.String role, @org.jetbrains.annotations.NotNull()
    java.lang.String provider, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp createdAt, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp lastLoginAt, @org.jetbrains.annotations.Nullable()
    com.burner.app.data.models.UserPreferences preferences) {
        return null;
    }
    
    @java.lang.Override()
    public boolean equals(@org.jetbrains.annotations.Nullable()
    java.lang.Object other) {
        return false;
    }
    
    @java.lang.Override()
    public int hashCode() {
        return 0;
    }
    
    @java.lang.Override()
    @org.jetbrains.annotations.NotNull()
    public java.lang.String toString() {
        return null;
    }
}