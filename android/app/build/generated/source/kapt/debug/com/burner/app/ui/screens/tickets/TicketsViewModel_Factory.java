package com.burner.app.ui.screens.tickets;

import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.TicketRepository;
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
public final class TicketsViewModel_Factory implements Factory<TicketsViewModel> {
  private final Provider<TicketRepository> ticketRepositoryProvider;

  private final Provider<EventRepository> eventRepositoryProvider;

  private final Provider<AuthService> authServiceProvider;

  public TicketsViewModel_Factory(Provider<TicketRepository> ticketRepositoryProvider,
      Provider<EventRepository> eventRepositoryProvider,
      Provider<AuthService> authServiceProvider) {
    this.ticketRepositoryProvider = ticketRepositoryProvider;
    this.eventRepositoryProvider = eventRepositoryProvider;
    this.authServiceProvider = authServiceProvider;
  }

  @Override
  public TicketsViewModel get() {
    return newInstance(ticketRepositoryProvider.get(), eventRepositoryProvider.get(), authServiceProvider.get());
  }

  public static TicketsViewModel_Factory create(Provider<TicketRepository> ticketRepositoryProvider,
      Provider<EventRepository> eventRepositoryProvider,
      Provider<AuthService> authServiceProvider) {
    return new TicketsViewModel_Factory(ticketRepositoryProvider, eventRepositoryProvider, authServiceProvider);
  }

  public static TicketsViewModel newInstance(TicketRepository ticketRepository,
      EventRepository eventRepository, AuthService authService) {
    return new TicketsViewModel(ticketRepository, eventRepository, authService);
  }
}
