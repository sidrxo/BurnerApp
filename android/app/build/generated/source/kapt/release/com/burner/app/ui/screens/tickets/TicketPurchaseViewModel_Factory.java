package com.burner.app.ui.screens.tickets;

import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.TicketRepository;
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
public final class TicketPurchaseViewModel_Factory implements Factory<TicketPurchaseViewModel> {
  private final Provider<EventRepository> eventRepositoryProvider;

  private final Provider<TicketRepository> ticketRepositoryProvider;

  private final Provider<PaymentService> paymentServiceProvider;

  public TicketPurchaseViewModel_Factory(Provider<EventRepository> eventRepositoryProvider,
      Provider<TicketRepository> ticketRepositoryProvider,
      Provider<PaymentService> paymentServiceProvider) {
    this.eventRepositoryProvider = eventRepositoryProvider;
    this.ticketRepositoryProvider = ticketRepositoryProvider;
    this.paymentServiceProvider = paymentServiceProvider;
  }

  @Override
  public TicketPurchaseViewModel get() {
    return newInstance(eventRepositoryProvider.get(), ticketRepositoryProvider.get(), paymentServiceProvider.get());
  }

  public static TicketPurchaseViewModel_Factory create(
      Provider<EventRepository> eventRepositoryProvider,
      Provider<TicketRepository> ticketRepositoryProvider,
      Provider<PaymentService> paymentServiceProvider) {
    return new TicketPurchaseViewModel_Factory(eventRepositoryProvider, ticketRepositoryProvider, paymentServiceProvider);
  }

  public static TicketPurchaseViewModel newInstance(EventRepository eventRepository,
      TicketRepository ticketRepository, PaymentService paymentService) {
    return new TicketPurchaseViewModel(eventRepository, ticketRepository, paymentService);
  }
}
