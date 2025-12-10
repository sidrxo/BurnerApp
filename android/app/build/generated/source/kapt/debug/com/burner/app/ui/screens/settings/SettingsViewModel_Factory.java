package com.burner.app.ui.screens.settings;

import com.burner.app.data.repository.PreferencesRepository;
import com.burner.app.services.AuthService;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata
@QualifierMetadata
@DaggerGenerated
@Generated(
    value = "dagger.internal.codegen.ComponentProcessor",
    comments = "https://dagger.dev"
)
@SuppressWarnings({
    "unchecked",
    "rawtypes",
    "KotlinInternal",
    "KotlinInternalInJava"
})
public final class SettingsViewModel_Factory implements Factory<SettingsViewModel> {
  private final Provider<AuthService> authServiceProvider;

  private final Provider<PreferencesRepository> preferencesRepositoryProvider;

  public SettingsViewModel_Factory(Provider<AuthService> authServiceProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    this.authServiceProvider = authServiceProvider;
    this.preferencesRepositoryProvider = preferencesRepositoryProvider;
  }

  @Override
  public SettingsViewModel get() {
    return newInstance(authServiceProvider.get(), preferencesRepositoryProvider.get());
  }

  public static SettingsViewModel_Factory create(Provider<AuthService> authServiceProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    return new SettingsViewModel_Factory(authServiceProvider, preferencesRepositoryProvider);
  }

  public static SettingsViewModel newInstance(AuthService authService,
      PreferencesRepository preferencesRepository) {
    return new SettingsViewModel(authService, preferencesRepository);
  }
}
