package com.burner.app.services;

import com.google.firebase.functions.FirebaseFunctions;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
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
public final class PaymentService_Factory implements Factory<PaymentService> {
  private final Provider<FirebaseFunctions> functionsProvider;

  private final Provider<AuthService> authServiceProvider;

  public PaymentService_Factory(Provider<FirebaseFunctions> functionsProvider,
      Provider<AuthService> authServiceProvider) {
    this.functionsProvider = functionsProvider;
    this.authServiceProvider = authServiceProvider;
  }

  @Override
  public PaymentService get() {
    return newInstance(functionsProvider.get(), authServiceProvider.get());
  }

  public static PaymentService_Factory create(Provider<FirebaseFunctions> functionsProvider,
      Provider<AuthService> authServiceProvider) {
    return new PaymentService_Factory(functionsProvider, authServiceProvider);
  }

  public static PaymentService newInstance(FirebaseFunctions functions, AuthService authService) {
    return new PaymentService(functions, authService);
  }
}
