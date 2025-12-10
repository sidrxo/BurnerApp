package com.burner.app.ui.screens.tickets;

import com.burner.app.data.repository.TicketRepository;
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
public final class TicketDetailViewModel_Factory implements Factory<TicketDetailViewModel> {
  private final Provider<TicketRepository> ticketRepositoryProvider;

  public TicketDetailViewModel_Factory(Provider<TicketRepository> ticketRepositoryProvider) {
    this.ticketRepositoryProvider = ticketRepositoryProvider;
  }

  @Override
  public TicketDetailViewModel get() {
    return newInstance(ticketRepositoryProvider.get());
  }

  public static TicketDetailViewModel_Factory create(
      Provider<TicketRepository> ticketRepositoryProvider) {
    return new TicketDetailViewModel_Factory(ticketRepositoryProvider);
  }

  public static TicketDetailViewModel newInstance(TicketRepository ticketRepository) {
    return new TicketDetailViewModel(ticketRepository);
  }
}
