package com.burner.app.data.repository;

import com.google.firebase.Timestamp;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.burner.app.data.models.Event;
import kotlinx.coroutines.flow.Flow;
import java.util.Calendar;
import java.util.Date;
import javax.inject.Inject;
import javax.inject.Singleton;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0005\b\u0086\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005\u00a8\u0006\u0006"}, d2 = {"Lcom/burner/app/data/repository/SearchSortOption;", "", "(Ljava/lang/String;I)V", "DATE", "PRICE", "NEARBY", "app_debug"})
public enum SearchSortOption {
    /*public static final*/ DATE /* = new DATE() */,
    /*public static final*/ PRICE /* = new PRICE() */,
    /*public static final*/ NEARBY /* = new NEARBY() */;
    
    SearchSortOption() {
    }
    
    @org.jetbrains.annotations.NotNull()
    public static kotlin.enums.EnumEntries<com.burner.app.data.repository.SearchSortOption> getEntries() {
        return null;
    }
}