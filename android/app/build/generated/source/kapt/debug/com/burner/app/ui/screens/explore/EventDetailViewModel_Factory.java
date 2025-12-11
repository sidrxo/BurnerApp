package com.burner.app.ui.screens.explore;

import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
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
public final class EventDetailViewModel_Factory implements Factory<EventDetailViewModel> {
  private final Provider<EventRepository> eventRepositoryProvider;

  private final Provider<BookmarkRepository> bookmarkRepositoryProvider;

  private final Provider<TicketRepository> ticketRepositoryProvider;

  public EventDetailViewModel_Factory(Provider<EventRepository> eventRepositoryProvider,
      Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<TicketRepository> ticketRepositoryProvider) {
    this.eventRepositoryProvider = eventRepositoryProvider;
    this.bookmarkRepositoryProvider = bookmarkRepositoryProvider;
    this.ticketRepositoryProvider = ticketRepositoryProvider;
  }

  @Override
  public EventDetailViewModel get() {
    return newInstance(eventRepositoryProvider.get(), bookmarkRepositoryProvider.get(), ticketRepositoryProvider.get());
  }

  public static EventDetailViewModel_Factory create(
      Provider<EventRepository> eventRepositoryProvider,
      Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<TicketRepository> ticketRepositoryProvider) {
    return new EventDetailViewModel_Factory(eventRepositoryProvider, bookmarkRepositoryProvider, ticketRepositoryProvider);
  }

  public static EventDetailViewModel newInstance(EventRepository eventRepository,
      BookmarkRepository bookmarkRepository, TicketRepository ticketRepository) {
    return new EventDetailViewModel(eventRepository, bookmarkRepository, ticketRepository);
  }
}
