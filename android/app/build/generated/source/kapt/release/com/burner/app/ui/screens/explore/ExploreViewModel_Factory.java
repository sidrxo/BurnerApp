package com.burner.app.ui.screens.explore;

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
public final class ExploreViewModel_Factory implements Factory<ExploreViewModel> {
  private final Provider<EventRepository> eventRepositoryProvider;

  private final Provider<BookmarkRepository> bookmarkRepositoryProvider;

  private final Provider<PreferencesRepository> preferencesRepositoryProvider;

  public ExploreViewModel_Factory(Provider<EventRepository> eventRepositoryProvider,
      Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    this.eventRepositoryProvider = eventRepositoryProvider;
    this.bookmarkRepositoryProvider = bookmarkRepositoryProvider;
    this.preferencesRepositoryProvider = preferencesRepositoryProvider;
  }

  @Override
  public ExploreViewModel get() {
    return newInstance(eventRepositoryProvider.get(), bookmarkRepositoryProvider.get(), preferencesRepositoryProvider.get());
  }

  public static ExploreViewModel_Factory create(Provider<EventRepository> eventRepositoryProvider,
      Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider) {
    return new ExploreViewModel_Factory(eventRepositoryProvider, bookmarkRepositoryProvider, preferencesRepositoryProvider);
  }

  public static ExploreViewModel newInstance(EventRepository eventRepository,
      BookmarkRepository bookmarkRepository, PreferencesRepository preferencesRepository) {
    return new ExploreViewModel(eventRepository, bookmarkRepository, preferencesRepository);
  }
}
