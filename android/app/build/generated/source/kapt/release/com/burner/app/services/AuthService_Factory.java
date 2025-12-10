package com.burner.app.services;

import android.content.Context;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
@QualifierMetadata("dagger.hilt.android.qualifiers.ApplicationContext")
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
public final class AuthService_Factory implements Factory<AuthService> {
  private final Provider<FirebaseAuth> authProvider;

  private final Provider<FirebaseFirestore> firestoreProvider;

  private final Provider<Context> contextProvider;

  public AuthService_Factory(Provider<FirebaseAuth> authProvider,
      Provider<FirebaseFirestore> firestoreProvider, Provider<Context> contextProvider) {
    this.authProvider = authProvider;
    this.firestoreProvider = firestoreProvider;
    this.contextProvider = contextProvider;
  }

  @Override
  public AuthService get() {
    return newInstance(authProvider.get(), firestoreProvider.get(), contextProvider.get());
  }

  public static AuthService_Factory create(Provider<FirebaseAuth> authProvider,
      Provider<FirebaseFirestore> firestoreProvider, Provider<Context> contextProvider) {
    return new AuthService_Factory(authProvider, firestoreProvider, contextProvider);
  }

  public static AuthService newInstance(FirebaseAuth auth, FirebaseFirestore firestore,
      Context context) {
    return new AuthService(auth, firestore, context);
  }
}
