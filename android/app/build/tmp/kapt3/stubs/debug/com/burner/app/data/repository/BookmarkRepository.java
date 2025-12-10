package com.burner.app.data.repository;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.burner.app.data.models.Bookmark;
import com.burner.app.data.models.Event;
import com.burner.app.services.AuthService;
import kotlinx.coroutines.flow.Flow;
import javax.inject.Inject;
import javax.inject.Singleton;

@javax.inject.Singleton()
@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000R\n\u0002\u0018\u0002\n\u0002\u0010\u0000\n\u0000\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0010\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0018\u0002\n\u0002\u0010\"\n\u0002\u0010\u000e\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0010 \n\u0002\u0018\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0007\b\u0007\u0018\u00002\u00020\u0001B\u0017\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u0012\u0006\u0010\u0004\u001a\u00020\u0005\u00a2\u0006\u0002\u0010\u0006J$\u0010\u0007\u001a\b\u0012\u0004\u0012\u00020\t0\b2\u0006\u0010\n\u001a\u00020\u000bH\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b\f\u0010\rJ\u0012\u0010\u000e\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00110\u00100\u000fJ\u0010\u0010\u0012\u001a\u00020\u00132\u0006\u0010\u0014\u001a\u00020\u0011H\u0002J\u0012\u0010\u0015\u001a\u000e\u0012\n\u0012\b\u0012\u0004\u0012\u00020\u00170\u00160\u000fJ\u0016\u0010\u0018\u001a\u00020\u00192\u0006\u0010\u001a\u001a\u00020\u0011H\u0086@\u00a2\u0006\u0002\u0010\u001bJ$\u0010\u001c\u001a\b\u0012\u0004\u0012\u00020\t0\b2\u0006\u0010\u001a\u001a\u00020\u0011H\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b\u001d\u0010\u001bJ$\u0010\u001e\u001a\b\u0012\u0004\u0012\u00020\u00190\b2\u0006\u0010\n\u001a\u00020\u000bH\u0086@\u00f8\u0001\u0000\u00f8\u0001\u0001\u00a2\u0006\u0004\b\u001f\u0010\rR\u000e\u0010\u0004\u001a\u00020\u0005X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000\u0082\u0002\u000b\n\u0002\b!\n\u0005\b\u00a1\u001e0\u0001\u00a8\u0006 "}, d2 = {"Lcom/burner/app/data/repository/BookmarkRepository;", "", "firestore", "Lcom/google/firebase/firestore/FirebaseFirestore;", "authService", "Lcom/burner/app/services/AuthService;", "(Lcom/google/firebase/firestore/FirebaseFirestore;Lcom/burner/app/services/AuthService;)V", "addBookmark", "Lkotlin/Result;", "", "event", "Lcom/burner/app/data/models/Event;", "addBookmark-gIAlu-s", "(Lcom/burner/app/data/models/Event;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "getBookmarkedEventIds", "Lkotlinx/coroutines/flow/Flow;", "", "", "getBookmarksCollection", "Lcom/google/firebase/firestore/CollectionReference;", "userId", "getUserBookmarks", "", "Lcom/burner/app/data/models/Bookmark;", "isBookmarked", "", "eventId", "(Ljava/lang/String;Lkotlin/coroutines/Continuation;)Ljava/lang/Object;", "removeBookmark", "removeBookmark-gIAlu-s", "toggleBookmark", "toggleBookmark-gIAlu-s", "app_debug"})
public final class BookmarkRepository {
    @org.jetbrains.annotations.NotNull()
    private final com.google.firebase.firestore.FirebaseFirestore firestore = null;
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.services.AuthService authService = null;
    
    @javax.inject.Inject()
    public BookmarkRepository(@org.jetbrains.annotations.NotNull()
    com.google.firebase.firestore.FirebaseFirestore firestore, @org.jetbrains.annotations.NotNull()
    com.burner.app.services.AuthService authService) {
        super();
    }
    
    private final com.google.firebase.firestore.CollectionReference getBookmarksCollection(java.lang.String userId) {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.Flow<java.util.List<com.burner.app.data.models.Bookmark>> getUserBookmarks() {
        return null;
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.Flow<java.util.Set<java.lang.String>> getBookmarkedEventIds() {
        return null;
    }
    
    @org.jetbrains.annotations.Nullable()
    public final java.lang.Object isBookmarked(@org.jetbrains.annotations.NotNull()
    java.lang.String eventId, @org.jetbrains.annotations.NotNull()
    kotlin.coroutines.Continuation<? super java.lang.Boolean> $completion) {
        return null;
    }
}