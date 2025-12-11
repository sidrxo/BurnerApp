package com.burner.app;

import android.app.Activity;
import android.app.Service;
import android.view.View;
import androidx.datastore.core.DataStore;
import androidx.datastore.preferences.core.Preferences;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.SavedStateHandle;
import androidx.lifecycle.ViewModel;
import com.burner.app.data.repository.BookmarkRepository;
import com.burner.app.data.repository.EventRepository;
import com.burner.app.data.repository.PreferencesRepository;
import com.burner.app.data.repository.TagRepository;
import com.burner.app.data.repository.TicketRepository;
import com.burner.app.di.AppModule;
import com.burner.app.di.AppModule_ProvideDataStoreFactory;
import com.burner.app.di.AppModule_ProvideFirebaseAuthFactory;
import com.burner.app.di.AppModule_ProvideFirebaseFirestoreFactory;
import com.burner.app.navigation.NavigationViewModel;
import com.burner.app.navigation.NavigationViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.services.AuthService;
import com.burner.app.services.PaymentService;
import com.burner.app.ui.screens.auth.AuthViewModel;
import com.burner.app.ui.screens.auth.AuthViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.bookmarks.BookmarksViewModel;
import com.burner.app.ui.screens.bookmarks.BookmarksViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.explore.EventDetailViewModel;
import com.burner.app.ui.screens.explore.EventDetailViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.explore.ExploreViewModel;
import com.burner.app.ui.screens.explore.ExploreViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.onboarding.OnboardingViewModel;
import com.burner.app.ui.screens.onboarding.OnboardingViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.search.SearchViewModel;
import com.burner.app.ui.screens.search.SearchViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.settings.AccountDetailsViewModel;
import com.burner.app.ui.screens.settings.AccountDetailsViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.settings.NotificationSettingsViewModel;
import com.burner.app.ui.screens.settings.NotificationSettingsViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.settings.PaymentSettingsViewModel;
import com.burner.app.ui.screens.settings.PaymentSettingsViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.settings.SettingsViewModel;
import com.burner.app.ui.screens.settings.SettingsViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.tickets.TicketDetailViewModel;
import com.burner.app.ui.screens.tickets.TicketDetailViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.tickets.TicketPurchaseViewModel;
import com.burner.app.ui.screens.tickets.TicketPurchaseViewModel_HiltModules_KeyModule_ProvideFactory;
import com.burner.app.ui.screens.tickets.TicketsViewModel;
import com.burner.app.ui.screens.tickets.TicketsViewModel_HiltModules_KeyModule_ProvideFactory;
import com.google.common.collect.ImmutableMap;
import com.google.common.collect.ImmutableSet;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import dagger.hilt.android.ActivityRetainedLifecycle;
import dagger.hilt.android.ViewModelLifecycle;
import dagger.hilt.android.flags.HiltWrapper_FragmentGetContextFix_FragmentGetContextFixModule;
import dagger.hilt.android.internal.builders.ActivityComponentBuilder;
import dagger.hilt.android.internal.builders.ActivityRetainedComponentBuilder;
import dagger.hilt.android.internal.builders.FragmentComponentBuilder;
import dagger.hilt.android.internal.builders.ServiceComponentBuilder;
import dagger.hilt.android.internal.builders.ViewComponentBuilder;
import dagger.hilt.android.internal.builders.ViewModelComponentBuilder;
import dagger.hilt.android.internal.builders.ViewWithFragmentComponentBuilder;
import dagger.hilt.android.internal.lifecycle.DefaultViewModelFactories;
import dagger.hilt.android.internal.lifecycle.DefaultViewModelFactories_InternalFactoryFactory_Factory;
import dagger.hilt.android.internal.managers.ActivityRetainedComponentManager_LifecycleModule_ProvideActivityRetainedLifecycleFactory;
import dagger.hilt.android.internal.modules.ApplicationContextModule;
import dagger.hilt.android.internal.modules.ApplicationContextModule_ProvideContextFactory;
import dagger.internal.DaggerGenerated;
import dagger.internal.DoubleCheck;
import dagger.internal.Preconditions;
import java.util.Map;
import java.util.Set;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

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
public final class DaggerBurnerApplication_HiltComponents_SingletonC {
  private DaggerBurnerApplication_HiltComponents_SingletonC() {
  }

