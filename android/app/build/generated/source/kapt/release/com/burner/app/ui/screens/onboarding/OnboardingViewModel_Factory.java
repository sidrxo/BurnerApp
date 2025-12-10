package com.burner.app.ui.screens.onboarding;

import android.content.Context;
import com.burner.app.data.repository.PreferencesRepository;
import com.burner.app.data.repository.TagRepository;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata
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
public final class OnboardingViewModel_Factory implements Factory<OnboardingViewModel> {
  private final Provider<PreferencesRepository> preferencesRepositoryProvider;

  private final Provider<TagRepository> tagRepositoryProvider;

  private final Provider<Context> contextProvider;

  public OnboardingViewModel_Factory(Provider<PreferencesRepository> preferencesRepositoryProvider,
      Provider<TagRepository> tagRepositoryProvider, Provider<Context> contextProvider) {
    this.preferencesRepositoryProvider = preferencesRepositoryProvider;
    this.tagRepositoryProvider = tagRepositoryProvider;
    this.contextProvider = contextProvider;
  }

  @Override
  public OnboardingViewModel get() {
    return newInstance(preferencesRepositoryProvider.get(), tagRepositoryProvider.get(), contextProvider.get());
  }

  public static OnboardingViewModel_Factory create(
      Provider<PreferencesRepository> preferencesRepositoryProvider,
      Provider<TagRepository> tagRepositoryProvider, Provider<Context> contextProvider) {
    return new OnboardingViewModel_Factory(preferencesRepositoryProvider, tagRepositoryProvider, contextProvider);
  }

  public static OnboardingViewModel newInstance(PreferencesRepository preferencesRepository,
      TagRepository tagRepository, Context context) {
    return new OnboardingViewModel(preferencesRepository, tagRepository, context);
  }
}
