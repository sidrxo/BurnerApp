package com.burner.app.data.models;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.DocumentId;
import com.google.firebase.firestore.PropertyName;
import java.util.Date;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0014\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0010\u000e\n\u0002\b\u0004\b\u00c6\u0002\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002R\u000e\u0010\u0003\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0005\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0007\u001a\u00020\u0004X\u0086T\u00a2\u0006\u0002\n\u0000\u00a8\u0006\b"}, d2 = {"Lcom/burner/app/data/models/TicketStatus;", "", "()V", "CANCELLED", "", "CONFIRMED", "REFUNDED", "USED", "app_debug"})
public final class TicketStatus {
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String CONFIRMED = "confirmed";
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String CANCELLED = "cancelled";
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String REFUNDED = "refunded";
    @org.jetbrains.annotations.NotNull()
    public static final java.lang.String USED = "used";
    @org.jetbrains.annotations.NotNull()
    public static final com.burner.app.data.models.TicketStatus INSTANCE = null;
    
    private TicketStatus() {
        super();
    }
}