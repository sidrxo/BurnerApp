package com.burner.app.ui.screens.search;

import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.PreferencesRepository;
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
public final class SearchViewModel_Factory implements Factory<SearchViewModel> {
  private final Provider<EventRepository> eventRepositoryProvider;

  private final Provider<BookmarkRepository> bookmarkRepositoryProvider;

  private final Provider<PreferencesRepository> preferencesRepositoryProvider;

  public SearchViewModel_Factory(Provider<EventRepository> eventRepositoryProvider,
      Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    this.eventRepositoryProvider = eventRepositoryProvider;
    this.bookmarkRepositoryProvider = bookmarkRepositoryProvider;
    this.preferencesRepositoryProvider = preferencesRepositoryProvider;
  }

  @Override
  public SearchViewModel get() {
    return newInstance(eventRepositoryProvider.get(), bookmarkRepositoryProvider.get(), preferencesRepositoryProvider.get());
  }

  public static SearchViewModel_Factory create(Provider<EventRepository> eventRepositoryProvider,
      Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    return new SearchViewModel_Factory(eventRepositoryProvider, bookmarkRepositoryProvider, preferencesRepositoryProvider);
  }

  public static SearchViewModel newInstance(EventRepository eventRepository,
      BookmarkRepository bookmarkRepository, PreferencesRepository preferencesRepository) {
    return new SearchViewModel(eventRepository, bookmarkRepository, preferencesRepository);
  }
}
