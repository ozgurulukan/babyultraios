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
        case .chatEdit:    return "sparkles"
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
                if #available(iOS 26.0, *) {
                    LiquidTabBar(selectedTab: $selectedTab)
                } else {
                    PillNavigationBar(selectedTab: $selectedTab)
                }
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


@available(iOS 26.0, *)
struct LiquidTabBar: View {
    @Binding var selectedTab: BabyUltraTab
    private let tabs = BabyUltraTab.allCases
    @Namespace private var tabNamespace

    var body: some View {
        // Use GlassEffectContainer with spacing: 40.0 to enable the liquid merge
        GlassEffectContainer(spacing: 40.0) {
            HStack(spacing: 20.0) {
                ForEach(tabs, id: \.self) { tab in
                    Button {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.65, blendDuration: 0.5)) {
                            selectedTab = tab
                        }
                    } label: {
                        ZStack {
                            // The liquid blob for each tab.
                            // Because they are spaced by 20 and the container spacing is 40,
                            // they will organically melt together into a continuous tab bar shape!
                            Capsule()
                                .fill(selectedTab == tab ? BabyUltra.accent : Color.white.opacity(0.8))
                                .frame(width: selectedTab == tab ? 80 : 64, height: 64)
                                .glassEffect()
                            
                            // The icon also gets the glassEffect to merge smoothly
                            Image(systemName: tab.icon)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(selectedTab == tab ? .white : BabyUltra.textSecondary.opacity(0.8))
                                .glassEffect()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(tab.label)
                }
            }
            .padding(.horizontal, 16)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 16, y: 8)
        .padding(.bottom, 24)
    }
}

struct PillNavigationBar: View {
    @Binding var selectedTab: BabyUltraTab

    private let tabs = BabyUltraTab.allCases

    var body: some View {
        HStack(spacing: 20) {
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
                        .frame(width: 44, height: 44)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.label)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.30), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.6), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.08), radius: 16, y: 8)
        }
        .padding(.bottom, 16)
    }
}

#Preview {
    MainTabView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
