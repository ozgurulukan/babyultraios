import SwiftUI

// MARK: - Shared Mesh Gradient Fill (blob-based, smooth animation)
private struct MeshGradientFill: View {
    @State private var move = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            ZStack {
                Color(hex: "6A3080")

                Ellipse()
                    .fill(Color(hex: "B8547A"))
                    .frame(width: w * 0.7, height: h * 2.2)
                    .blur(radius: 38)
                    .offset(x: move ? -w * 0.18 : -w * 0.28, y: 0)

                Ellipse()
                    .fill(Color(hex: "4CC2F1"))
                    .frame(width: w * 0.55, height: h * 2.0)
                    .blur(radius: 40)
                    .offset(x: move ? w * 0.04 : -w * 0.04, y: 0)

                Ellipse()
                    .fill(Color(hex: "9B59D4"))
                    .frame(width: w * 0.5, height: h * 1.8)
                    .blur(radius: 35)
                    .offset(x: move ? w * 0.12 : w * 0.20, y: 0)

                Ellipse()
                    .fill(Color(hex: "D946A8"))
                    .frame(width: w * 0.6, height: h * 2.0)
                    .blur(radius: 38)
                    .offset(x: move ? w * 0.32 : w * 0.24, y: 0)

                LinearGradient(
                    colors: [.white.opacity(0.07), .clear],
                    startPoint: .top,
                    endPoint: .center
                )
            }
            .clipped()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                move = true
            }
        }
    }
}

// MARK: - Glow layer behind button (same mesh colors, diffused)
private struct MeshGlow: View {
    @State private var move = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width

            ZStack {
                Ellipse()
                    .fill(Color(hex: "B8547A"))
                    .frame(width: w * 0.45, height: 50)
                    .blur(radius: 32)
                    .offset(x: move ? -w * 0.12 : -w * 0.18)

                Ellipse()
                    .fill(Color(hex: "4CC2F1"))
                    .frame(width: w * 0.35, height: 44)
                    .blur(radius: 30)
                    .offset(x: move ? w * 0.02 : -w * 0.04)

                Ellipse()
                    .fill(Color(hex: "9B59D4"))
                    .frame(width: w * 0.4, height: 48)
                    .blur(radius: 34)
                    .offset(x: move ? w * 0.08 : w * 0.14)

                Ellipse()
                    .fill(Color(hex: "D946A8"))
                    .frame(width: w * 0.4, height: 46)
                    .blur(radius: 30)
                    .offset(x: move ? w * 0.22 : w * 0.16)
            }
            .opacity(0.35)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
                move = true
            }
        }
    }
}

// MARK: - Full-width CTA Button
struct PremiumGradientButton: View {
    let text: String
    let icon: String
    let action: () -> Void

    init(
        _ text: String = "Upgrade to Pro",
        icon: String = "sparkles",
        action: @escaping () -> Void = {}
    ) {
        self.text = text
        self.icon = icon
        self.action = action
    }

    var body: some View {
        ZStack {
            // Ambient mesh glow behind the button
            MeshGlow()
                .frame(height: 70)
                .offset(y: 8)

            Button(action: action) {
                HStack(spacing: 6) {
                    Text(text)
                        .font(.system(size: 16, weight: .semibold))
                    Image(systemName: icon)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background { MeshGradientFill() }
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.18), lineWidth: 0.5)
                )
                .overlay(
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.12))
                )
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Compact Pill Variant (for headers)
struct PremiumPill: View {
    let text: String
    let icon: String
    let action: () -> Void

    init(
        _ text: String = "Upgrade Pro",
        icon: String = "sparkles",
        action: @escaping () -> Void = {}
    ) {
        self.text = text
        self.icon = icon
        self.action = action
    }

    var body: some View {
        ZStack {
            MeshGlow()
                .frame(height: 40)
                .offset(y: 4)
                .opacity(0.7)

            Button(action: action) {
                HStack(spacing: 5) {
                    Text(text)
                        .font(.system(size: 12, weight: .bold))
                    Image(systemName: icon)
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background { MeshGradientFill() }
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(.white.opacity(0.15), lineWidth: 0.5)
                )
                .overlay(
                    Capsule()
                        .fill(.ultraThinMaterial.opacity(0.10))
                )
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 30) {
            PremiumPill()
            PremiumGradientButton()
            PremiumGradientButton("Get Started", icon: "arrow.right")
        }
        .padding(.horizontal, 24)
    }
}
