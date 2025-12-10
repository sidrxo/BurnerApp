package com.burner.app.ui.screens.auth;

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
public final class AuthViewModel_Factory implements Factory<AuthViewModel> {
  private final Provider<AuthService> authServiceProvider;

  public AuthViewModel_Factory(Provider<AuthService> authServiceProvider) {
    this.authServiceProvider = authServiceProvider;
  }

  @Override
  public AuthViewModel get() {
    return newInstance(authServiceProvider.get());
  }

  public static AuthViewModel_Factory create(Provider<AuthService> authServiceProvider) {
    return new AuthViewModel_Factory(authServiceProvider);
  }

  public static AuthViewModel newInstance(AuthService authService) {
    return new AuthViewModel(authService);
  }
}
