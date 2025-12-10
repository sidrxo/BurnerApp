package com.burner.app.ui.screens.settings;

import androidx.lifecycle.ViewModel;
import com.burner.app.data.repository.PreferencesRepository;
import dagger.hilt.android.lifecycle.HiltViewModel;
import kotlinx.coroutines.flow.*;
import javax.inject.Inject;

@kotlin.Metadata(mv = {1, 9, 0}, k = 1, xi = 48, d1 = {"\u00002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0002\n\u0002\u0018\u0002\n\u0002\u0018\u0002\n\u0000\n\u0002\u0018\u0002\n\u0002\b\u0003\n\u0002\u0010\u0002\n\u0000\n\u0002\u0010\u000b\n\u0002\b\u0005\b\u0007\u0018\u00002\u00020\u0001B\u000f\b\u0007\u0012\u0006\u0010\u0002\u001a\u00020\u0003\u00a2\u0006\u0002\u0010\u0004J\u000e\u0010\f\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\u000fJ\u000e\u0010\u0010\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\u000fJ\u000e\u0010\u0011\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\u000fJ\u000e\u0010\u0012\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\u000fJ\u000e\u0010\u0013\u001a\u00020\r2\u0006\u0010\u000e\u001a\u00020\u000fR\u0014\u0010\u0005\u001a\b\u0012\u0004\u0012\u00020\u00070\u0006X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u000e\u0010\u0002\u001a\u00020\u0003X\u0082\u0004\u00a2\u0006\u0002\n\u0000R\u0017\u0010\b\u001a\b\u0012\u0004\u0012\u00020\u00070\t\u00a2\u0006\b\n\u0000\u001a\u0004\b\n\u0010\u000b\u00a8\u0006\u0014"}, d2 = {"Lcom/burner/app/ui/screens/settings/NotificationSettingsViewModel;", "Landroidx/lifecycle/ViewModel;", "preferencesRepository", "Lcom/burner/app/data/repository/PreferencesRepository;", "(Lcom/burner/app/data/repository/PreferencesRepository;)V", "_uiState", "Lkotlinx/coroutines/flow/MutableStateFlow;", "Lcom/burner/app/ui/screens/settings/NotificationSettingsUiState;", "uiState", "Lkotlinx/coroutines/flow/StateFlow;", "getUiState", "()Lkotlinx/coroutines/flow/StateFlow;", "setEventReminders", "", "enabled", "", "setMarketingEmails", "setNewEvents", "setPriceDrops", "setTicketConfirmations", "app_debug"})
@dagger.hilt.android.lifecycle.HiltViewModel()
public final class NotificationSettingsViewModel extends androidx.lifecycle.ViewModel {
    @org.jetbrains.annotations.NotNull()
    private final com.burner.app.data.repository.PreferencesRepository preferencesRepository = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.MutableStateFlow<com.burner.app.ui.screens.settings.NotificationSettingsUiState> _uiState = null;
    @org.jetbrains.annotations.NotNull()
    private final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.settings.NotificationSettingsUiState> uiState = null;
    
    @javax.inject.Inject()
    public NotificationSettingsViewModel(@org.jetbrains.annotations.NotNull()
    com.burner.app.data.repository.PreferencesRepository preferencesRepository) {
        super();
    }
    
    @org.jetbrains.annotations.NotNull()
    public final kotlinx.coroutines.flow.StateFlow<com.burner.app.ui.screens.settings.NotificationSettingsUiState> getUiState() {
        return null;
    }
    
    public final void setEventReminders(boolean enabled) {
    }
    
    public final void setNewEvents(boolean enabled) {
    }
    
    public final void setPriceDrops(boolean enabled) {
    }
    
    public final void setMarketingEmails(boolean enabled) {
    }
    
    public final void setTicketConfirmations(boolean enabled) {
    }
}