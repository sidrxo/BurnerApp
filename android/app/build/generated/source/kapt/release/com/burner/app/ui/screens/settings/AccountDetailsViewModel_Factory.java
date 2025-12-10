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
public final class AccountDetailsViewModel_Factory implements Factory<AccountDetailsViewModel> {
  private final Provider<AuthService> authServiceProvider;

  private final Provider<PreferencesRepository> preferencesRepositoryProvider;

  public AccountDetailsViewModel_Factory(Provider<AuthService> authServiceProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    this.authServiceProvider = authServiceProvider;
    this.preferencesRepositoryProvider = preferencesRepositoryProvider;
  }

  @Override
  public AccountDetailsViewModel get() {
    return newInstance(authServiceProvider.get(), preferencesRepositoryProvider.get());
  }

  public static AccountDetailsViewModel_Factory create(Provider<AuthService> authServiceProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    return new AccountDetailsViewModel_Factory(authServiceProvider, preferencesRepositoryProvider);
  }

  public static AccountDetailsViewModel newInstance(AuthService authService,
      PreferencesRepository preferencesRepository) {
    return new AccountDetailsViewModel(authService, preferencesRepository);
  }
}
