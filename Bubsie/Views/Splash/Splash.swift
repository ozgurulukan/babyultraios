import SwiftUI

private enum SplashPalette {
    static let background = Color(hex: "F6ECE6")
    static let card = Color(hex: "EFE2DC")
    static let tile = Color(hex: "F4ECE8")
    static let text = Color(hex: "3F2D28")
    static let subtleText = Color(hex: "796B64")
    static let accent = Color(hex: "A66A54")
}

struct Splash: View {
    @State private var isContinue = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 16
    @State private var minimumDisplayTimeReached = false
    @StateObject private var auth = AuthManager.shared

    private func continueIfReady() {
        guard minimumDisplayTimeReached, auth.idToken != nil, !isContinue else { return }
        withAnimation { isContinue = true }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                SplashPalette.background.ignoresSafeArea()

                // Subtle ambient glow behind logo
                SplashPalette.accent
                    .opacity(0.12)
                    .blur(radius: 90)
                    .frame(width: 280, height: 280)
                    .offset(y: -40)

                VStack(spacing: 24) {
                    Spacer()

                    Image("bubsielogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: SplashPalette.accent.opacity(0.35), radius: 36, x: 0, y: 12)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    VStack(spacing: 8) {
                        Text("Bubsie")
                            .font(.system(size: 40, weight: .black, design: .rounded))
                            .foregroundStyle(SplashPalette.text)

                        Text("AI Magic for Your Little One")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(SplashPalette.subtleText)
                            .offset(y: taglineOffset)
                    }
                    .opacity(textOpacity)

                    if auth.isAuthenticating {
                        ProgressView()
                            .tint(SplashPalette.accent)
                            .scaleEffect(1.1)
                            .padding(.top, 16)
                    }

                    Spacer()

                    Image("splashkid")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 280)
                        .padding(.bottom, 20)
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.70, dampingFraction: 0.65)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.55).delay(0.25)) {
                    textOpacity = 1.0
                    taglineOffset = 0
                }

                // En az 2 saniye splash ekranında kal
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    await MainActor.run {
                        minimumDisplayTimeReached = true
                        continueIfReady()
                    }
                }
            }
            .navigationDestination(isPresented: $isContinue) {
                if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                    MainTabView()
                        .navigationBarBackButtonHidden()
                } else {
                    Intro()
                        .navigationBarBackButtonHidden()
                }
            }
            .onChange(of: auth.idToken) { _, newValue in
                if newValue != nil && !isContinue {
                    continueIfReady()
                }
            }
        }
        .environment(\.colorScheme, .light)
    }
}

#Preview {
    Splash()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
