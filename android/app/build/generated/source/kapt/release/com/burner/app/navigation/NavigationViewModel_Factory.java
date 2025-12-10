package com.burner.app.navigation;

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
public final class NavigationViewModel_Factory implements Factory<NavigationViewModel> {
  private final Provider<PreferencesRepository> preferencesRepositoryProvider;

  private final Provider<AuthService> authServiceProvider;

  public NavigationViewModel_Factory(Provider<PreferencesRepository> preferencesRepositoryProvider,
      Provider<AuthService> authServiceProvider) {
    this.preferencesRepositoryProvider = preferencesRepositoryProvider;
    this.authServiceProvider = authServiceProvider;
  }

  @Override
  public NavigationViewModel get() {
    return newInstance(preferencesRepositoryProvider.get(), authServiceProvider.get());
  }

  public static NavigationViewModel_Factory create(
      Provider<PreferencesRepository> preferencesRepositoryProvider,
      Provider<AuthService> authServiceProvider) {
    return new NavigationViewModel_Factory(preferencesRepositoryProvider, authServiceProvider);
  }

  public static NavigationViewModel newInstance(PreferencesRepository preferencesRepository,
      AuthService authService) {
    return new NavigationViewModel(preferencesRepository, authService);
  }
}
