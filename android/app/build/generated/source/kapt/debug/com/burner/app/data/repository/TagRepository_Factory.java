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
public final class TagRepository_Factory implements Factory<TagRepository> {
  private final Provider<FirebaseFirestore> firestoreProvider;

  public TagRepository_Factory(Provider<FirebaseFirestore> firestoreProvider) {
    this.firestoreProvider = firestoreProvider;
  }

  @Override
  public TagRepository get() {
    return newInstance(firestoreProvider.get());
  }

  public static TagRepository_Factory create(Provider<FirebaseFirestore> firestoreProvider) {
    return new TagRepository_Factory(firestoreProvider);
  }

  public static TagRepository newInstance(FirebaseFirestore firestore) {
    return new TagRepository(firestore);
  }
}
