import SwiftUI

private enum SplashPalette {
    static let background = BabyUltra.bg
    static let card = Color.white.opacity(0.85)
    static let tile = Color.white.opacity(0.7)
    static let text = BabyUltra.textPrimary
    static let subtleText = BabyUltra.textSecondary
    static let accent = BabyUltra.accent
}

struct DeviceBannedView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "shield.slash.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Color(hex: "FF4D85"))

                VStack(spacing: 12) {
                    Text(NSLocalizedString("splash.access_restricted", comment: ""))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(hex: "2D2422"))

                    Text(NSLocalizedString("splash.device_banned_message", comment: ""))
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "8D7F7A"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text(NSLocalizedString("splash.contact_support_message", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "8D7F7A"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)

                Button {
                    if let url = URL(string: "mailto:hi@fagore.com?subject=Device Ban Appeal") {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(NSLocalizedString("splash.contact_support", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(hex: "FF4D85"))
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(.vertical, 40)
            .background(
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 40, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 32, y: 16)
            .padding(.horizontal, 24)
        }
        .environment(\.colorScheme, .light)
    }
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
        Group {
            if isContinue {
                if UserDefaults.standard.bool(forKey: "hasSeenOnboarding") {
                    MainTabView()
                } else {
                    Intro()
                }
            } else {
                splashContent
            }
        }
        .environment(\.colorScheme, .light)
    }

    private var splashContent: some View {
        ZStack {
            Image("bg")
                .resizable()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("babyultralogo")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                if auth.isAuthenticating {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.1)
                        .padding(.top, 16)
                }

                Spacer()
            }

            if auth.isDeviceBanned {
                DeviceBannedView()
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            LanguageManager.shared.refreshIfNeeded()

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
        .onChange(of: auth.idToken) { _, newValue in
            if newValue != nil && !isContinue {
                continueIfReady()
            }
        }
    }
}

#Preview {
    Splash()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
