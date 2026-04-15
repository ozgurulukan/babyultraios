import SwiftUI

// MARK: - Intro Page Model
struct IntroPage: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let subtitle: String
    let accentColor: Color
    let gradientStart: Color
    let gradientEnd: Color
}

private let pages: [IntroPage] = [
    .init(
        emoji: "🎬",
        title: "AI Video Generation",
        subtitle: "Create stunning videos powered by the world's most advanced models — Veo 3.1, Sora 2, Kling 2.0, and more.",
        accentColor: Color(hex: "6B00CC"),
        gradientStart: Color(hex: "0D0020"),
        gradientEnd: Color(hex: "2A0066")
    ),
    .init(
        emoji: "✨",
        title: "Photo Magic",
        subtitle: "Remove backgrounds, restore old photos, upscale to 4K, and generate images from text — all in seconds.",
        accentColor: Luris.accent,
        gradientStart: Color(hex: "001A10"),
        gradientEnd: Color(hex: "003322")
    ),
    .init(
        emoji: "⚡️",
        title: "Credit-Powered AI",
        subtitle: "Get 8 free credits to start. Use them across all AI tools, or go Premium for unlimited access.",
        accentColor: Color(hex: "FF9500"),
        gradientStart: Color(hex: "1A1000"),
        gradientEnd: Color(hex: "332200")
    ),
]

// MARK: - Intro View
struct Intro: View {
    @State private var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var navigateToMain = false

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBG()

                VStack(spacing: 0) {
                    // Page tabs
                    TabView(selection: $currentPage) {
                        ForEach(pages.indices, id: \.self) { idx in
                            IntroPageContent(page: pages[idx])
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.4), value: currentPage)

                    // Bottom controls
                    bottomControls
                }
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView()
                    .navigationBarBackButtonHidden()
            }
        }
        .navigationBarBackButtonHidden()
    }

    var bottomControls: some View {
        VStack(spacing: 20) {
            // Page indicator dots
            HStack(spacing: 8) {
                ForEach(pages.indices, id: \.self) { idx in
                    Capsule()
                        .fill(currentPage == idx ? Luris.accent : Luris.surface)
                        .frame(width: currentPage == idx ? 28 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: currentPage)
                }
            }

            // CTA Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    if currentPage < pages.count - 1 {
                        currentPage += 1
                    } else {
                        hasSeenOnboarding = true
                        navigateToMain = true
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                        .font(.system(size: 17, weight: .bold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Luris.accentGradient)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .accentGlow(radius: 10)
            }

            // Skip button (first page only)
            if currentPage == 0 {
                Button {
                    hasSeenOnboarding = true
                    navigateToMain = true
                } label: {
                    Text("Skip for now")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                }
            } else {
                Color.clear.frame(height: 20)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 44)
        .padding(.top, 20)
    }
}

// MARK: - Intro Page Content
struct IntroPageContent: View {
    let page: IntroPage

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero visual
            ZStack {
                // Outer glow ring
                Circle()
                    .fill(page.accentColor.opacity(0.08))
                    .frame(width: 220, height: 220)
                // Middle ring
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.gradientStart, page.gradientEnd],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 170, height: 170)
                // Inner highlight
                Circle()
                    .fill(page.accentColor.opacity(0.08))
                    .frame(width: 120, height: 120)
                // Emoji
                Text(page.emoji)
                    .font(.system(size: 72))
            }
            .padding(.bottom, 48)

            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(page.subtitle)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Luris.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 8)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    Intro()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
