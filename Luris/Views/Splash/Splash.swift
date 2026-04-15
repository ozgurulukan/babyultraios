import SwiftUI

struct Splash: View {
    @State private var isContinue = false
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBG()

                if !isContinue {
                    VStack(spacing: 18) {
                        // App icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Luris.accentGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: Luris.accentRose.opacity(0.5), radius: 28, y: 10)
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                        }
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                        // App name
                        VStack(spacing: 4) {
                            Text("Luris")
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundStyle(.white)
                            Text("AI Video & Photo Studio")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Luris.textSecondary)
                        }
                        .opacity(textOpacity)
                    }
                    .onAppear {
                        withAnimation(.spring(response: 0.65, dampingFraction: 0.72)) {
                            logoScale = 1.0
                            logoOpacity = 1.0
                        }
                        withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                            textOpacity = 1.0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation { isContinue = true }
                        }
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
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    Splash()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
