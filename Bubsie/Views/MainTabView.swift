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
            LiquidNavigationBar(selectedTab: $selectedTab)
        }
        .preferredColorScheme(selectedTab == .account || selectedTab == .chatEdit ? .light : .dark)
        .ignoresSafeArea(.keyboard)
    }
}

struct LiquidNavigationBar: View {
    @Binding var selectedTab: BubsieTab
    @State private var breathe = false

    private let tabs = BubsieTab.allCases
    private let sideInset: CGFloat = 10

    var body: some View {
        GeometryReader { proxy in
            let shape = LiquidSquircle(skew: breathe ? 1 : 0)
            let contentWidth = proxy.size.width - (sideInset * 2)
            let itemWidth = contentWidth / CGFloat(max(tabs.count, 1))
            let selectedIndex = CGFloat(tabs.firstIndex(of: selectedTab) ?? 0)
            let blobX = sideInset + (itemWidth * selectedIndex) + (itemWidth / 2)

            ZStack {
                LiquidTabBarMesh()
                    .blur(radius: breathe ? 16 : 22)
                    .overlay(.ultraThinMaterial.opacity(0.78))

                LiquidBlob(breathe: breathe)
                    .frame(width: itemWidth * 0.84, height: 54)
                    .position(x: blobX, y: proxy.size.height / 2)
                    .animation(.interpolatingSpring(stiffness: 280, damping: 26), value: selectedTab)
                    .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: breathe)

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
                                        selectedTab == tab ? Color(hex: "7C2A1A") : Color(hex: "634B44"),
                                        selectedTab == tab ? Color.white.opacity(0.88) : Color.clear
                                    )

                                Text(tab.label)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(selectedTab == tab ? Color(hex: "5F2618") : Color(hex: "6A5049"))
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
            .overlay {
                shape
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: .white.opacity(0.65), location: 0),
                                .init(color: .white.opacity(0.24), location: 0.28),
                                .init(color: .white.opacity(0.08), location: 0.58),
                                .init(color: .clear, location: 1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .overlay {
                shape
                    .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
                    .blur(radius: 0.4)
                    .blendMode(.plusLighter)
            }
            .shadow(color: .black.opacity(0.18), radius: 26, x: 0, y: 12)
            .shadow(color: Color(hex: "F98A66").opacity(0.26), radius: 14, x: -8, y: 3)
            .shadow(color: Color(hex: "7B4BD4").opacity(0.2), radius: 18, x: 9, y: 6)
        }
        .frame(height: 82)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .onAppear { breathe = true }
    }
}

private struct LiquidBlob: View {
    let breathe: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "FFD1A9").opacity(0.72),
                            Color(hex: "F27A8E").opacity(0.58),
                            Color(hex: "C47BEF").opacity(0.50)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Circle()
                .fill(Color.white.opacity(0.38))
                .frame(width: 24, height: 24)
                .offset(
                    x: breathe ? 14 : -9,
                    y: breathe ? -7 : 5
                )
        }
        .compositingGroup()
        .blur(radius: breathe ? 8 : 11)
    }
}

private struct LiquidTabBarMesh: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            GeometryReader { _ in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let waveA = Float((sin(t * 0.45) + 1) * 0.5)
                let waveB = Float((cos(t * 0.37) + 1) * 0.5)

                if #available(iOS 18.0, *) {
                    MeshGradient(
                        width: 3,
                        height: 3,
                        points: [
                            .init(0.00, 0.00), .init(0.50 + waveA * 0.08, 0.00), .init(1.00, 0.00),
                            .init(0.00, 0.52 + waveB * 0.08), .init(0.50, 0.50), .init(1.00, 0.45 + waveA * 0.08),
                            .init(0.00, 1.00), .init(0.48 + waveB * 0.07, 1.00), .init(1.00, 1.00)
                        ],
                        colors: [
                            Color(hex: "FFE0B3"), Color(hex: "FFB46D"), Color(hex: "FB856D"),
                            Color(hex: "F694AE"), Color(hex: "F2A56A"), Color(hex: "D178E8"),
                            Color(hex: "FEB246"), Color(hex: "FB856D"), Color(hex: "B56ADB")
                        ]
                    )
                } else {
                    Canvas { context, size in
                        let blobs: [(Color, CGPoint, CGFloat)] = [
                            (Color(hex: "FFB46D"), CGPoint(x: size.width * 0.18, y: size.height * 0.25), size.width * 0.30),
                            (Color(hex: "FB856D"), CGPoint(x: size.width * 0.42, y: size.height * 0.70), size.width * 0.34),
                            (Color(hex: "FEB246"), CGPoint(x: size.width * 0.74, y: size.height * 0.30), size.width * 0.33),
                            (Color(hex: "C47BEF"), CGPoint(x: size.width * 0.86, y: size.height * 0.76), size.width * 0.30)
                        ]

                        for blob in blobs {
                            let rect = CGRect(
                                x: blob.1.x - blob.2 * 0.5,
                                y: blob.1.y - blob.2 * 0.5,
                                width: blob.2,
                                height: blob.2
                            )
                            context.fill(
                                Path(ellipseIn: rect),
                                with: .radialGradient(
                                    Gradient(colors: [blob.0.opacity(0.7), .clear]),
                                    center: blob.1,
                                    startRadius: 0,
                                    endRadius: blob.2 * 0.65
                                )
                            )
                        }
                    }
                    .background(Color(hex: "B56ADB"))
                }
            }
        }
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
