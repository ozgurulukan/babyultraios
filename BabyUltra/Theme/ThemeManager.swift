import SwiftUI

// MARK: - BabyUltra Design System
struct BabyUltra {
    // MARK: Core Accent Colors
    /// Primary accent — vibrant warm pink
    static let accent      = Color(hex: "FF5E7E")
    /// Secondary accent — soft peach/rose
    static let accentRose  = Color(hex: "FF9E80")

    // MARK: Surface / Background
    static let bg            = Color(hex: "FFF3F1") // Light peachy white
    static let card          = Color.white
    static let surface       = Color.white.opacity(0.85)
    static let textPrimary   = Color(hex: "2D2422") // Dark brown/gray for readability on light bg
    static let textSecondary = Color(hex: "8D7F7A") // Soft gray/brown

    // MARK: Corner Radius
    static let cardRadius:   CGFloat = 24
    static let buttonRadius: CGFloat = 20
    static let pillRadius:   CGFloat = 100
    static let smallRadius:  CGFloat = 16

    // MARK: Spacing
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48

    // MARK: - Gradient Helpers

    /// Primary gradient: vibrant pink → soft magenta
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
            colors: [accent.opacity(0.12), accentRose.opacity(0.06)],
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
    func babyultraCard() -> some View {
        self
            .background(BabyUltra.card)
            .clipShape(RoundedRectangle(cornerRadius: BabyUltra.cardRadius, style: .continuous))
    }

    func glassMorphism(radius: CGFloat = 24) -> some View {
        self
            .background(.regularMaterial)
            .background(Color.white.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
            )
            .shadow(color: Color(hex: "FF88A8").opacity(0.12), radius: 16, x: 0, y: 8)
    }

    func accentGlow(radius: CGFloat = 8) -> some View {
        self.shadow(color: BabyUltra.accent.opacity(0.3), radius: radius, y: 4)
            .shadow(color: BabyUltra.accentRose.opacity(0.2), radius: radius * 1.5, y: 0)
    }

    func accentCapsule() -> some View {
        self.background(BabyUltra.accentGradient).clipShape(Capsule())
    }

    func accentRounded(radius: CGFloat = BabyUltra.buttonRadius) -> some View {
        self.background(BabyUltra.accentGradient)
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
                // Light peachy background
                BabyUltra.bg

                // Soft Pink
                Ellipse()
                    .fill(Color(hex: "FFC5D9"))
                    .frame(width: w * 0.9, height: w * 0.7)
                    .blur(radius: 80)
                    .opacity(0.7)
                    .offset(
                        x: move ? -w * 0.2 : w * 0.1,
                        y: -h * 0.3
                    )

                // Warm Peach
                Ellipse()
                    .fill(Color(hex: "FFDAB9"))
                    .frame(width: w * 0.8, height: w * 0.6)
                    .blur(radius: 70)
                    .opacity(0.6)
                    .offset(
                        x: move ? w * 0.25 : -w * 0.1,
                        y: h * 0.1
                    )

                // Bright Magenta/Pink accent
                Ellipse()
                    .fill(Color(hex: "FF69B4"))
                    .frame(width: w * 0.9, height: w * 0.7)
                    .blur(radius: 100)
                    .opacity(0.4)
                    .offset(
                        x: move ? w * 0.1 : -w * 0.2,
                        y: move ? h * 0.3 : h * 0.4
                    )
                
                // Soft White Glow at the top
                Ellipse()
                    .fill(Color.white)
                    .frame(width: w * 0.9, height: w * 0.6)
                    .blur(radius: 60)
                    .opacity(0.8)
                    .offset(
                        x: 0,
                        y: -h * 0.45
                    )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
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
                .stroke(BabyUltra.accentGradient, lineWidth: lineWidth)
        )
    }
}

extension View {
    func gradientBorder(cornerRadius: CGFloat, lineWidth: CGFloat = 1) -> some View {
        self.modifier(GradientBorder(cornerRadius: cornerRadius, lineWidth: lineWidth))
    }
}
