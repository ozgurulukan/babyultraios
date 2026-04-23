import SwiftUI
import MessageUI

struct AccountView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionManager: SubscriptionsManager
    @StateObject private var counter = CoinCounter()
    @StateObject private var auth = AuthManager.shared
    @State private var isPremiumShow = false
    @State private var showShareSheet = false
    @State private var showLanguageSheet = false
    @State private var showMailComposer = false
    @State private var showCopiedBanner = false
    @Environment(\.openURL) private var openURL

    private let supportEmail = "hi@fagore.com"

    private var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }
    private var isPro: Bool { auth.currentUser?.isPro ?? entitlementManager.hasPro }
    private var memberTier: String { isPro ? "Premium Plan" : "Free Plan" }

    var body: some View {
        StickyBlurHeader(
            maxBlurRadius: 10,
            fadeExtension: 84,
            tintOpacityTop: 0.58,
            tintOpacityMiddle: 0.36
        ) {
            headerSection
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 12)
        } content: {
            VStack(alignment: .leading, spacing: 24) {
                creditCard
                subscriptionSection
                if !isPro { premiumButton }
                menuList
                Color.clear.frame(height: 96)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .environment(\.colorScheme, .light)
        .background(profileBackground.ignoresSafeArea())
        .task { await auth.fetchProfile() }
        .sheet(isPresented: $isPremiumShow) { PremiumView() }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: ["Check out Bubsie AI — stunning AI video & photo studio! 🎬 https://apps.apple.com"])
        }
        .sheet(isPresented: $showLanguageSheet) {
            LanguageSelectionView()
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                recipients: [supportEmail],
                subject: "Bubsie Support",
                body: ""
            )
        }
        .overlay {
            if showCopiedBanner {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.white)
                        Text("Email copied to clipboard")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color(hex: "97462E"))
                    )
                    .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showCopiedBanner = false }
                    }
                }
            }
        }
    }

    private var profileBackground: some View {
        LinearGradient(
            colors: [Color(hex: "FFF9EC"), Color(hex: "FFF9EC")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var headerSection: some View {
        ProfileStyleHeader(
            title: "Profile",
            subtitle: "Manage your credits and profile settings."
        )
    }

    private var creditCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CURRENT BALANCE")
                        .font(.system(size: 14, weight: .medium))
                        .tracking(0.7)
                        .foregroundStyle(Color(hex: "55433E"))

                    Text("\(displayCredits)")
                        .font(.system(size: 48, weight: .heavy))
                        .foregroundStyle(Color(hex: "97462E"))
                }

                Spacer()

                Image(systemName: "star.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(hex: "97462E").opacity(0.85))
            }

            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "55433E"))
                Text("Credits ready to use")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "55433E"))
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.30), Color.white.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(Color.white.opacity(0.55), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 40, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color(hex: "F08C6E").opacity(0.32), Color(hex: "FEB246").opacity(0.22)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(Color(hex: "F08C6E").opacity(0.35))
                        .frame(width: 128, height: 128)
                        .blur(radius: 24)
                        .offset(x: 45, y: -45)
                }
                .overlay(alignment: .bottomLeading) {
                    Circle()
                        .fill(Color(hex: "FEB246").opacity(0.35))
                        .frame(width: 128, height: 128)
                        .blur(radius: 24)
                        .offset(x: -45, y: 45)
                }
                .compositingGroup()
        }
        .shadow(color: Color.white.opacity(0.30), radius: 1, y: -1)
        .shadow(color: Color(hex: "97462E").opacity(0.12), radius: 20, y: 8)
    }

    private var subscriptionSection: some View {
        VStack(spacing: 0) {
            profileInfoRow(
                icon: "creditcard.fill",
                title: "Subscription",
                subtitle: memberTier,
                trailing: AnyView(
                    Text("Active")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(hex: "55433E"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: "FFF9EC")))
                )
            )

            Divider().overlay(Color(hex: "F4EEDB"))

            profileInfoRow(
                icon: "calendar",
                title: "Weekly Allowance",
                subtitle: "Resets every Sunday",
                trailing: AnyView(
                    Text(isPro ? "Unlimited" : "5 Credits")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color(hex: "1E1C10"))
                )
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(Color(hex: "FAF3E0"))
        )
    }

    private func profileInfoRow(
        icon: String,
        title: String,
        subtitle: String,
        trailing: AnyView
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "F4EEDB"))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "97462E"))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color(hex: "1E1C10"))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "55433E"))
            }

            Spacer()
            trailing
        }
        .padding(.vertical, 16)
    }

    private var premiumButton: some View {
        Button { isPremiumShow = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 20))
                Text("Go Premium")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color(hex: "97462E"), Color(hex: "F08C6E")],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color(hex: "97462E").opacity(0.2), radius: 12, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var menuList: some View {
        VStack(spacing: 0) {
            profileMenuRow(icon: "person.2.fill", title: "Invite Friends") { showShareSheet = true }
            menuDivider
            profileMenuRow(icon: "globe", title: "Language") { showLanguageSheet = true }
            menuDivider
            profileMenuRow(icon: "headphones", title: "Contact Support") {
                if MFMailComposeViewController.canSendMail() {
                    showMailComposer = true
                } else {
                    UIPasteboard.general.string = supportEmail
                    withAnimation { showCopiedBanner = true }
                }
            }
            menuDivider
            profileMenuRow(icon: "questionmark.circle", title: "Help Center") {
                openURL(URL(string: "https://fagore.com/help/")!)
            }
            menuDivider
            profileMenuRow(icon: "lock.shield", title: "Privacy Policy") {
                openURL(URL(string: "https://fagore.com/privacy/")!)
            }
            menuDivider
            profileMenuRow(icon: "doc.text", title: "Terms & Conditions") {
                openURL(URL(string: "https://fagore.com/terms/")!)
            }
            menuDivider
            profileMenuRow(icon: "star.fill", title: "Rate Us") {
                openURL(URL(string: "https://apps.apple.com")!)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(.white)
                .shadow(color: Color(hex: "1E1C10").opacity(0.03), radius: 10, y: 4)
        )
        .clipShape(RoundedRectangle(cornerRadius: 40, style: .continuous))
    }

    private var menuDivider: some View {
        Rectangle()
            .fill(Color(hex: "F4EEDB").opacity(0.6))
            .frame(height: 1)
            .padding(.leading, 60)
    }

    private func profileMenuRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color(hex: "97462E"))
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(hex: "1E1C10"))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "88726C"))
            }
            .padding(20)
        }
        .buttonStyle(.plain)
    }
}

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var selectedLanguage: String = Locale.current.language.languageCode?.identifier ?? "en"

    private let languages: [(code: String, name: String, flag: String)] = [
        ("en", "English", "🇺🇸"),
        ("tr", "Türkçe", "🇹🇷"),
        ("es", "Español", "🇪🇸"),
        ("fr", "Français", "🇫🇷"),
        ("de", "Deutsch", "🇩🇪"),
        ("it", "Italiano", "🇮🇹"),
        ("pt", "Português", "🇵🇹"),
        ("ru", "Русский", "🇷🇺"),
        ("ja", "日本語", "🇯🇵"),
        ("ko", "한국어", "🇰🇷"),
        ("zh", "中文", "🇨🇳"),
        ("ar", "العربية", "🇸🇦")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FFF9EC").ignoresSafeArea()

                VStack(spacing: 0) {
                    Text("Choose your preferred language")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "55433E"))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .padding(.top, 16)
                        .padding(.bottom, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            ForEach(languages, id: \.code) { lang in
                                Button {
                                    selectedLanguage = lang.code
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(lang.flag)
                                            .font(.system(size: 22))
                                        Text(lang.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color(hex: "1E1C10"))
                                        Spacer()
                                        if selectedLanguage == lang.code {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(Color(hex: "97462E"))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(selectedLanguage == lang.code ? Color(hex: "FAF3E0") : Color.clear)
                                }
                                .buttonStyle(.plain)

                                if lang.code != languages.last?.code {
                                    Divider()
                                        .overlay(Color(hex: "F4EEDB"))
                                        .padding(.leading, 20)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.white)
                                .shadow(color: Color(hex: "1E1C10").opacity(0.03), radius: 10, y: 4)
                        )
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .navigationTitle("Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color(hex: "97462E"))
                    }
                }
            }
        }
    }
}

struct MailComposerView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let body: String

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
