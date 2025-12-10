package com.burner.app.ui.screens.bookmarks;

import com.burner.app.data.repository.BookmarkRepository;
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
public final class BookmarksViewModel_Factory implements Factory<BookmarksViewModel> {
  private final Provider<BookmarkRepository> bookmarkRepositoryProvider;

  private final Provider<AuthService> authServiceProvider;

  public BookmarksViewModel_Factory(Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<AuthService> authServiceProvider) {
    this.bookmarkRepositoryProvider = bookmarkRepositoryProvider;
    this.authServiceProvider = authServiceProvider;
  }

  @Override
  public BookmarksViewModel get() {
    return newInstance(bookmarkRepositoryProvider.get(), authServiceProvider.get());
  }

  public static BookmarksViewModel_Factory create(
      Provider<BookmarkRepository> bookmarkRepositoryProvider,
      Provider<AuthService> authServiceProvider) {
    return new BookmarksViewModel_Factory(bookmarkRepositoryProvider, authServiceProvider);
  }

  public static BookmarksViewModel newInstance(BookmarkRepository bookmarkRepository,
      AuthService authService) {
    return new BookmarksViewModel(bookmarkRepository, authService);
  }
}
