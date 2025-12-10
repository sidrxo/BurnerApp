package com.burner.app.data.models;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.DocumentId;
import com.google.firebase.firestore.PropertyName;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0005\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\b\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\t"}, d2 = {"Lcom/burner/app/data/models/UserRole;", "", "()V", "SCANNER", "", "SITE_ADMIN", "SUB_ADMIN", "USER", "VENUE_ADMIN", "app_debug"})
public final class UserRole {
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String USER = "user";
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String SCANNER = "scanner";
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String VENUE_ADMIN = "venueAdmin";
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String SUB_ADMIN = "subAdmin";
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String SITE_ADMIN = "siteAdmin";
    @org.jetbrains.annotations.NotNull()
    public static final com.burner.app.data.models.UserRole INSTANCE = null;
    
    private UserRole() {
        super();
    }
}