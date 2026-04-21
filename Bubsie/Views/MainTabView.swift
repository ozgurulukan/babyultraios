import SwiftUI

// MARK: - Tab Enum
enum BubsieTab: String, CaseIterable {
    case home        = "home"
    case generations = "generations"
    case chatEdit    = "chatEdit"
    case account     = "account"

    var icon: String {
        switch self {
        case .home:        return "house.fill"
        case .generations: return "square.grid.2x2.fill"
        case .chatEdit:    return "message.fill"
        case .account:     return "person.crop.circle.fill"
        }
    }

    var label: String {
        switch self {
        case .home:        return "Home"
        case .generations: return "Generations"
        case .chatEdit:    return "BubsieAI"
        case .account:     return "Profile"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: BubsieTab = .home
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionManager: SubscriptionsManager

    var body: some View {
        ZStack {
            Group {
                if selectedTab == .home || selectedTab == .account || selectedTab == .chatEdit {
                    Color(hex: "F6ECE6")
                        .ignoresSafeArea()
                } else {
                    AnimatedMeshBG()
                }
            }

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
            BubsieTabBar(selectedTab: $selectedTab)
        }
        .preferredColorScheme(selectedTab == .account || selectedTab == .chatEdit ? .light : .dark)
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Liquid Glass Tab Bar
struct BubsieTabBar: View {
    @Binding var selectedTab: BubsieTab

    var body: some View {
        HStack(spacing: 8) {
            ForEach(BubsieTab.allCases, id: \.self) { tab in
                BubsieTabButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.clear)
                .background(.regularMaterial.opacity(0.9), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(
                            .white.opacity(0.22),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 2)
        .padding(.horizontal, 12)
        .padding(.bottom, 4)
    }
}

// MARK: - Individual Tab Button
struct BubsieTabButton: View {
    let tab: BubsieTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "F0D8CF"))
                            .frame(width: 40, height: 40)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color(hex: "7E3A24") : Color(hex: "6A5B55"))
                }
                .frame(width: 44, height: 44)

                Text(tab.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(isSelected ? Color(hex: "5E2A1A") : Color(hex: "5F514C"))
            }
            .frame(maxWidth: .infinity, minHeight: 58)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    MainTabView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
