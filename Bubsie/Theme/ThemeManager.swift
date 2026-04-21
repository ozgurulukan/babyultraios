import SwiftUI

// MARK: - Bubsie Design System
struct Bubsie {
    // MARK: Core Accent Colors
    /// Primary accent — deep violet #7C3AED
    static let accent      = Color(hex: "7C3AED")
    /// Secondary accent — magenta-pink #EC4899
    static let accentRose  = Color(hex: "EC4899")

    // MARK: Surface / Background
    static let bg            = Color(hex: "0A0A0F")
    static let card          = Color(hex: "141422")
    static let surface       = Color(hex: "1C1C2E")
    static let textPrimary   = Color.white
    static let textSecondary = Color(hex: "8E8EA0")

    // MARK: Corner Radius
    static let cardRadius:   CGFloat = 20
    static let buttonRadius: CGFloat = 14
    static let pillRadius:   CGFloat = 100
    static let smallRadius:  CGFloat = 12

    // MARK: Spacing
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48

    // MARK: - Gradient Helpers

    /// Primary gradient: violet → pink
    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentRose],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Horizontal progress gradient
    static var progressGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentRose],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Subtle tinted fill for selected containers
    static var accentFill: LinearGradient {
        LinearGradient(
            colors: [accent.opacity(0.15), accentRose.opacity(0.08)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Angular gradient for spinner arcs
    static var spinnerGradient: AngularGradient {
        AngularGradient(
            colors: [accent.opacity(0.0), accent, accentRose],
            center: .center
        )
    }
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:  (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:     Double(r) / 255,
            green:   Double(g) / 255,
            blue:    Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Modifiers
extension View {
    func bubsieCard() -> some View {
        self
            .background(Bubsie.card)
            .clipShape(RoundedRectangle(cornerRadius: Bubsie.cardRadius))
    }

    func glassMorphism(radius: CGFloat = 20) -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.85))
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    func accentGlow(radius: CGFloat = 8) -> some View {
        self.shadow(color: Bubsie.accent.opacity(0.45), radius: radius, y: 2)
            .shadow(color: Bubsie.accentRose.opacity(0.25), radius: radius * 1.5, y: 0)
    }

    func accentCapsule() -> some View {
        self.background(Bubsie.accentGradient).clipShape(Capsule())
    }

    func accentRounded(radius: CGFloat = Bubsie.buttonRadius) -> some View {
        self.background(Bubsie.accentGradient)
            .clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - Animated Mesh Background (blob-based for smooth SwiftUI animation)
// Uses the exact same color palette as PremiumGradientButton mesh fill
struct AnimatedMeshBG: View {
    @State private var move = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Bubsie.bg

                // Mauve-rose (same as button B8547A)
                Ellipse()
                    .fill(Color(hex: "B8547A"))
                    .frame(width: w * 0.85, height: w * 0.55)
                    .blur(radius: 100)
                    .opacity(0.18)
                    .offset(
                        x: move ? -w * 0.22 : -w * 0.14,
                        y: -h * 0.32
                    )

                // Sky blue (same as button 4CC2F1)
                Ellipse()
                    .fill(Color(hex: "4CC2F1"))
                    .frame(width: w * 0.8, height: w * 0.5)
                    .blur(radius: 95)
                    .opacity(0.15)
                    .offset(
                        x: move ? w * 0.22 : w * 0.14,
                        y: -h * 0.34
                    )

                // Purple (same as button 9B59D4)
                Ellipse()
                    .fill(Color(hex: "9B59D4"))
                    .frame(width: w * 0.9, height: w * 0.6)
                    .blur(radius: 95)
                    .opacity(0.16)
                    .offset(
                        x: move ? -w * 0.02 : w * 0.06,
                        y: move ? -h * 0.28 : -h * 0.33
                    )

                // Deep magenta-pink (same as button D946A8)
                Ellipse()
                    .fill(Color(hex: "D946A8"))
                    .frame(width: w * 0.55, height: w * 0.4)
                    .blur(radius: 85)
                    .opacity(0.12)
                    .offset(
                        x: move ? w * 0.05 : -w * 0.08,
                        y: -h * 0.38
                    )

                // Fade to solid bg
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .clear, location: 0.28),
                        .init(color: Bubsie.bg.opacity(0.55), location: 0.40),
                        .init(color: Bubsie.bg, location: 0.50),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                move = true
            }
        }
    }
}

// MARK: - Gradient Stroke Shape
struct GradientBorder: ViewModifier {
    var cornerRadius: CGFloat
    var lineWidth: CGFloat = 1

    func body(content: Content) -> some View {
        content.overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(Bubsie.accentGradient, lineWidth: lineWidth)
        )
    }
}

extension View {
    func gradientBorder(cornerRadius: CGFloat, lineWidth: CGFloat = 1) -> some View {
        self.modifier(GradientBorder(cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}