  public static Builder builder() {
    return new Builder();
  }

  public static final class Builder {
    private ApplicationContextModule applicationContextModule;

    private Builder() {
    }

    /**
     * @deprecated This module is declared, but an instance is not used in the component. This method is a no-op. For more, see https://dagger.dev/unused-modules.
     */
    @Deprecated
    public Builder appModule(AppModule appModule) {
      Preconditions.checkNotNull(appModule);
      return this;
    }

    public Builder applicationContextModule(ApplicationContextModule applicationContextModule) {
      this.applicationContextModule = Preconditions.checkNotNull(applicationContextModule);
      return this;
    }

    /**
     * @deprecated This module is declared, but an instance is not used in the component. This method is a no-op. For more, see https://dagger.dev/unused-modules.
     */
    @Deprecated
    public Builder hiltWrapper_FragmentGetContextFix_FragmentGetContextFixModule(
        HiltWrapper_FragmentGetContextFix_FragmentGetContextFixModule hiltWrapper_FragmentGetContextFix_FragmentGetContextFixModule) {
      Preconditions.checkNotNull(hiltWrapper_FragmentGetContextFix_FragmentGetContextFixModule);
      return this;
    }

    public BurnerApplication_HiltComponents.SingletonC build() {
      Preconditions.checkBuilderRequirement(applicationContextModule, ApplicationContextModule.class);
      return new SingletonCImpl(applicationContextModule);
    }
  }

  private static final class ActivityRetainedCBuilder implements BurnerApplication_HiltComponents.ActivityRetainedC.Builder {
    private final SingletonCImpl singletonCImpl;

    private ActivityRetainedCBuilder(SingletonCImpl singletonCImpl) {
      this.singletonCImpl = singletonCImpl;
    }

    @Override
    public BurnerApplication_HiltComponents.ActivityRetainedC build() {
      return new ActivityRetainedCImpl(singletonCImpl);
    }
  }

  private static final class ActivityCBuilder implements BurnerApplication_HiltComponents.ActivityC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private Activity activity;

