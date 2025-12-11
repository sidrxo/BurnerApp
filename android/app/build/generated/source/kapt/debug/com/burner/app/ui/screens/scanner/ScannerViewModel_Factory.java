package com.burner.app.ui.screens.scanner;

import com.burner.app.data.repository.EventRepository;
import com.burner.app.services.AuthService;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.functions.FirebaseFunctions;
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
public final class ScannerViewModel_Factory implements Factory<ScannerViewModel> {
  private final Provider<AuthService> authServiceProvider;

  private final Provider<EventRepository> eventRepositoryProvider;

  private final Provider<FirebaseFirestore> firestoreProvider;

  private final Provider<FirebaseFunctions> functionsProvider;

  public ScannerViewModel_Factory(Provider<AuthService> authServiceProvider,
      Provider<EventRepository> eventRepositoryProvider,
      Provider<FirebaseFirestore> firestoreProvider,
      Provider<FirebaseFunctions> functionsProvider) {
    this.authServiceProvider = authServiceProvider;
    this.eventRepositoryProvider = eventRepositoryProvider;
    this.firestoreProvider = firestoreProvider;
    this.functionsProvider = functionsProvider;
  }

  @Override
  public ScannerViewModel get() {
    return newInstance(authServiceProvider.get(), eventRepositoryProvider.get(), firestoreProvider.get(), functionsProvider.get());
  }

  public static ScannerViewModel_Factory create(Provider<AuthService> authServiceProvider,
      Provider<EventRepository> eventRepositoryProvider,
      Provider<FirebaseFirestore> firestoreProvider,
      Provider<FirebaseFunctions> functionsProvider) {
    return new ScannerViewModel_Factory(authServiceProvider, eventRepositoryProvider, firestoreProvider, functionsProvider);
  }

  public static ScannerViewModel newInstance(AuthService authService,
      EventRepository eventRepository, FirebaseFirestore firestore, FirebaseFunctions functions) {
    return new ScannerViewModel(authService, eventRepository, firestore, functions);
  }
}
