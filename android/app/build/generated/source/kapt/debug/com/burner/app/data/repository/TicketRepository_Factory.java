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
public final class TicketRepository_Factory implements Factory<TicketRepository> {
  private final Provider<FirebaseFirestore> firestoreProvider;

  private final Provider<AuthService> authServiceProvider;

  private final Provider<EventRepository> eventRepositoryProvider;

  public TicketRepository_Factory(Provider<FirebaseFirestore> firestoreProvider,
      Provider<AuthService> authServiceProvider,
      Provider<EventRepository> eventRepositoryProvider) {
    this.firestoreProvider = firestoreProvider;
    this.authServiceProvider = authServiceProvider;
    this.eventRepositoryProvider = eventRepositoryProvider;
  }

  @Override
  public TicketRepository get() {
    return newInstance(firestoreProvider.get(), authServiceProvider.get(), eventRepositoryProvider.get());
  }

  public static TicketRepository_Factory create(Provider<FirebaseFirestore> firestoreProvider,
      Provider<AuthService> authServiceProvider,
      Provider<EventRepository> eventRepositoryProvider) {
    return new TicketRepository_Factory(firestoreProvider, authServiceProvider, eventRepositoryProvider);
  }

  public static TicketRepository newInstance(FirebaseFirestore firestore, AuthService authService,
      EventRepository eventRepository) {
    return new TicketRepository(firestore, authService, eventRepository);
  }
}
