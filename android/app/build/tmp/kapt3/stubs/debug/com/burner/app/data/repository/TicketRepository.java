package com.burner.app.data.repository;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.burner.app.data.models.Ticket;
import com.burner.app.data.models.TicketStatus;
import com.burner.app.data.models.TicketWithEventData;
import com.burner.app.services.AuthService;
import kotlinx.coroutines.flow.Flow;
import java.util.Date;
import java.util.UUID;
import javax.inject.Inject;
import javax.inject.Singleton;

@javax.inject.Singleton()
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\\\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000e\n\u0002\b\b\n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u0006\n\u0002\b\u0007\n\u0002\u0018\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\b\u0003\b\u0007\u0018\u00002\u00020\u0001B\u001f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u0012\u0006\u0010\u0006\u001a\u00020\u0007\u00a2\u0006\u0002\u0010\bJ$\u0010\u000b\u001a\b\u0012\u0004\u0012\u00020\r0\f2\u0006\u0010\u000e\u001a\u00020\u000fH\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b\u0010\u0010\u0011JZ\u0010\u0012\u001a\b\u0012\u0004\u0012\u00020\u000f0\f2\u0006\u0010\u0013\u001a\u00020\u000f2\u0006\u0010\u0014\u001a\u00020\u000f2\u0006\u0010\u0015\u001a\u00020\u000f2\b\u0010\u0016\u001a\u0004\u0018\u00010\u000f2\u0006\u0010\u0017\u001a\u00020\u00182\u0006\u0010\u0019\u001a\u00020\u001a2\n\b\u0002\u0010\u001b\u001a\u0004\u0018\u00010\u000fH\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b\u001c\u0010\u001dJ \u0010\u001e\u001a\u00020\u000f2\u0006\u0010\u000e\u001a\u00020\u000f2\u0006\u0010\u0013\u001a\u00020\u000f2\u0006\u0010\u001f\u001a\u00020\u000fH\u0002J\b\u0010 \u001a\u00020\u000fH\u0002J\u0012\u0010!\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020$0#0\"J\u0018\u0010%\u001a\u0004\u0018\u00010$2\u0006\u0010\u000e\u001a\u00020\u000fH\u0086@\u00a2\u0006\u0002\u0010\u0011J\u0016\u0010&\u001a\n\u0012\u0006\u0012\u0004\u0018\u00010$0\"2\u0006\u0010\u000e\u001a\u00020\u000fJ\u0018\u0010\'\u001a\u0004\u0018\u00010(2\u0006\u0010\u000e\u001a\u00020\u000fH\u0086@\u00a2\u0006\u0002\u0010\u0011J\u0012\u0010)\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020$0#0\"J\u0012\u0010*\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020$0#0\"R\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0006\u001a\u00020\u0007X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\t\u001a\u00020\nX\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0082\u0002\u000b\n\u0002\b!\n\u0005\b\u00a1\u001e0\u0001\u00a8\u0006+"}, d2 = {"Lcom/burner/app/data/repository/TicketRepository;", "", "firestore", "Lcom/google/firebase/firestore/FirebaseFirestore;", "authService", "Lcom/burner/app/services/AuthService;", "eventRepository", "Lcom/burner/app/data/repository/EventRepository;", "(Lcom/google/firebase/firestore/FirebaseFirestore;Lcom/burner/app/services/AuthService;Lcom/burner/app/data/repository/EventRepository;)V", "ticketsCollection", "Lcom/google/firebase/firestore/CollectionReference;", "cancelTicket", "Lkotlin/Result;", "", "ticketId", "", "cancelTicket-gIAlu-s", "(Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "createTicket", "eventId", "eventName", "venue", "venueId", "startTime", "Lcom/google/firebase/Timestamp;", "totalPrice", "", "eventImageUrl", "createTicket-eH_QyT8", "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Lcom/google/firebase/Timestamp;DLjava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "generateQRCodeData", "userId", "generateTicketNumber", "getPastTickets", "Lkotlinx/coroutines/flow/Flow;", "", "Lcom/burner/app/data/models/Ticket;", "getTicket", "getTicketFlow", "getTicketWithEventData", "Lcom/burner/app/data/models/TicketWithEventData;", "getUpcomingTickets", "getUserTickets", "app_debug"})
public final class TicketRepository {
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.firestore.FirebaseFirestore firestore = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.services.AuthService authService = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.EventRepository eventRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.firestore.CollectionReference ticketsCollection = null;
    
    @javax.inject.Inject()
    public TicketRepository(@org.jetbrains.annotations.NotNull()
    com.google.firebase.firestore.FirebaseFirestore firestore, @org.jetbrains.annotations.NotNull()
    com.burner.app.services.AuthService authService, @org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.EventRepository eventRepository) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.Flow<java.util.List<com.burner.app.data.models.Ticket>> getUserTickets() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.Flow<java.util.List<com.burner.app.data.models.Ticket>> getUpcomingTickets() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.Flow<java.util.List<com.burner.app.data.models.Ticket>> getPastTickets() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object getTicket(@org.jetbrains.annotations.NotNull()
    java.lang.String ticketId, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super com.burner.app.data.models.Ticket> $completion) {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object getTicketWithEventData(@org.jetbrains.annotations.NotNull()
    java.lang.String ticketId, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super com.burner.app.data.models.TicketWithEventData> $completion) {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.Flow<com.burner.app.data.models.Ticket> getTicketFlow(@org.jetbrains.annotations.NotNull()
    java.lang.String ticketId) {
        return null;
    }
    
    private final java.lang.String generateTicketNumber() {
        return null;
    }
    
    private final java.lang.String generateQRCodeData(java.lang.String ticketId, java.lang.String eventId, java.lang.String userId) {
        return null;
    }
}