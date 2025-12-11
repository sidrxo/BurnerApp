package com.burner.app.ui.screens.explore;

import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.PreferencesRepository;
import com.burner.app.data.repository.TagRepository;
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

  private final Provider<TagRepository> tagRepositoryProvider;

  public ExploreViewModel_Factory(Provider<EventRepository> eventRepositoryProvider,
      Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider,
      Provider<TagRepository> tagRepositoryProvider) {
    this.eventRepositoryProvider = eventRepositoryProvider;
    this.bookmarkRepositoryProvider = bookmarkRepositoryProvider;
    this.preferencesRepositoryProvider = preferencesRepositoryProvider;
    this.tagRepositoryProvider = tagRepositoryProvider;
  }

  @Override
  public ExploreViewModel get() {
    return newInstance(eventRepositoryProvider.get(), bookmarkRepositoryProvider.get(), preferencesRepositoryProvider.get(), tagRepositoryProvider.get());
  }

  public static ExploreViewModel_Factory create(Provider<EventRepository> eventRepositoryProvider,
      Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<PreferencesRepository> preferencesRepositoryProvider,
      Provider<TagRepository> tagRepositoryProvider) {
    return new ExploreViewModel_Factory(eventRepositoryProvider, bookmarkRepositoryProvider, preferencesRepositoryProvider, tagRepositoryProvider);
  }

  public static ExploreViewModel newInstance(EventRepository eventRepository,
      BookmarkRepository bookmarkRepository, PreferencesRepository preferencesRepository,
      TagRepository tagRepository) {
    return new ExploreViewModel(eventRepository, bookmarkRepository, preferencesRepository, tagRepository);
  }
}
