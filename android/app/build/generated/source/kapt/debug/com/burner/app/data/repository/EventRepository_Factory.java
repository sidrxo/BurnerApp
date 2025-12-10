package com.burner.app.data.repository;

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
public final class EventRepository_Factory implements Factory<EventRepository> {
  private final Provider<FirebaseFirestore> firestoreProvider;

  public EventRepository_Factory(Provider<FirebaseFirestore> firestoreProvider) {
    this.firestoreProvider = firestoreProvider;
  }

  @Override
  public EventRepository get() {
    return newInstance(firestoreProvider.get());
  }

  public static EventRepository_Factory create(Provider<FirebaseFirestore> firestoreProvider) {
    return new EventRepository_Factory(firestoreProvider);
  }

  public static EventRepository newInstance(FirebaseFirestore firestore) {
    return new EventRepository(firestore);
  }
}
