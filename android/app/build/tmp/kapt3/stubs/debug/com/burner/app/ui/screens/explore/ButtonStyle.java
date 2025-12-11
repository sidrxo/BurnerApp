package com.burner.app.ui.screens.explore;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.models.Event;
import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.TicketRepository;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import java.util.Calendar;
import java.util.Date;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u0000\f\n\u0002\u0018\u0002\n\u0002\u0010\u0010\n\u0002\b\u0006\b\u0086\u0081\u0002\u0018\u00002\b\u0012\u0004\u0012\u00020\u00000\u0001B\u0007\b\u0002\u00a2\u0006\u0002\u0010\u0002j\u0002\b\u0003j\u0002\b\u0004j\u0002\b\u0005j\u0002\b\u0006\u00a8\u0006\u0007"}, d2 = {"Lcom/burner/app/ui/screens/explore/ButtonStyle;", "", "(Ljava/lang/String;I)V", "PRIMARY", "DIMMED_RED", "DIMMED_WHITE", "DIMMED_GRAY", "app_debug"})
public enum ButtonStyle {
    /*public static final*/ PRIMARY /* = new PRIMARY() */,
    /*public static final*/ DIMMED_RED /* = new DIMMED_RED() */,
    /*public static final*/ DIMMED_WHITE /* = new DIMMED_WHITE() */,
    /*public static final*/ DIMMED_GRAY /* = new DIMMED_GRAY() */;
    
    ButtonStyle() {
    }
    
    @org.jetbrains.annotations.NotNull()
    public static kotlin.enums.EnumEntries<com.burner.app.ui.screens.explore.ButtonStyle> getEntries() {
        return null;
    }
}