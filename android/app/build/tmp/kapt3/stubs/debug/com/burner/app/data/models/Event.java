package com.burner.app.data.models;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.DocumentId;
import com.google.firebase.firestore.Exclude;
import com.google.firebase.firestore.GeoPoint;
import com.google.firebase.firestore.PropertyName;
import java.util.Calendar;
import java.util.Date;

/**
 * Event model matching iOS Event struct
 */
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000T\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0010\u000e\n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010\u0006\n\u0000\n\u0002\u0010\b\n\u0002\b\u0003\n\u0002\u0010\u000b\n\u0002\b\u0003\n\u0002\u0010 \n\u0002\b\u0004\n\u0002\u0018\u0002\n\u0002\b\u0005\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0002\b\n\n\u0002\u0018\u0002\n\u0002\b:\b\u0086\b\u0018\u0000 e2\u00020\u0001:\u0001eB\u00bd\u0001\u0012\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u0003\u0012\b\b\u0002\u0010\u0004\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0005\u001a\u00020\u0003\u0012\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0002\u0010\u0007\u001a\u0004\u0018\u00010\b\u0012\n\b\u0002\u0010\t\u001a\u0004\u0018\u00010\b\u0012\b\b\u0002\u0010\n\u001a\u00020\u000b\u0012\b\b\u0002\u0010\f\u001a\u00020\r\u0012\b\b\u0002\u0010\u000e\u001a\u00020\r\u0012\b\b\u0002\u0010\u000f\u001a\u00020\u0003\u0012\b\b\u0002\u0010\u0010\u001a\u00020\u0011\u0012\n\b\u0002\u0010\u0012\u001a\u0004\u0018\u00010\u0003\u0012\n\b\u0002\u0010\u0013\u001a\u0004\u0018\u00010\u0003\u0012\u0010\b\u0002\u0010\u0014\u001a\n\u0012\u0004\u0012\u00020\u0003\u0018\u00010\u0015\u0012\n\b\u0002\u0010\u0016\u001a\u0004\u0018\u00010\b\u0012\n\b\u0002\u0010\u0017\u001a\u0004\u0018\u00010\b\u00a2\u0006\u0002\u0010\u0018J\u000b\u0010G\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\t\u0010H\u001a\u00020\u0003H\u00c6\u0003J\t\u0010I\u001a\u00020\u0011H\u00c6\u0003J\u000b\u0010J\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010K\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u0011\u0010L\u001a\n\u0012\u0004\u0012\u00020\u0003\u0018\u00010\u0015H\u00c6\u0003J\u000b\u0010M\u001a\u0004\u0018\u00010\bH\u00c6\u0003J\u000b\u0010N\u001a\u0004\u0018\u00010\bH\u00c6\u0003J\t\u0010O\u001a\u00020\u0003H\u00c6\u0003J\t\u0010P\u001a\u00020\u0003H\u00c6\u0003J\u000b\u0010Q\u001a\u0004\u0018\u00010\u0003H\u00c6\u0003J\u000b\u0010R\u001a\u0004\u0018\u00010\bH\u00c6\u0003J\u000b\u0010S\u001a\u0004\u0018\u00010\bH\u00c6\u0003J\t\u0010T\u001a\u00020\u000bH\u00c6\u0003J\t\u0010U\u001a\u00020\rH\u00c6\u0003J\t\u0010V\u001a\u00020\rH\u00c6\u0003J\u00c1\u0001\u0010W\u001a\u00020\u00002\n\b\u0002\u0010\u0002\u001a\u0004\u0018\u00010\u00032\b\b\u0002\u0010\u0004\u001a\u00020\u00032\b\b\u0002\u0010\u0005\u001a\u00020\u00032\n\b\u0002\u0010\u0006\u001a\u0004\u0018\u00010\u00032\n\b\u0002\u0010\u0007\u001a\u0004\u0018\u00010\b2\n\b\u0002\u0010\t\u001a\u0004\u0018\u00010\b2\b\b\u0002\u0010\n\u001a\u00020\u000b2\b\b\u0002\u0010\f\u001a\u00020\r2\b\b\u0002\u0010\u000e\u001a\u00020\r2\b\b\u0002\u0010\u000f\u001a\u00020\u00032\b\b\u0002\u0010\u0010\u001a\u00020\u00112\n\b\u0002\u0010\u0012\u001a\u0004\u0018\u00010\u00032\n\b\u0002\u0010\u0013\u001a\u0004\u0018\u00010\u00032\u0010\b\u0002\u0010\u0014\u001a\n\u0012\u0004\u0012\u00020\u0003\u0018\u00010\u00152\n\b\u0002\u0010\u0016\u001a\u0004\u0018\u00010\b2\n\b\u0002\u0010\u0017\u001a\u0004\u0018\u00010\bH\u00c6\u0001J\u001d\u0010X\u001a\u0004\u0018\u00010\u000b2\u0006\u0010Y\u001a\u00020\u000b2\u0006\u0010Z\u001a\u00020\u000b\u00a2\u0006\u0002\u0010[J\u0013\u0010\\\u001a\u00020\u00112\b\u0010]\u001a\u0004\u0018\u00010\u0001H\u00d6\u0003J\t\u0010^\u001a\u00020\rH\u00d6\u0001J(\u0010_\u001a\u00020\u000b2\u0006\u0010`\u001a\u00020\u000b2\u0006\u0010a\u001a\u00020\u000b2\u0006\u0010b\u001a\u00020\u000b2\u0006\u0010c\u001a\u00020\u000bH\u0002J\t\u0010d\u001a\u00020\u0003H\u00d6\u0001R\u001e\u0010\u0019\u001a\u0004\u0018\u00010\u001a8GX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b\u001b\u0010\u001c\"\u0004\b\u001d\u0010\u001eRd\u0010\"\u001a\"\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u0001\u0018\u00010 j\u0010\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u0001\u0018\u0001`!2&\u0010\u001f\u001a\"\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u0001\u0018\u00010 j\u0010\u0012\u0004\u0012\u00020\u0003\u0012\u0004\u0012\u00020\u0001\u0018\u0001`!@GX\u0086\u000e\u00a2\u0006\u000e\n\u0000\u001a\u0004\b#\u0010$\"\u0004\b%\u0010&R\u0018\u0010\u0016\u001a\u0004\u0018\u00010\b8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\'\u0010(R\u0013\u0010\u0012\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b)\u0010*R\u0013\u0010+\u001a\u0004\u0018\u00010,8F\u00a2\u0006\u0006\u001a\u0004\b-\u0010.R\u0018\u0010\t\u001a\u0004\u0018\u00010\b8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b/\u0010(R\u0018\u0010\u0002\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b0\u0010*R\u0016\u0010\u000f\u001a\u00020\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b1\u0010*R\u0011\u00102\u001a\u00020\u00118F\u00a2\u0006\u0006\u001a\u0004\b2\u00103R\u0016\u0010\u0010\u001a\u00020\u00118\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b\u0010\u00103R\u0011\u00104\u001a\u00020\u00118F\u00a2\u0006\u0006\u001a\u0004\b4\u00103R\u0011\u00105\u001a\u00020\u00118F\u00a2\u0006\u0006\u001a\u0004\b5\u00103R\u0016\u0010\f\u001a\u00020\r8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b6\u00107R\u0011\u0010\u0004\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b8\u0010*R\u0011\u0010\n\u001a\u00020\u000b\u00a2\u0006\b\n\u0000\u001a\u0004\b9\u0010:R\u0013\u0010;\u001a\u0004\u0018\u00010,8F\u00a2\u0006\u0006\u001a\u0004\b<\u0010.R\u0018\u0010\u0007\u001a\u0004\u0018\u00010\b8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\b=\u0010(R\u0013\u0010\u0013\u001a\u0004\u0018\u00010\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\b>\u0010*R\u0019\u0010\u0014\u001a\n\u0012\u0004\u0012\u00020\u0003\u0018\u00010\u0015\u00a2\u0006\b\n\u0000\u001a\u0004\b?\u0010@R\u0011\u0010A\u001a\u00020\r8F\u00a2\u0006\u0006\u001a\u0004\bB\u00107R\u0016\u0010\u000e\u001a\u00020\r8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\bC\u00107R\u0018\u0010\u0017\u001a\u0004\u0018\u00010\b8\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\bD\u0010(R\u0011\u0010\u0005\u001a\u00020\u0003\u00a2\u0006\b\n\u0000\u001a\u0004\bE\u0010*R\u0018\u0010\u0006\u001a\u0004\u0018\u00010\u00038\u0006X\u0087\u0004\u00a2\u0006\b\n\u0000\u001a\u0004\bF\u0010*\u00a8\u0006f"}, d2 = {"Lcom/burner/app/data/models/Event;", "", "id", "", "name", "venue", "venueId", "startTime", "Lcom/google/firebase/Timestamp;", "endTime", "price", "", "maxTickets", "", "ticketsSold", "imageUrl", "isFeatured", "", "description", "status", "tags", "", "createdAt", "updatedAt", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/google/firebase/Timestamp;Lcom/google/firebase/Timestamp;DIILjava/lang/String;ZLjava/lang/String;Ljava/lang/String;Ljava/util/List;Lcom/google/firebase/Timestamp;Lcom/google/firebase/Timestamp;)V", "coordinates", "Lcom/google/firebase/firestore/GeoPoint;", "getCoordinates", "()Lcom/google/firebase/firestore/GeoPoint;", "setCoordinates", "(Lcom/google/firebase/firestore/GeoPoint;)V", "value", "Ljava/util/HashMap;", "Lkotlin/collections/HashMap;", "coordinatesMap", "getCoordinatesMap", "()Ljava/util/HashMap;", "setCoordinatesMap", "(Ljava/util/HashMap;)V", "getCreatedAt", "()Lcom/google/firebase/Timestamp;", "getDescription", "()Ljava/lang/String;", "endDate", "Ljava/util/Date;", "getEndDate", "()Ljava/util/Date;", "getEndTime", "getId", "getImageUrl", "isAvailable", "()Z", "isPast", "isSoldOut", "getMaxTickets", "()I", "getName", "getPrice", "()D", "startDate", "getStartDate", "getStartTime", "getStatus", "getTags", "()Ljava/util/List;", "ticketsRemaining", "getTicketsRemaining", "getTicketsSold", "getUpdatedAt", "getVenue", "getVenueId", "component1", "component10", "component11", "component12", "component13", "component14", "component15", "component16", "component2", "component3", "component4", "component5", "component6", "component7", "component8", "component9", "copy", "distanceFrom", "latitude", "longitude", "(DD)Ljava/lang/Double;", "equals", "other", "hashCode", "haversineDistance", "lat1", "lon1", "lat2", "lon2", "toString", "Companion", "app_debug"})
public final class Event {
    @com.google.firebase.firestore.DocumentId()
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String id = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String name = null;
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String venue = null;
    @com.google.firebase.firestore.PropertyName(value = "venueId")
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String venueId = null;
    @com.google.firebase.firestore.PropertyName(value = "startTime")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp startTime = null;
    @com.google.firebase.firestore.PropertyName(value = "endTime")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp endTime = null;
    private final double price = 0.0;
    @com.google.firebase.firestore.PropertyName(value = "maxTickets")
    private final int maxTickets = 0;
    @com.google.firebase.firestore.PropertyName(value = "ticketsSold")
    private final int ticketsSold = 0;
    @com.google.firebase.firestore.PropertyName(value = "imageUrl")
    @org.jetbrains.annotations.NotNull()
    private final java.lang.String imageUrl = null;
    @com.google.firebase.firestore.PropertyName(value = "isFeatured")
    private final boolean isFeatured = false;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String description = null;
    @org.jetbrains.annotations.Nullable()
    private final java.lang.String status = null;
    @org.jetbrains.annotations.Nullable()
    private final java.util.List<java.lang.String> tags = null;
    @com.google.firebase.firestore.PropertyName(value = "createdAt")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp createdAt = null;
    @com.google.firebase.firestore.PropertyName(value = "updatedAt")
    @org.jetbrains.annotations.Nullable()
    private final com.google.firebase.Timestamp updatedAt = null;
    @org.jetbrains.annotations.Nullable()
    private com.google.firebase.firestore.GeoPoint coordinates;
    @org.jetbrains.annotations.Nullable()
    private java.util.HashMap<java.lang.String, java.lang.Object> coordinatesMap;
    @org.jetbrains.annotations.NotNull()
    public static final com.burner.app.data.models.Event.Companion Companion = null;
    
