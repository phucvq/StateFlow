import SwiftUI

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .home
    @State private var showSplash = true
    @ObservedObject private var locManager = LocalizationManager.shared

    var body: some View {
        ZStack {
            // Main content loads underneath — no jank when splash fades out
            Group {
                if !hasCompletedOnboarding {
                    OnboardingScreen(isPresented: $hasCompletedOnboarding)
                } else {
                    MainTabView(selectedTab: $selectedTab)
                }
            }
            .id(locManager.currentLanguage)

            // Splash overlay — auto-dismisses after 1.5 s with fade
            if showSplash {
                SplashScreen()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.4)) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Tab Definition
enum AppTab: Int, CaseIterable {
    case home = 0
    case analytics = 1
    case settings = 2

    var title: String {
        switch self {
        case .home: return L10n.tabHome
        case .analytics: return L10n.tabStats
        case .settings: return L10n.tabSettings
        }
    }

    var icon: String {
        switch self {
        case .home: return "timer"
        case .analytics: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Binding var selectedTab: AppTab
    @Environment(TimerViewModel.self) private var timerVM
    @Environment(SubscriptionService.self) private var subService
    @Environment(AudioService.self) private var audioService
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeScreen()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.icon) }
                .tag(AppTab.home)

            AnalyticsScreen()
                .tabItem { Label(AppTab.analytics.title, systemImage: AppTab.analytics.icon) }
                .tag(AppTab.analytics)

            SettingsScreen()
                .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.icon) }
                .tag(AppTab.settings)
        }
        .tint(AppColors.amber)
        // Keep TimerViewModel in sync with subscription state
        .onAppear { timerVM.isPremium = subService.isPremium }
        .onChange(of: subService.isPremium) { _, newValue in
            timerVM.isPremium = newValue
        }
        // Recover Live Activity if it was missed while app was in background
        // (e.g. auto-start countdown fired while app was inactive).
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                timerVM.handleForeground()
                // Bug fix: resume audio if app was killed/backgrounded during an active session
                if timerVM.isRunning || timerVM.isPaused {
                    audioService.resumeIfNeeded()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [SessionRecord.self, EnergyLog.self], inMemory: true)
        .environment(TimerViewModel())
        .environment(SubscriptionService())
        .environment(AudioService())
}
