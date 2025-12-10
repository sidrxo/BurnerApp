package com.burner.app.services;

import android.content.Context;
import com.google.firebase.functions.FirebaseFunctions;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
@QualifierMetadata("dagger.hilt.android.qualifiers.ApplicationContext")
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
  private final Provider<Context> contextProvider;

  private final Provider<FirebaseFunctions> functionsProvider;

  private final Provider<AuthService> authServiceProvider;

  public PaymentService_Factory(Provider<Context> contextProvider,
      Provider<FirebaseFunctions> functionsProvider, Provider<AuthService> authServiceProvider) {
    this.contextProvider = contextProvider;
    this.functionsProvider = functionsProvider;
    this.authServiceProvider = authServiceProvider;
  }

  @Override
  public PaymentService get() {
    return newInstance(contextProvider.get(), functionsProvider.get(), authServiceProvider.get());
  }

  public static PaymentService_Factory create(Provider<Context> contextProvider,
      Provider<FirebaseFunctions> functionsProvider, Provider<AuthService> authServiceProvider) {
    return new PaymentService_Factory(contextProvider, functionsProvider, authServiceProvider);
  }

  public static PaymentService newInstance(Context context, FirebaseFunctions functions,
      AuthService authService) {
    return new PaymentService(context, functions, authService);
  }
}
