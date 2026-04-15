import SwiftUI

// MARK: - Tab Enum
enum LurisTab: String, CaseIterable {
    case home        = "home"
    case generations = "generations"
    case chatEdit    = "chatEdit"
    case account     = "account"

    var icon: String {
        switch self {
        case .home:        return "house.fill"
        case .generations: return "photo.stack.fill"
        case .chatEdit:    return "wand.and.sparkles"
        case .account:     return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .home:        return "Home"
        case .generations: return "Gallery"
        case .chatEdit:    return "Create"
        case .account:     return "Account"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: LurisTab = .home
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionManager: SubscriptionsManager

    var body: some View {
        ZStack(alignment: .bottom) {
            AnimatedMeshBG()

            Group {
                switch selectedTab {
                case .home:        HomeView()
                case .generations: GenerationsView()
                case .chatEdit:    ChatEditView()
                case .account:     AccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Liquid Glass floating tab bar
            LurisTabBar(selectedTab: $selectedTab)
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Liquid Glass Tab Bar
struct LurisTabBar: View {
    @Binding var selectedTab: LurisTab

    private var bottomInset: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 0
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(LurisTab.allCases, id: \.self) { tab in
                LurisTabButton(tab: tab, isSelected: selectedTab == tab) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 10)
        .modifier(LiquidGlassModifier())
        .shadow(color: .black.opacity(0.35), radius: 28, y: 10)
        .padding(.horizontal, 28)
        .padding(.bottom, bottomInset > 0 ? bottomInset + 8 : 24)
    }
}

// MARK: - Liquid Glass / Fallback Modifier
private struct LiquidGlassModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(.regular, in: Capsule())
        } else {
            content
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                )
        }
    }
}

// MARK: - Individual Tab Button
struct LurisTabButton: View {
    let tab: LurisTab
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Luris.accentFill)
                            .frame(width: 48, height: 32)
                            .transition(.scale.combined(with: .opacity))
                    }
                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .thin))
                        .foregroundStyle(
                            isSelected
                                ? LinearGradient(colors: [Luris.accent, Luris.accentRose], startPoint: .topLeading, endPoint: .bottomTrailing)
                                : LinearGradient(colors: [Color.white.opacity(0.45)], startPoint: .leading, endPoint: .trailing)
                        )
                        .scaleEffect(isSelected ? 1.08 : 1.0)
                        .shadow(color: isSelected ? Luris.accentRose.opacity(0.55) : .clear, radius: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                }
                .frame(width: 48, height: 32)

                if isSelected {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Luris.accentGradient)
                        .frame(width: 16, height: 2)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.clear)
                        .frame(width: 16, height: 2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

#Preview {
    MainTabView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