    public Event(@org.jetbrains.annotations.Nullable()
    java.lang.String id, @org.jetbrains.annotations.NotNull()
    java.lang.String name, @org.jetbrains.annotations.NotNull()
    java.lang.String venue, @org.jetbrains.annotations.Nullable()
    java.lang.String venueId, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp startTime, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp endTime, double price, int maxTickets, int ticketsSold, @org.jetbrains.annotations.NotNull()
    java.lang.String imageUrl, boolean isFeatured, @org.jetbrains.annotations.Nullable()
    java.lang.String description, @org.jetbrains.annotations.Nullable()
    java.lang.String status, @org.jetbrains.annotations.Nullable()
    java.util.List<java.lang.String> tags, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp createdAt, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp updatedAt) {
        super();
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getId() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getName() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getVenue() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getVenueId() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getStartTime() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getEndTime() {
        return null;
    }
    
    public final double getPrice() {
        return 0.0;
    }
    
    public final int getMaxTickets() {
        return 0;
    }
    
    public final int getTicketsSold() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String getImageUrl() {
        return null;
    }
    
    public final boolean isFeatured() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getDescription() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String getStatus() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.util.List<java.lang.String> getTags() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getCreatedAt() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp getUpdatedAt() {
        return null;
    }
    
    @com.google.firebase.firestore.Exclude()
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.firestore.GeoPoint getCoordinates() {
        return null;
    }
    
    public final void setCoordinates(@org.jetbrains.annotations.Nullable()
    com.google.firebase.firestore.GeoPoint p0) {
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.util.HashMap<java.lang.String, java.lang.Object> getCoordinatesMap() {
        return null;
    }
    
    @com.google.firebase.firestore.PropertyName(value = "coordinates")
    public final void setCoordinatesMap(@org.jetbrains.annotations.Nullable()
    java.util.HashMap<java.lang.String, java.lang.Object> value) {
    }
    
    public final boolean isAvailable() {
        return false;
    }
    
    public final boolean isSoldOut() {
        return false;
    }
    
    public final int getTicketsRemaining() {
        return 0;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.util.Date getStartDate() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.util.Date getEndDate() {
        return null;
    }
    
    public final boolean isPast() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Double distanceFrom(double latitude, double longitude) {
        return null;
    }
    
    private final double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
        return 0.0;
    }
    
    public Event() {
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
    
    public final boolean component11() {
        return false;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component12() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.String component13() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.util.List<java.lang.String> component14() {
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
    
    @org.jetbrains.annotations.NotNull()
    public final java.lang.String component2() {
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
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component5() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final com.google.firebase.Timestamp component6() {
        return null;
    }
    
    public final double component7() {
        return 0.0;
    }
    
    public final int component8() {
        return 0;
    }
    
    public final int component9() {
        return 0;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final com.burner.app.data.models.Event copy(@org.jetbrains.annotations.Nullable()
    java.lang.String id, @org.jetbrains.annotations.NotNull()
    java.lang.String name, @org.jetbrains.annotations.NotNull()
    java.lang.String venue, @org.jetbrains.annotations.Nullable()
    java.lang.String venueId, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp startTime, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp endTime, double price, int maxTickets, int ticketsSold, @org.jetbrains.annotations.NotNull()
    java.lang.String imageUrl, boolean isFeatured, @org.jetbrains.annotations.Nullable()
    java.lang.String description, @org.jetbrains.annotations.Nullable()
    java.lang.String status, @org.jetbrains.annotations.Nullable()
    java.util.List<java.lang.String> tags, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp createdAt, @org.jetbrains.annotations.Nullable()
    com.google.firebase.Timestamp updatedAt) {
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
    
    @kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\u0012\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\b\u0086\u0003\u0018\u00002\u00020\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002J\u0006\u0010\u0003\u001a\u00020\u0004\u00a8\u0006\u0005"}, d2 = {"Lcom/burner/app/data/models/Event$Companion;", "", "()V", "empty", "Lcom/burner/app/data/models/Event;", "app_debug"})
    public static final class Companion {
        
        private Companion() {
            super();
        }
        
        @org.jetbrains.annotations.NotNull()
        public final com.burner.app.data.models.Event empty() {
            return null;
        }
    }
}