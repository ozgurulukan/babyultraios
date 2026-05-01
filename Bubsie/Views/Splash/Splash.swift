import SwiftUI

private enum SplashPalette {
    static let background = Color(hex: "F6ECE6")
    static let card = Color(hex: "EFE2DC")
    static let tile = Color(hex: "F4ECE8")
    static let text = Color(hex: "3F2D28")
    static let subtleText = Color(hex: "796B64")
    static let accent = Color(hex: "A66A54")
}

struct DeviceBannedView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "shield.slash.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Color(hex: "E04A2E"))

                VStack(spacing: 12) {
                    Text(NSLocalizedString("splash.access_restricted", comment: ""))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color(hex: "1E1C10"))

                    Text(NSLocalizedString("splash.device_banned_message", comment: ""))
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "55433E"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)

                    Text(NSLocalizedString("splash.contact_support_message", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color(hex: "55433E"))
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
                            .fill(Color(hex: "97462E"))
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
                    Text(NSLocalizedString("app.name", comment: ""))
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(SplashPalette.text)

                    Text(NSLocalizedString("splash.tagline", comment: ""))
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
