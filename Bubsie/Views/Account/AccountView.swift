import SwiftUI
import MessageUI
import FirebaseAuth

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
    @State private var copiedBannerText = NSLocalizedString("common.copied", comment: "")
    @State private var showTopup = false
    @State private var showDeleteAccountPopup = false
    @State private var isDeletingAccount = false
    @State private var deleteAccountError: String?
    @Environment(\.openURL) private var openURL
    @Binding var isPresented: Bool

    var showBackButton: Bool = false

    private let supportEmail = "hi@fagore.com"

    init(isPresented: Binding<Bool> = .constant(false), showBackButton: Bool = false) {
        self._isPresented = isPresented
        self.showBackButton = showBackButton
    }

    private var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }
    private var isPro: Bool { auth.currentUser?.isPro == true || entitlementManager.hasPro }
    private var memberTier: String { isPro ? NSLocalizedString("account.premium_plan", comment: "") : NSLocalizedString("account.free_plan", comment: "") }

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
                if !isPro { premiumButton }
                subscriptionSection
                menuList
                deleteAccountButton
                Color.clear.frame(height: 96)
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .environment(\.colorScheme, .light)
        .background(profileBackground.ignoresSafeArea())
        .navigationBarHidden(true)
        .task { await auth.fetchProfile() }
        .onChange(of: entitlementManager.hasPro) { _, _ in
            Task { await auth.fetchProfile() }
        }
        .sheet(isPresented: $isPremiumShow) { PremiumView() }
        .sheet(isPresented: $showTopup) { TopupView() }
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: ["Check out Bubsie · AI Magic for Your Little One! 🎬 https://apps.apple.com/app/id\(BUBSIE_APP_STORE_ID)"])
        }
        .sheet(isPresented: $showLanguageSheet) {
            LanguageSelectionView()
        }
        .sheet(isPresented: $showMailComposer) {
            MailComposerView(
                recipients: [supportEmail],
                subject: NSLocalizedString("email.subject_support", comment: ""),
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
                        Text(copiedBannerText)
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
        .overlay {
            if showDeleteAccountPopup {
                deleteAccountPopup
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
        HStack(spacing: 20) {
            if showBackButton {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isPresented = false
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: "1E1C10"))
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }

            ProfileStyleHeader(
                title: NSLocalizedString("account.profile_title", comment: ""),
                subtitle: NSLocalizedString("account.profile_subtitle", comment: "")
            )

            Spacer()
        }
    }

    private var creditCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top half
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(NSLocalizedString("account.current_balance", comment: ""))
                            .font(.system(size: 14, weight: .medium))
                            .tracking(0.7)
                            .foregroundStyle(Color(hex: "55433E"))

                        Text("\(displayCredits)")
                            .font(.system(size: 48, weight: .heavy))
                            .foregroundStyle(Color(hex: "97462E"))

                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color(hex: "55433E"))
                            Text(NSLocalizedString("account.credits_ready", comment: ""))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color(hex: "55433E"))
                        }
                        .padding(.top, 4)
                    }

                    Spacer()

                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(Color(hex: "97462E").opacity(0.85))
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 20)

            // Horizontal divider
            Rectangle()
                .fill(Color.white.opacity(0.4))
                .frame(height: 1)
                .padding(.horizontal, 24)

            // Bottom half — tappable liquid-glass area
            Button {
                showTopup = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text(NSLocalizedString("account.top_up_credits", comment: ""))
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "97462E"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.30), Color.white.opacity(0.06)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "F08C6E").opacity(0.32), Color(hex: "FEB246").opacity(0.22)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                )
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
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
                title: NSLocalizedString("account.subscription", comment: ""),
                subtitle: memberTier,
                trailing: AnyView(
                    Text(NSLocalizedString("account.active", comment: ""))
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
                title: NSLocalizedString("account.weekly_allowance", comment: ""),
                subtitle: NSLocalizedString("account.resets_monday", comment: ""),
                trailing: AnyView(
                    Group {
                        if isPro {
                            Text(NSLocalizedString("account.50_credits", comment: ""))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(Color(hex: "1E1C10"))
                        } else {
                            Button {
                                isPremiumShow = true
                            } label: {
                                Text(NSLocalizedString("account.upgrade", comment: ""))
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(hex: "88726C"))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                )
            )
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
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

    @State private var glowPulse = false
    @State private var scalePulse = false

    private var premiumButton: some View {
        Button { isPremiumShow = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)

                Text(NSLocalizedString("account.start_free_trial", comment: ""))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)

                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "FFD56A"))
            }
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "97462E"),
                                Color(hex: "B75D3F"),
                                Color(hex: "F08C6E"),
                                Color(hex: "B75D3F"),
                                Color(hex: "97462E")
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.4), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: Color(hex: "97462E").opacity(glowPulse ? 0.35 : 0.18), radius: glowPulse ? 24 : 14, y: 8)
        }
        .buttonStyle(.plain)
        .scaleEffect(scalePulse ? 1.02 : 1.0)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                glowPulse.toggle()
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                scalePulse.toggle()
            }
        }
    }

    private var menuList: some View {
        VStack(spacing: 0) {
            profileMenuRow(icon: "person.2.fill", title: NSLocalizedString("account.invite_friends", comment: "")) { showShareSheet = true }
            menuDivider
            profileMenuRow(icon: "globe", title: NSLocalizedString("menu.language", comment: "")) { showLanguageSheet = true }
            menuDivider
            profileMenuRow(icon: "headphones", title: NSLocalizedString("account.contact_support", comment: "")) {
                if MFMailComposeViewController.canSendMail() {
                    showMailComposer = true
                } else {
                    UIPasteboard.general.string = supportEmail
                    copiedBannerText = NSLocalizedString("account.email_copied", comment: "")
                    withAnimation { showCopiedBanner = true }
                }
            }
            menuDivider
            profileMenuRow(icon: "questionmark.circle", title: NSLocalizedString("menu.help_center", comment: "")) {
                openURL(URL(string: "https://fagore.com/help/")!)
            }
            menuDivider
            profileMenuRow(icon: "lock.shield", title: NSLocalizedString("menu.privacy_policy", comment: "")) {
                openURL(URL(string: "https://fagore.com/privacy/")!)
            }
            menuDivider
            profileMenuRow(icon: "doc.text", title: NSLocalizedString("account.terms_conditions", comment: "")) {
                openURL(URL(string: "https://fagore.com/terms/")!)
            }
            menuDivider

            profileMenuRow(icon: "person.fill.viewfinder", title: NSLocalizedString("account.user_id", comment: "")) {
                if let uid = Auth.auth().currentUser?.uid {
                    UIPasteboard.general.string = uid
                    copiedBannerText = NSLocalizedString("account.userid_copied", comment: "")
                    withAnimation { showCopiedBanner = true }
                }
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
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var deleteAccountButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                showDeleteAccountPopup = true
            }
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color(hex: "C0392B"))
                Text(NSLocalizedString("account.delete_all_data", comment: ""))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color(hex: "C0392B"))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "C0392B").opacity(0.5))
            }
            .padding(20)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 40, style: .continuous)
                    .fill(.white)
                    .shadow(color: Color(hex: "1E1C10").opacity(0.03), radius: 10, y: 4)
            )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private var deleteAccountPopup: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    if !isDeletingAccount {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDeleteAccountPopup = false
                            deleteAccountError = nil
                        }
                    }
                }

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Color(hex: "E04A2E"))

                Text(NSLocalizedString("account.delete_alert_title", comment: ""))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color(hex: "1E1C10"))

                Text(NSLocalizedString("account.delete_alert_message", comment: ""))
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "55433E"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                if let error = deleteAccountError {
                    Text(error)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(hex: "E04A2E"))
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showDeleteAccountPopup = false
                            deleteAccountError = nil
                        }
                    } label: {
                        Text(NSLocalizedString("common.cancel", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color(hex: "1E1C10"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .fill(Color.white.opacity(0.25))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await performDeleteAccount() }
                    } label: {
                        Text(isDeletingAccount ? NSLocalizedString("account.deleting", comment: "") : NSLocalizedString("account.delete_all_data", comment: ""))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(Color(hex: "C0392B"))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeletingAccount)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Color.white.opacity(0.55), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.12), radius: 24, y: 12)
            .padding(.horizontal, 32)
        }
    }

    private func performDeleteAccount() async {
        isDeletingAccount = true
        deleteAccountError = nil
        do {
            try await BubsieAPI.shared.deleteAccount()
            isDeletingAccount = false
            showDeleteAccountPopup = false
            copiedBannerText = NSLocalizedString("account.deletion_submitted", comment: "")
            withAnimation { showCopiedBanner = true }
        } catch {
            isDeletingAccount = false
            deleteAccountError = error.localizedDescription
        }
    }
}

struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var languageManager = LanguageManager.shared

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
        ("zh", "中文 (Simplified)", "🇨🇳"),
        ("zh-Hant", "中文 (Traditional)", "🇹🇼"),
        ("ar", "العربية", "🇸🇦"),
        ("da", "Dansk", "🇩🇰"),
        ("fi", "Suomi", "🇫🇮"),
        ("el", "Ελληνικά", "🇬🇷"),
        ("nl", "Nederlands", "🇳🇱"),
        ("sv", "Svenska", "🇸🇪"),
        ("nb", "Norsk", "🇳🇴"),
        ("ga", "Gaeilge", "🇮🇪"),
        ("th", "ไทย", "🇹🇭"),
        ("cs", "Čeština", "🇨🇿"),
        ("fil", "Filipino", "🇵🇭"),
        ("he", "עברית", "🇮🇱"),
        ("hr", "Hrvatski", "🇭🇷"),
        ("hu", "Magyar", "🇭🇺"),
        ("id", "Bahasa Indonesia", "🇮🇩"),
        ("ms", "Bahasa Melayu", "🇲🇾"),
        ("pl", "Polski", "🇵🇱"),
        ("ro", "Română", "🇷🇴"),
        ("sk", "Slovenčina", "🇸🇰"),
        ("uk", "Українська", "🇺🇦"),
        ("vi", "Tiếng Việt", "🇻🇳")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FFF9EC").ignoresSafeArea()

                VStack(spacing: 0) {
                    Text(NSLocalizedString("language.choose", comment: ""))
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
                                    languageManager.setLanguage(lang.code)
                                } label: {
                                    HStack(spacing: 12) {
                                        Text(lang.flag)
                                            .font(.system(size: 22))
                                        Text(lang.name)
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundStyle(Color(hex: "1E1C10"))
                                        Spacer()
                                        if languageManager.selectedLanguage == lang.code {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(Color(hex: "97462E"))
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                    .background(languageManager.selectedLanguage == lang.code ? Color(hex: "FAF3E0") : Color.clear)
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
            .navigationTitle(NSLocalizedString("menu.language", comment: ""))
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
        if UIDevice.current.userInterfaceIdiom == .pad {
            composer.modalPresentationStyle = .popover
            composer.popoverPresentationController?.delegate = context.coordinator
        }
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate, UIPopoverPresentationControllerDelegate {
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            controller.dismiss(animated: true)
        }

        func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
            guard let view = popoverPresentationController.presentedViewController.view else { return }
            popoverPresentationController.sourceView = view
            popoverPresentationController.sourceRect = view.bounds
            popoverPresentationController.permittedArrowDirections = []
        }
    }
}

#Preview {
    AccountView()
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
