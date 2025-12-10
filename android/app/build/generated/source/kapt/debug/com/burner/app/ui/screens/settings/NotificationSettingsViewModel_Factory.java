package com.burner.app.ui.screens.settings;

import com.burner.app.data.repository.PreferencesRepository;
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
public final class NotificationSettingsViewModel_Factory implements Factory<NotificationSettingsViewModel> {
  private final Provider<PreferencesRepository> preferencesRepositoryProvider;

  public NotificationSettingsViewModel_Factory(
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    this.preferencesRepositoryProvider = preferencesRepositoryProvider;
  }

  @Override
  public NotificationSettingsViewModel get() {
    return newInstance(preferencesRepositoryProvider.get());
  }

  public static NotificationSettingsViewModel_Factory create(
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    return new NotificationSettingsViewModel_Factory(preferencesRepositoryProvider);
  }

  public static NotificationSettingsViewModel newInstance(
      PreferencesRepository preferencesRepository) {
    return new NotificationSettingsViewModel(preferencesRepository);
  }
}
