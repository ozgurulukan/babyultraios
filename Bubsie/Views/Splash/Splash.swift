import SwiftUI

struct Splash: View {
    @State private var isContinue = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @StateObject private var auth = AuthManager.shared

    private func continueIfReady() {
        guard auth.idToken != nil, !isContinue else { return }
        withAnimation { isContinue = true }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBG()

                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Bubsie.accentGradient)
                            .frame(width: 100, height: 100)
                            .shadow(color: Bubsie.accentRose.opacity(0.5), radius: 28, y: 10)
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                    VStack(spacing: 4) {
                        Text("Bubsie")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundStyle(.white)
                        Text("AI Video & Photo Studio")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Bubsie.textSecondary)
                    }
                    .opacity(textOpacity)

                    if auth.isAuthenticating {
                        ProgressView()
                            .tint(Bubsie.accent)
                            .padding(.top, 8)
                    }
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                    textOpacity = 1.0
                }

                // On warm launches token may already be restored before onChange is attached.
                continueIfReady()

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
        .preferredColorScheme(.dark)
    }
}

#Preview {
    Splash()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
