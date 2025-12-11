package com.burner.app.services;

import android.content.Context;
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

  public PaymentService_Factory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public PaymentService get() {
    return newInstance(contextProvider.get());
  }

  public static PaymentService_Factory create(Provider<Context> contextProvider) {
    return new PaymentService_Factory(contextProvider);
  }

  public static PaymentService newInstance(Context context) {
    return new PaymentService(context);
  }
}
