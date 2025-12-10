package com.burner.app.ui.screens.settings;

import com.burner.app.services.PaymentService;
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
public final class PaymentSettingsViewModel_Factory implements Factory<PaymentSettingsViewModel> {
  private final Provider<PaymentService> paymentServiceProvider;

  public PaymentSettingsViewModel_Factory(Provider<PaymentService> paymentServiceProvider) {
    this.paymentServiceProvider = paymentServiceProvider;
  }

  @Override
  public PaymentSettingsViewModel get() {
    return newInstance(paymentServiceProvider.get());
  }

  public static PaymentSettingsViewModel_Factory create(
      Provider<PaymentService> paymentServiceProvider) {
    return new PaymentSettingsViewModel_Factory(paymentServiceProvider);
  }

  public static PaymentSettingsViewModel newInstance(PaymentService paymentService) {
    return new PaymentSettingsViewModel(paymentService);
  }
}
