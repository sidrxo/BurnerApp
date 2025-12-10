package com.burner.app.data.repository;

import com.burner.app.services.AuthService;
import com.google.firebase.firestore.FirebaseFirestore;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
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
public final class BookmarkRepository_Factory implements Factory<BookmarkRepository> {
  private final Provider<FirebaseFirestore> firestoreProvider;

  private final Provider<AuthService> authServiceProvider;

  public BookmarkRepository_Factory(Provider<FirebaseFirestore> firestoreProvider,
      Provider<AuthService> authServiceProvider) {
    this.firestoreProvider = firestoreProvider;
    this.authServiceProvider = authServiceProvider;
  }

  @Override
  public BookmarkRepository get() {
    return newInstance(firestoreProvider.get(), authServiceProvider.get());
  }

  public static BookmarkRepository_Factory create(Provider<FirebaseFirestore> firestoreProvider,
      Provider<AuthService> authServiceProvider) {
    return new BookmarkRepository_Factory(firestoreProvider, authServiceProvider);
  }

  public static BookmarkRepository newInstance(FirebaseFirestore firestore,
      AuthService authService) {
    return new BookmarkRepository(firestore, authService);
  }
}