    private ActivityCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
    }

    @Override
    public ActivityCBuilder activity(Activity activity) {
      this.activity = Preconditions.checkNotNull(activity);
      return this;
    }

    @Override
    public BurnerApplication_HiltComponents.ActivityC build() {
      Preconditions.checkBuilderRequirement(activity, Activity.class);
      return new ActivityCImpl(singletonCImpl, activityRetainedCImpl, activity);
    }
  }

  private static final class FragmentCBuilder implements BurnerApplication_HiltComponents.FragmentC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private Fragment fragment;

    private FragmentCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
    }

    @Override
    public FragmentCBuilder fragment(Fragment fragment) {
      this.fragment = Preconditions.checkNotNull(fragment);
      return this;
    }

    @Override
    public BurnerApplication_HiltComponents.FragmentC build() {
      Preconditions.checkBuilderRequirement(fragment, Fragment.class);
      return new FragmentCImpl(singletonCImpl, activityRetainedCImpl, activityCImpl, fragment);
    }
  }

  private static final class ViewWithFragmentCBuilder implements BurnerApplication_HiltComponents.ViewWithFragmentC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final FragmentCImpl fragmentCImpl;

    private View view;

    private ViewWithFragmentCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl,
        FragmentCImpl fragmentCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
      this.fragmentCImpl = fragmentCImpl;
    }

    @Override
    public ViewWithFragmentCBuilder view(View view) {
      this.view = Preconditions.checkNotNull(view);
      return this;
    }

    @Override
    public BurnerApplication_HiltComponents.ViewWithFragmentC build() {
      Preconditions.checkBuilderRequirement(view, View.class);
      return new ViewWithFragmentCImpl(singletonCImpl, activityRetainedCImpl, activityCImpl, fragmentCImpl, view);
    }
  }

  private static final class ViewCBuilder implements BurnerApplication_HiltComponents.ViewC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private View view;

    private ViewCBuilder(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
        ActivityCImpl activityCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
    }

    @Override
    public ViewCBuilder view(View view) {
      this.view = Preconditions.checkNotNull(view);
      return this;
    }

    @Override
    public BurnerApplication_HiltComponents.ViewC build() {
      Preconditions.checkBuilderRequirement(view, View.class);
      return new ViewCImpl(singletonCImpl, activityRetainedCImpl, activityCImpl, view);
    }
  }

  private static final class ViewModelCBuilder implements BurnerApplication_HiltComponents.ViewModelC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private SavedStateHandle savedStateHandle;

    private ViewModelLifecycle viewModelLifecycle;

    private ViewModelCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
    }

    @Override
    public ViewModelCBuilder savedStateHandle(SavedStateHandle handle) {
      this.savedStateHandle = Preconditions.checkNotNull(handle);
      return this;
    }

    @Override
    public ViewModelCBuilder viewModelLifecycle(ViewModelLifecycle viewModelLifecycle) {
      this.viewModelLifecycle = Preconditions.checkNotNull(viewModelLifecycle);
      return this;
    }

    @Override
    public BurnerApplication_HiltComponents.ViewModelC build() {
      Preconditions.checkBuilderRequirement(savedStateHandle, SavedStateHandle.class);
      Preconditions.checkBuilderRequirement(viewModelLifecycle, ViewModelLifecycle.class);
      return new ViewModelCImpl(singletonCImpl, activityRetainedCImpl, savedStateHandle, viewModelLifecycle);
    }
  }

  private static final class ServiceCBuilder implements BurnerApplication_HiltComponents.ServiceC.Builder {
    private final SingletonCImpl singletonCImpl;

    private Service service;

    private ServiceCBuilder(SingletonCImpl singletonCImpl) {
      this.singletonCImpl = singletonCImpl;
    }

    @Override
    public ServiceCBuilder service(Service service) {
      this.service = Preconditions.checkNotNull(service);
      return this;
    }

    @Override
    public BurnerApplication_HiltComponents.ServiceC build() {
      Preconditions.checkBuilderRequirement(service, Service.class);
      return new ServiceCImpl(singletonCImpl, service);
    }
  }

  private static final class ViewWithFragmentCImpl extends BurnerApplication_HiltComponents.ViewWithFragmentC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final FragmentCImpl fragmentCImpl;

    private final ViewWithFragmentCImpl viewWithFragmentCImpl = this;

    private ViewWithFragmentCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl,
        FragmentCImpl fragmentCImpl, View viewParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
      this.fragmentCImpl = fragmentCImpl;


    }
  }

  private static final class FragmentCImpl extends BurnerApplication_HiltComponents.FragmentC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final FragmentCImpl fragmentCImpl = this;

    private FragmentCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl,
        Fragment fragmentParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;


    }

    @Override
    public DefaultViewModelFactories.InternalFactoryFactory getHiltInternalFactoryFactory() {
      return activityCImpl.getHiltInternalFactoryFactory();
    }

    @Override
    public ViewWithFragmentComponentBuilder viewWithFragmentComponentBuilder() {
      return new ViewWithFragmentCBuilder(singletonCImpl, activityRetainedCImpl, activityCImpl, fragmentCImpl);
    }
  }

  private static final class ViewCImpl extends BurnerApplication_HiltComponents.ViewC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final ViewCImpl viewCImpl = this;

    private ViewCImpl(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
        ActivityCImpl activityCImpl, View viewParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;


    }
  }

  private static final class ActivityCImpl extends BurnerApplication_HiltComponents.ActivityC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl = this;

    private ActivityCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, Activity activityParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;


    }

    @Override
    public void injectMainActivity(MainActivity arg0) {
    }

    @Override
    public DefaultViewModelFactories.InternalFactoryFactory getHiltInternalFactoryFactory() {
      return DefaultViewModelFactories_InternalFactoryFactory_Factory.newInstance(getViewModelKeys(), new ViewModelCBuilder(singletonCImpl, activityRetainedCImpl));
    }

    @Override
    public Set<String> getViewModelKeys() {
      return ImmutableSet.<String>of(AccountDetailsViewModel_HiltModules_KeyModule_ProvideFactory.provide(), AuthViewModel_HiltModules_KeyModule_ProvideFactory.provide(), BookmarksViewModel_HiltModules_KeyModule_ProvideFactory.provide(), EventDetailViewModel_HiltModules_KeyModule_ProvideFactory.provide(), ExploreViewModel_HiltModules_KeyModule_ProvideFactory.provide(), NavigationViewModel_HiltModules_KeyModule_ProvideFactory.provide(), NotificationSettingsViewModel_HiltModules_KeyModule_ProvideFactory.provide(), OnboardingViewModel_HiltModules_KeyModule_ProvideFactory.provide(), PaymentSettingsViewModel_HiltModules_KeyModule_ProvideFactory.provide(), SearchViewModel_HiltModules_KeyModule_ProvideFactory.provide(), SettingsViewModel_HiltModules_KeyModule_ProvideFactory.provide(), TicketDetailViewModel_HiltModules_KeyModule_ProvideFactory.provide(), TicketPurchaseViewModel_HiltModules_KeyModule_ProvideFactory.provide(), TicketsViewModel_HiltModules_KeyModule_ProvideFactory.provide());
    }

    @Override
    public ViewModelComponentBuilder getViewModelComponentBuilder() {
      return new ViewModelCBuilder(singletonCImpl, activityRetainedCImpl);
    }

    @Override
    public FragmentComponentBuilder fragmentComponentBuilder() {
      return new FragmentCBuilder(singletonCImpl, activityRetainedCImpl, activityCImpl);
    }

    @Override
    public ViewComponentBuilder viewComponentBuilder() {
      return new ViewCBuilder(singletonCImpl, activityRetainedCImpl, activityCImpl);
    }
  }

  private static final class ViewModelCImpl extends BurnerApplication_HiltComponents.ViewModelC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ViewModelCImpl viewModelCImpl = this;

    private Provider<AccountDetailsViewModel> accountDetailsViewModelProvider;

    private Provider<AuthViewModel> authViewModelProvider;

    private Provider<BookmarksViewModel> bookmarksViewModelProvider;

    private Provider<EventDetailViewModel> eventDetailViewModelProvider;

    private Provider<ExploreViewModel> exploreViewModelProvider;

    private Provider<NavigationViewModel> navigationViewModelProvider;

    private Provider<NotificationSettingsViewModel> notificationSettingsViewModelProvider;

    private Provider<OnboardingViewModel> onboardingViewModelProvider;

    private Provider<PaymentSettingsViewModel> paymentSettingsViewModelProvider;

    private Provider<SearchViewModel> searchViewModelProvider;

    private Provider<SettingsViewModel> settingsViewModelProvider;

    private Provider<TicketDetailViewModel> ticketDetailViewModelProvider;

    private Provider<TicketPurchaseViewModel> ticketPurchaseViewModelProvider;

    private Provider<TicketsViewModel> ticketsViewModelProvider;

    private ViewModelCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, SavedStateHandle savedStateHandleParam,
        ViewModelLifecycle viewModelLifecycleParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;

      initialize(savedStateHandleParam, viewModelLifecycleParam);

    }

    @SuppressWarnings("unchecked")
    private void initialize(final SavedStateHandle savedStateHandleParam,
        final ViewModelLifecycle viewModelLifecycleParam) {
      this.accountDetailsViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 0);
      this.authViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 1);
      this.bookmarksViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 2);
      this.eventDetailViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 3);
      this.exploreViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 4);
      this.navigationViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 5);
      this.notificationSettingsViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 6);
      this.onboardingViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 7);
      this.paymentSettingsViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 8);
      this.searchViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 9);
      this.settingsViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 10);
      this.ticketDetailViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 11);
      this.ticketPurchaseViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 12);
      this.ticketsViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 13);
    }

    @Override
    public Map<String, Provider<ViewModel>> getHiltViewModelMap() {
      return ImmutableMap.<String, Provider<ViewModel>>builderWithExpectedSize(14).put("com.burner.app.ui.screens.settings.AccountDetailsViewModel", ((Provider) accountDetailsViewModelProvider)).put("com.burner.app.ui.screens.auth.AuthViewModel", ((Provider) authViewModelProvider)).put("com.burner.app.ui.screens.bookmarks.BookmarksViewModel", ((Provider) bookmarksViewModelProvider)).put("com.burner.app.ui.screens.explore.EventDetailViewModel", ((Provider) eventDetailViewModelProvider)).put("com.burner.app.ui.screens.explore.ExploreViewModel", ((Provider) exploreViewModelProvider)).put("com.burner.app.navigation.NavigationViewModel", ((Provider) navigationViewModelProvider)).put("com.burner.app.ui.screens.settings.NotificationSettingsViewModel", ((Provider) notificationSettingsViewModelProvider)).put("com.burner.app.ui.screens.onboarding.OnboardingViewModel", ((Provider) onboardingViewModelProvider)).put("com.burner.app.ui.screens.settings.PaymentSettingsViewModel", ((Provider) paymentSettingsViewModelProvider)).put("com.burner.app.ui.screens.search.SearchViewModel", ((Provider) searchViewModelProvider)).put("com.burner.app.ui.screens.settings.SettingsViewModel", ((Provider) settingsViewModelProvider)).put("com.burner.app.ui.screens.tickets.TicketDetailViewModel", ((Provider) ticketDetailViewModelProvider)).put("com.burner.app.ui.screens.tickets.TicketPurchaseViewModel", ((Provider) ticketPurchaseViewModelProvider)).put("com.burner.app.ui.screens.tickets.TicketsViewModel", ((Provider) ticketsViewModelProvider)).build();
    }

    private static final class SwitchingProvider<T> implements Provider<T> {
      private final SingletonCImpl singletonCImpl;

      private final ActivityRetainedCImpl activityRetainedCImpl;

      private final ViewModelCImpl viewModelCImpl;

      private final int id;

      SwitchingProvider(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
          ViewModelCImpl viewModelCImpl, int id) {
        this.singletonCImpl = singletonCImpl;
        this.activityRetainedCImpl = activityRetainedCImpl;
        this.viewModelCImpl = viewModelCImpl;
        this.id = id;
      }

      @SuppressWarnings("unchecked")
      @Override
      public T get() {
        switch (id) {
          case 0: // com.burner.app.ui.screens.settings.AccountDetailsViewModel 
          return (T) new AccountDetailsViewModel(singletonCImpl.authServiceProvider.get(), singletonCImpl.preferencesRepositoryProvider.get());

          case 1: // com.burner.app.ui.screens.auth.AuthViewModel 
          return (T) new AuthViewModel(singletonCImpl.authServiceProvider.get());

          case 2: // com.burner.app.ui.screens.bookmarks.BookmarksViewModel 
          return (T) new BookmarksViewModel(singletonCImpl.bookmarkRepositoryProvider.get(), singletonCImpl.eventRepositoryProvider.get(), singletonCImpl.authServiceProvider.get());

          case 3: // com.burner.app.ui.screens.explore.EventDetailViewModel 
          return (T) new EventDetailViewModel(singletonCImpl.eventRepositoryProvider.get(), singletonCImpl.bookmarkRepositoryProvider.get(), singletonCImpl.ticketRepositoryProvider.get());

          case 4: // com.burner.app.ui.screens.explore.ExploreViewModel 
          return (T) new ExploreViewModel(singletonCImpl.eventRepositoryProvider.get(), singletonCImpl.bookmarkRepositoryProvider.get(), singletonCImpl.preferencesRepositoryProvider.get(), singletonCImpl.tagRepositoryProvider.get());

          case 5: // com.burner.app.navigation.NavigationViewModel 
          return (T) new NavigationViewModel(singletonCImpl.preferencesRepositoryProvider.get(), singletonCImpl.authServiceProvider.get());

          case 6: // com.burner.app.ui.screens.settings.NotificationSettingsViewModel 
          return (T) new NotificationSettingsViewModel(singletonCImpl.preferencesRepositoryProvider.get());

          case 7: // com.burner.app.ui.screens.onboarding.OnboardingViewModel 
          return (T) new OnboardingViewModel(singletonCImpl.preferencesRepositoryProvider.get(), singletonCImpl.tagRepositoryProvider.get(), singletonCImpl.eventRepositoryProvider.get(), ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          case 8: // com.burner.app.ui.screens.settings.PaymentSettingsViewModel 
          return (T) new PaymentSettingsViewModel(singletonCImpl.paymentServiceProvider.get());

          case 9: // com.burner.app.ui.screens.search.SearchViewModel 
          return (T) new SearchViewModel(singletonCImpl.eventRepositoryProvider.get(), singletonCImpl.bookmarkRepositoryProvider.get(), singletonCImpl.preferencesRepositoryProvider.get());

          case 10: // com.burner.app.ui.screens.settings.SettingsViewModel 
          return (T) new SettingsViewModel(singletonCImpl.authServiceProvider.get(), singletonCImpl.preferencesRepositoryProvider.get());

          case 11: // com.burner.app.ui.screens.tickets.TicketDetailViewModel 
          return (T) new TicketDetailViewModel(singletonCImpl.ticketRepositoryProvider.get());

          case 12: // com.burner.app.ui.screens.tickets.TicketPurchaseViewModel 
          return (T) new TicketPurchaseViewModel(singletonCImpl.eventRepositoryProvider.get(), singletonCImpl.paymentServiceProvider.get());

          case 13: // com.burner.app.ui.screens.tickets.TicketsViewModel 
          return (T) new TicketsViewModel(singletonCImpl.ticketRepositoryProvider.get(), singletonCImpl.eventRepositoryProvider.get(), singletonCImpl.authServiceProvider.get());

          default: throw new AssertionError(id);
        }
      }
    }
  }

  private static final class ActivityRetainedCImpl extends BurnerApplication_HiltComponents.ActivityRetainedC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl = this;

    private Provider<ActivityRetainedLifecycle> provideActivityRetainedLifecycleProvider;

    private ActivityRetainedCImpl(SingletonCImpl singletonCImpl) {
      this.singletonCImpl = singletonCImpl;

      initialize();

    }

    @SuppressWarnings("unchecked")
    private void initialize() {
      this.provideActivityRetainedLifecycleProvider = DoubleCheck.provider(new SwitchingProvider<ActivityRetainedLifecycle>(singletonCImpl, activityRetainedCImpl, 0));
    }

    @Override
    public ActivityComponentBuilder activityComponentBuilder() {
      return new ActivityCBuilder(singletonCImpl, activityRetainedCImpl);
    }

    @Override
    public ActivityRetainedLifecycle getActivityRetainedLifecycle() {
      return provideActivityRetainedLifecycleProvider.get();
    }

    private static final class SwitchingProvider<T> implements Provider<T> {
      private final SingletonCImpl singletonCImpl;

      private final ActivityRetainedCImpl activityRetainedCImpl;

      private final int id;

      SwitchingProvider(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
          int id) {
        this.singletonCImpl = singletonCImpl;
        this.activityRetainedCImpl = activityRetainedCImpl;
        this.id = id;
      }

      @SuppressWarnings("unchecked")
      @Override
      public T get() {
        switch (id) {
          case 0: // dagger.hilt.android.ActivityRetainedLifecycle 
          return (T) ActivityRetainedComponentManager_LifecycleModule_ProvideActivityRetainedLifecycleFactory.provideActivityRetainedLifecycle();

          default: throw new AssertionError(id);
        }
      }
    }
  }

  private static final class ServiceCImpl extends BurnerApplication_HiltComponents.ServiceC {
    private final SingletonCImpl singletonCImpl;

    private final ServiceCImpl serviceCImpl = this;

    private ServiceCImpl(SingletonCImpl singletonCImpl, Service serviceParam) {
      this.singletonCImpl = singletonCImpl;


    }
  }

  private static final class SingletonCImpl extends BurnerApplication_HiltComponents.SingletonC {
    private final ApplicationContextModule applicationContextModule;

    private final SingletonCImpl singletonCImpl = this;

    private Provider<FirebaseAuth> provideFirebaseAuthProvider;

    private Provider<FirebaseFirestore> provideFirebaseFirestoreProvider;

    private Provider<AuthService> authServiceProvider;

    private Provider<DataStore<Preferences>> provideDataStoreProvider;

    private Provider<PreferencesRepository> preferencesRepositoryProvider;

    private Provider<BookmarkRepository> bookmarkRepositoryProvider;

    private Provider<EventRepository> eventRepositoryProvider;

    private Provider<TicketRepository> ticketRepositoryProvider;

    private Provider<TagRepository> tagRepositoryProvider;

    private Provider<PaymentService> paymentServiceProvider;

    private SingletonCImpl(ApplicationContextModule applicationContextModuleParam) {
      this.applicationContextModule = applicationContextModuleParam;
      initialize(applicationContextModuleParam);

    }

    @SuppressWarnings("unchecked")
    private void initialize(final ApplicationContextModule applicationContextModuleParam) {
      this.provideFirebaseAuthProvider = DoubleCheck.provider(new SwitchingProvider<FirebaseAuth>(singletonCImpl, 1));
      this.provideFirebaseFirestoreProvider = DoubleCheck.provider(new SwitchingProvider<FirebaseFirestore>(singletonCImpl, 2));
      this.authServiceProvider = DoubleCheck.provider(new SwitchingProvider<AuthService>(singletonCImpl, 0));
      this.provideDataStoreProvider = DoubleCheck.provider(new SwitchingProvider<DataStore<Preferences>>(singletonCImpl, 4));
      this.preferencesRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<PreferencesRepository>(singletonCImpl, 3));
      this.bookmarkRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<BookmarkRepository>(singletonCImpl, 5));
      this.eventRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<EventRepository>(singletonCImpl, 6));
      this.ticketRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<TicketRepository>(singletonCImpl, 7));
      this.tagRepositoryProvider = DoubleCheck.provider(new SwitchingProvider<TagRepository>(singletonCImpl, 8));
      this.paymentServiceProvider = DoubleCheck.provider(new SwitchingProvider<PaymentService>(singletonCImpl, 9));
    }

    @Override
    public void injectBurnerApplication(BurnerApplication arg0) {
    }

    @Override
    public Set<Boolean> getDisableFragmentGetContextFix() {
      return ImmutableSet.<Boolean>of();
    }

    @Override
    public ActivityRetainedComponentBuilder retainedComponentBuilder() {
      return new ActivityRetainedCBuilder(singletonCImpl);
    }

    @Override
    public ServiceComponentBuilder serviceComponentBuilder() {
      return new ServiceCBuilder(singletonCImpl);
    }

    private static final class SwitchingProvider<T> implements Provider<T> {
      private final SingletonCImpl singletonCImpl;

      private final int id;

      SwitchingProvider(SingletonCImpl singletonCImpl, int id) {
        this.singletonCImpl = singletonCImpl;
        this.id = id;
      }

      @SuppressWarnings("unchecked")
      @Override
      public T get() {
        switch (id) {
          case 0: // com.burner.app.services.AuthService 
          return (T) new AuthService(singletonCImpl.provideFirebaseAuthProvider.get(), singletonCImpl.provideFirebaseFirestoreProvider.get(), ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          case 1: // com.google.firebase.auth.FirebaseAuth 
          return (T) AppModule_ProvideFirebaseAuthFactory.provideFirebaseAuth();

          case 2: // com.google.firebase.firestore.FirebaseFirestore 
          return (T) AppModule_ProvideFirebaseFirestoreFactory.provideFirebaseFirestore();

          case 3: // com.burner.app.data.repository.PreferencesRepository 
          return (T) new PreferencesRepository(singletonCImpl.provideDataStoreProvider.get());

          case 4: // androidx.datastore.core.DataStore<androidx.datastore.preferences.core.Preferences> 
          return (T) AppModule_ProvideDataStoreFactory.provideDataStore(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          case 5: // com.burner.app.data.repository.BookmarkRepository 
          return (T) new BookmarkRepository(singletonCImpl.provideFirebaseFirestoreProvider.get(), singletonCImpl.authServiceProvider.get());

          case 6: // com.burner.app.data.repository.EventRepository 
          return (T) new EventRepository(singletonCImpl.provideFirebaseFirestoreProvider.get());

          case 7: // com.burner.app.data.repository.TicketRepository 
          return (T) new TicketRepository(singletonCImpl.provideFirebaseFirestoreProvider.get(), singletonCImpl.authServiceProvider.get(), singletonCImpl.eventRepositoryProvider.get());

          case 8: // com.burner.app.data.repository.TagRepository 
          return (T) new TagRepository(singletonCImpl.provideFirebaseFirestoreProvider.get());

          case 9: // com.burner.app.services.PaymentService 
          return (T) new PaymentService(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          default: throw new AssertionError(id);
        }
      }
    }
  }
}
