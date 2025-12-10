package com.burner.app.data.models;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.DocumentId;
import com.google.firebase.firestore.PropertyName;
import java.util.Date;

/**
 * Ticket model matching iOS Ticket struct
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00008\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0006\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0006\n\u0002\b\u0015\n\u0002\u0010\u000b\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\b+\n\u0002\u0010\b\n\u0002\b\u0003\b\u0086\b\u0018\u0000 V2\u00020\u0001:\u0001VB\u00e9\u0001\u0012\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u0003\u0012\b\b\u0002\u0010\u0007\u001a\u00020\u0003\u0012\b\b\u0002\u0010\b\u001a\u00020\u0003\u0012\n\b\u0002\u0010\t\u001a\u0004\u0018\u00010\n\u0012\b\b\u0002\u0010\u000b\u001a\u00020\f\u0012\n\b\u0002\u0010\r\u001a\u0004\u0018\u00010\n\u0012\b\b\u0002\u0010\u000e\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u000f\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0002\u0010\u0010\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0002\u0010\u0011\u001a\u0004\u0018\u00010\n\u0012\n\b\u0002\u0010\u0012\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0002\u0010\u0013\u001a\u0004\u0018\u00010\n\u0012\n\b\u0002\u0010\u0014\u001a\u0004\u0018\u00010\n\u0012\n\b\u0002\u0010\u0015\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0002\u0010\u0016\u001a\u0004\u0018\u00010\n\u0012\n\b\u0002\u0010\u0017\u001a\u0004\u0018\u00010\n\u0012\n\b\u0002\u0010\u0018\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\u0002\u0010\u0019J\u000b\u0010<\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\t\u0010=\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010>\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010?\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010@\u001a\u0004\u0018\u00010\nH\u00c6\u0003J\u000b\u0010A\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010B\u001a\u0004\u0018\u00010\nH\u00c6\u0003J\u000b\u0010C\u001a\u0004\u0018\u00010\nH\u00c6\u0003J\u000b\u0010D\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010E\u001a\u0004\u0018\u00010\nH\u00c6\u0003J\u000b\u0010F\u001a\u0004\u0018\u00010\nH\u00c6\u0003J\t\u0010G\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010H\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\t\u0010I\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010J\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\t\u0010K\u001a\u00020\u0003H\u00c6\u0003J\t\u0010L\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010M\u001a\u0004\u0018\u00010\nH\u00c6\u0003J\t\u0010N\u001a\u00020\fH\u00c6\u0003J\u000b\u0010O\u001a\u0004\u0018\u00010\nH\u00c6\u0003J\u00ed\u0001\u0010P\u001a\u00020\u00002\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00032\b\b\u0002\u0010\u0005\u001a\u00020\u00032\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u00032\b\b\u0002\u0010\u0007\u001a\u00020\u00032\b\b\u0002\u0010\b\u001a\u00020\u00032\n\b\u0002\u0010\t\u001a\u0004\u0018\u00010\n2\b\b\u0002\u0010\u000b\u001a\u00020\f2\n\b\u0002\u0010\r\u001a\u0004\u0018\u00010\n2\b\b\u0002\u0010\u000e\u001a\u00020\u00032\n\b\u0002\u0010\u000f\u001a\u0004\u0018\u00010\u00032\n\b\u0002\u0010\u0010\u001a\u0004\u0018\u00010\u00032\n\b\u0002\u0010\u0011\u001a\u0004\u0018\u00010\n2\n\b\u0002\u0010\u0012\u001a\u0004\u0018\u00010\u00032\n\b\u0002\u0010\u0013\u001a\u0004\u0018\u00010\n2\n\b\u0002\u0010\u0014\u001a\u0004\u0018\u00010\n2\n\b\u0002\u0010\u0015\u001a\u0004\u0018\u00010\u00032\n\b\u0002\u0010\u0016\u001a\u0004\u0018\u00010\n2\n\b\u0002\u0010\u0017\u001a\u0004\u0018\u00010\n2\n\b\u0002\u0010\u0018\u001a\u0004\u0018\u00010\u0003H\u00c6\u0001J\u0013\u0010Q\u001a\u00020\"2\b\u0010R\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010S\u001a\u00020TH\u00d6\u0001J\t\u0010U\u001a\u00020\u0003H\u00d6\u0001R\u0018\u0010\u0013\u001a\u0004\u0018\u00010\n8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001a\u0010\u001bR\u0016\u0010\u0004\u001a\u00020\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001c\u0010\u001dR\u0018\u0010\u0018\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001e\u0010\u001dR\u0016\u0010\u0007\u001a\u00020\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u001f\u0010\u001dR\u0018\u0010\u0002\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b \u0010\u001dR\u0011\u0010!\u001a\u00020\"8F\u00a2\u0006\u0006\u001a\u0004\b!\u0010#R\u0011\u0010$\u001a\u00020\"8F\u00a2\u0006\u0006\u001a\u0004\b$\u0010#R\u0011\u0010%\u001a\u00020\"8F\u00a2\u0006\u0006\u001a\u0004\b%\u0010#R\u0018\u0010\r\u001a\u0004\u0018\u00010\n8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b&\u0010\u001bR\u0013\u0010\'\u001a\u0004\u0018\u00010(8F\u00a2\u0006\u0006\u001a\u0004\b)\u0010*R\u0018\u0010\u000f\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b+\u0010\u001dR\u0018\u0010\u0014\u001a\u0004\u0018\u00010\n8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b,\u0010\u001bR\u0018\u0010\u0012\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b-\u0010\u001dR\u0013\u0010.\u001a\u0004\u0018\u00010(8F\u00a2\u0006\u0006\u001a\u0004\b/\u0010*R\u0018\u0010\t\u001a\u0004\u0018\u00010\n8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b0\u0010\u001bR\u0011\u0010\u000e\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b1\u0010\u001dR\u0018\u0010\u0006\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b2\u0010\u001dR\u0016\u0010\u000b\u001a\u00020\f8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b3\u00104R\u0018\u0010\u0016\u001a\u0004\u0018\u00010\n8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b5\u0010\u001bR\u0018\u0010\u0015\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b6\u0010\u001dR\u0018\u0010\u0017\u001a\u0004\u0018\u00010\n8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b7\u0010\u001bR\u0018\u0010\u0011\u001a\u0004\u0018\u00010\n8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b8\u0010\u001bR\u0016\u0010\u0005\u001a\u00020\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b9\u0010\u001dR\u0011\u0010\b\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b:\u0010\u001dR\u0018\u0010\u0010\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b;\u0010\u001d\u00a8\u0006W"}, d2 = {"Lcom/burner/app/data/models/Ticket;", "", "id", "", "eventId", "userId", "ticketNumber", "eventName", "venue", "startTime", "Lcom/google/firebase/Timestamp;", "totalPrice", "", "purchaseDate", "status", "qrCode", "venueId", "usedAt", "scannedBy", "cancelledAt", "refundedAt", "transferredFrom", "transferredAt", "updatedAt", "eventImageUrl", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/google/firebase/Timestamp;DLcom/google/firebase/Timestamp;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/google/firebase/Timestamp;Ljava/lang/String;Lcom/google/firebase/Timestamp;Lcom/google/firebase/Timestamp;Ljava/lang/String;Lcom/google/firebase/Timestamp;Lcom/google/firebase/Timestamp;Ljava/lang/String;)V", "getCancelledAt", "()Lcom/google/firebase/Timestamp;", "getEventId", "()Ljava/lang/String;", "getEventImageUrl", "getEventName", "getId", "isActive", "", "()Z", "isPast", "isUpcoming", "getPurchaseDate", "purchaseDateValue", "Ljava/util/Date;", "getPurchaseDateValue", "()Ljava/util/Date;", "getQrCode", "getRefundedAt", "getScannedBy", "startDate", "getStartDate", "getStartTime", "getStatus", "getTicketNumber", "getTotalPrice", "()D", "getTransferredAt", "getTransferredFrom", "getUpdatedAt", "getUsedAt", "getUserId", "getVenue", "getVenueId", "component1", "component10", "component11", "component12", "component13", "component14", "component15", "component16", "component17", "component18", "component19", "component2", "component20", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "equals", "other", "hashCode", "", "toString", "Companion", "app_debug"})
public final class Ticket {
    @com.google.firebase.firestore.DocumentId()
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String id = null;
    @com.google.firebase.firestore.PropertyName(value = "eventId")
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String eventId = null;
    @com.google.firebase.firestore.PropertyName(value = "userId")
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String userId = null;
    @com.google.firebase.firestore.PropertyName(value = "ticketNumber")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String ticketNumber = null;
    @com.google.firebase.firestore.PropertyName(value = "eventName")
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String eventName = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String venue = null;
    @com.google.firebase.firestore.PropertyName(value = "startTime")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp startTime = null;
    @com.google.firebase.firestore.PropertyName(value = "totalPrice")
    private final double totalPrice = 0.0;
    @com.google.firebase.firestore.PropertyName(value = "purchaseDate")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp purchaseDate = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String status = null;
    @com.google.firebase.firestore.PropertyName(value = "qrCode")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String qrCode = null;
    @com.google.firebase.firestore.PropertyName(value = "venueId")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String venueId = null;
    @com.google.firebase.firestore.PropertyName(value = "usedAt")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp usedAt = null;
    @com.google.firebase.firestore.PropertyName(value = "scannedBy")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String scannedBy = null;
    @com.google.firebase.firestore.PropertyName(value = "cancelledAt")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp cancelledAt = null;
    @com.google.firebase.firestore.PropertyName(value = "refundedAt")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp refundedAt = null;
    @com.google.firebase.firestore.PropertyName(value = "transferredFrom")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String transferredFrom = null;
    @com.google.firebase.firestore.PropertyName(value = "transferredAt")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp transferredAt = null;
    @com.google.firebase.firestore.PropertyName(value = "updatedAt")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp updatedAt = null;
    @com.google.firebase.firestore.PropertyName(value = "eventImageUrl")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String eventImageUrl = null;
    @org.jetbrains.annotations.NotNull()
    public static final com.burner.app.data.models.Ticket.Companion Companion = null;
    
    public Ticket(@org.jetbrains.annotations.Nullable()
    java.lang.String id, @org.jetbrains.annotations.NotNull()
    java.lang.String eventId, @org.jetbrains.annotations.NotNull()
    java.lang.String userId, @org.jetbrains.annotations.Nullable()
    java.lang.String ticketNumber, @org.jetbrains.annotations.NotNull()
    java.lang.String eventName, @org.jetbrains.annotations.NotNull()
    java.lang.String venue, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp startTime, double totalPrice, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp purchaseDate, @org.jetbrains.annotations.NotNull()
    java.lang.String status, @org.jetbrains.annotations.Nullable()
    java.lang.String qrCode, @org.jetbrains.annotations.Nullable()
    java.lang.String venueId, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp usedAt, @org.jetbrains.annotations.Nullable()
    java.lang.String scannedBy, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp cancelledAt, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp refundedAt, @org.jetbrains.annotations.Nullable()
    java.lang.String transferredFrom, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp transferredAt, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp updatedAt, @org.jetbrains.annotations.Nullable()
    java.lang.String eventImageUrl) {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getId() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getEventId() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getUserId() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getTicketNumber() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getEventName() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getVenue() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getStartTime() {
        return null;
    }
    
    public final double getTotalPrice() {
        return 0.0;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getPurchaseDate() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getStatus() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getQrCode() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getVenueId() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getUsedAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getScannedBy() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getCancelledAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getRefundedAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getTransferredFrom() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getTransferredAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getUpdatedAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getEventImageUrl() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.util.Date getStartDate() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.util.Date getPurchaseDateValue() {
        return null;
    }
    
    public final boolean isUpcoming() {
        return false;
    }
    
    public final boolean isPast() {
        return false;
    }
    
    public final boolean isActive() {
        return false;
    }
    
    public Ticket() {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component1() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component10() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component11() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component12() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component13() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component14() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component15() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component16() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component17() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component18() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component19() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component2() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component20() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component3() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component4() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component5() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component6() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component7() {
        return null;
    }
    
    public final double component8() {
        return 0.0;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component9() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.data.models.Ticket copy(@org.jetbrains.annotations.Nullable()
    java.lang.String id, @org.jetbrains.annotations.NotNull()
    java.lang.String eventId, @org.jetbrains.annotations.NotNull()
    java.lang.String userId, @org.jetbrains.annotations.Nullable()
    java.lang.String ticketNumber, @org.jetbrains.annotations.NotNull()
    java.lang.String eventName, @org.jetbrains.annotations.NotNull()
    java.lang.String venue, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp startTime, double totalPrice, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp purchaseDate, @org.jetbrains.annotations.NotNull()
    java.lang.String status, @org.jetbrains.annotations.Nullable()
    java.lang.String qrCode, @org.jetbrains.annotations.Nullable()
    java.lang.String venueId, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp usedAt, @org.jetbrains.annotations.Nullable()
    java.lang.String scannedBy, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp cancelledAt, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp refundedAt, @org.jetbrains.annotations.Nullable()
    java.lang.String transferredFrom, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp transferredAt, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp updatedAt, @org.jetbrains.annotations.Nullable()
    java.lang.String eventImageUrl) {
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
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0006\u0010\u0003\u001a\u00020\u0004\u00a8\u0006\u0005"}, d2 = {"Lcom/burner/app/data/models/Ticket$Companion;", "", "()V", "empty", "Lcom/burner/app/data/models/Ticket;", "app_debug"})
    public static final class Companion {
        
        private Companion() {
            super();
        }
        
        @org.jetbrains.annotations.NotNull()
        public final com.burner.app.data.models.Ticket empty() {
            return null;
        }
    }
}