import SwiftUI

// MARK: - Tab Enum
enum BabyUltraTab: String, CaseIterable {
    case home        = "home"
    case generations = "generations"
    case chatEdit    = "chatEdit"
    case account     = "account"

    var icon: String {
        switch self {
        case .home:        return "house.fill"
        case .generations: return "square.grid.2x2.fill"
        case .chatEdit:    return "textformat.abc"
        case .account:     return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .home:        return NSLocalizedString("tab.home", comment: "")
        case .generations: return NSLocalizedString("tab.generations", comment: "")
        case .chatEdit:    return NSLocalizedString("tab.babyultraai", comment: "")
        case .account:     return NSLocalizedString("tab.profile", comment: "")
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: BabyUltraTab = .home
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionManager: SubscriptionsManager
    @StateObject private var auth = AuthManager.shared
    @StateObject private var appState = AppState.shared

    var body: some View {
        ZStack {
            // Global Background from Assets
            Image("bg")
                .resizable()
                .ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:        HomeView()
                case .generations: GenerationsView()
                case .chatEdit:    ChatEditView()
                case .account:     AccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !appState.hideTabBar {
                PillNavigationBar(selectedTab: $selectedTab)
            }
        }
        .ignoresSafeArea(.keyboard)
        .overlay {
            if auth.isDeviceBanned {
                DeviceBannedView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .task {
            // Delay authorization request slightly to ensure view is active and ready
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            _ = await TrackingManager.shared.requestTrackingPermission()
        }
    }
}

struct PillNavigationBar: View {
    @Binding var selectedTab: BabyUltraTab

    private let tabs = BabyUltraTab.allCases

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            if selectedTab == tab {
                                Circle()
                                    .fill(BabyUltra.accent)
                                    .frame(width: 44, height: 44)
                                    .shadow(color: BabyUltra.accent.opacity(0.3), radius: 8, y: 4)
                            }
                            
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(selectedTab == tab ? .white : BabyUltra.textSecondary.opacity(0.6))
                        }
                        .frame(height: 44)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background {
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.5))
                Capsule()
                    .fill(.regularMaterial)
            }
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.9), lineWidth: 1.5)
            )
            .shadow(color: BabyUltra.accentRose.opacity(0.15), radius: 20, y: 10)
        }
        .frame(height: 72)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }
}

#Preview {
    MainTabView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
