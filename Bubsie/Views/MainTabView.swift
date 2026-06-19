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
        case .account:     return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .home:        return NSLocalizedString("tab.home", comment: "")
        case .generations: return NSLocalizedString("tab.generations", comment: "")
        case .chatEdit:    return NSLocalizedString("tab.bubsieai", comment: "")
        case .account:     return NSLocalizedString("tab.profile", comment: "")
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab: BubsieTab = .home
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionManager: SubscriptionsManager
    @StateObject private var auth = AuthManager.shared
    @StateObject private var appState = AppState.shared

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
            if !appState.hideTabBar {
                LiquidNavigationBar(selectedTab: $selectedTab)
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

struct LiquidNavigationBar: View {
    @Binding var selectedTab: BubsieTab

    private let tabs = BubsieTab.allCases
    private let sideInset: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let shape = LiquidSquircle(skew: 0)
            let contentWidth = proxy.size.width - (sideInset * 2)
            let itemWidth = contentWidth / CGFloat(max(tabs.count, 1))
            let selectedIndex = CGFloat(tabs.firstIndex(of: selectedTab) ?? 0)
            let blobX = sideInset + (itemWidth * selectedIndex) + (itemWidth / 2)

            ZStack {
                // MARK: Liquid Glass base
                shape
                    .fill(.ultraThinMaterial)

                // MARK: Top glass reflection
                shape
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.55), location: 0.0),
                                .init(color: .white.opacity(0.18), location: 0.30),
                                .init(color: .clear, location: 0.65)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )

                // MARK: Bottom edge tint
                shape
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.0),
                                .init(color: .black.opacity(0.05), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1.0
                    )
                    .blendMode(.multiply)

                // MARK: Selected tab blob
                LiquidBlob()
                    .frame(width: itemWidth * 0.95, height: 58)
                    .position(x: blobX, y: proxy.size.height / 2)
                    .animation(.interpolatingSpring(stiffness: 280, damping: 26), value: selectedTab)

                HStack(spacing: 0) {
                    ForEach(tabs, id: \.self) { tab in
                        Button {
                            withAnimation(.interpolatingSpring(stiffness: 280, damping: 26)) {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .symbolRenderingMode(.palette)
                                    .foregroundStyle(
                                        selectedTab == tab ? Color(hex: "5C3A2E") : Color(hex: "634B44"),
                                        selectedTab == tab ? Color.white.opacity(0.85) : Color.clear
                                    )

                                Text(tab.label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(selectedTab == tab ? Color(hex: "5C3A2E") : Color(hex: "6A5049"))
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, minHeight: 62)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(tab.label)
                    }
                }
                .padding(.horizontal, sideInset)
            }
            .clipShape(shape)
            .shadow(color: .black.opacity(0.10), radius: 24, x: 0, y: 12)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
        .frame(height: 82)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

private struct LiquidBlob: View {
    var body: some View {
        ZStack {
            Capsule()
                .fill(.white.opacity(0.32))

            // Inner top highlight
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(0.45),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .padding(1)
        }
        .blur(radius: 0.5)
    }
}

private struct LiquidSquircle: InsettableShape {
    var skew: CGFloat
    var insetAmount: CGFloat = 0

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let base = min(rect.width, rect.height) * 0.42
        let tl = max(8, base + (skew * 2))
        let tr = max(8, base - (skew * 2))
        let br = max(8, base + 1)
        let bl = max(8, base - 3)

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + tl, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - tr, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + tr),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - br))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - br, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + bl, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - bl),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + tl))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + tl, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    MainTabView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
