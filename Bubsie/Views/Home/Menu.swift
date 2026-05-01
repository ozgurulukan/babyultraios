import SwiftUI

// MARK: - Settings Sheet (accessed from AccountView → Settings)
struct Menu: View {
    @Environment(\.presentationMode) var dismiss
    @Environment(\.openURL) var openURL
    @StateObject private var languageManager = LanguageManager.shared

    @AppStorage("isDarkMode")    private var isDarkMode    = true
    @AppStorage("isWatermark")   private var isWatermark   = false

    @State private var showLanguagePicker = false
    @State private var showShareSheet     = false

    private let languages: [(String, String)] = [
        ("English", "en"), ("Türkçe", "tr"), ("Español", "es"), ("Français", "fr"), ("Deutsch", "de"),
        ("Italiano", "it"), ("Português", "pt"), ("Русский", "ru"), ("日本語", "ja"), ("한국어", "ko"),
        ("中文", "zh"), ("العربية", "ar"), ("Dansk", "da"), ("Suomi", "fi"), ("Ελληνικά", "el"),
        ("Nederlands", "nl"), ("Svenska", "sv"), ("Norsk Bokmål", "nb"), ("Gaeilge", "ga"), ("ไทย", "th"),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBG()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        // Appearance
                        settingsGroup(title: NSLocalizedString("menu.appearance", comment: "")) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Bubsie.surface)
                                        .frame(width: 34, height: 34)
                                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(isDarkMode ? Bubsie.accent : .yellow)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                Text(NSLocalizedString("menu.dark_mode", comment: ""))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Toggle("", isOn: $isDarkMode)
                                    .tint(Bubsie.accent)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 54)
                        }

                        // Preferences
                        settingsGroup(title: NSLocalizedString("menu.preferences", comment: "")) {
                            // Language
                            Button {
                                showLanguagePicker = true
                            } label: {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "001A6E").opacity(0.6))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "globe")
                                            .font(.system(size: 15))
                                            .foregroundStyle(.blue)
                                    }
                                    Text(NSLocalizedString("menu.language", comment: ""))
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text(languages.first(where: { $0.1 == languageManager.selectedLanguage })?.0 ?? languageManager.selectedLanguage)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(Bubsie.textSecondary)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Bubsie.textSecondary)
                                }
                                .padding(.horizontal, 14)
                                .frame(height: 54)
                            }
                            .buttonStyle(.plain)

                            Rectangle().fill(Color(hex: "1C1C2E")).frame(height: 0.5).padding(.leading, 60)

                            // Watermark
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Bubsie.surface)
                                        .frame(width: 34, height: 34)
                                    Image(systemName: "drop.fill")
                                        .font(.system(size: 15))
                                        .foregroundStyle(Bubsie.textSecondary)
                                }
                                Text(NSLocalizedString("menu.show_watermark", comment: ""))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                Toggle("", isOn: $isWatermark)
                                    .tint(Bubsie.accent)
                                    .labelsHidden()
                            }
                            .padding(.horizontal, 14)
                            .frame(height: 54)
                        }

                        // Legal
                        settingsGroup(title: NSLocalizedString("menu.legal_support", comment: "")) {
                            Button {
                                openURL(URL(string: "https://fagore.com/privacy/")!)
                            } label: {
                                CardItem(icon: "shield.fill", text: NSLocalizedString("menu.privacy_policy", comment: ""), iconColor: .green)
                            }
                            .buttonStyle(.plain)

                            Rectangle().fill(Color(hex: "1C1C2E")).frame(height: 0.5).padding(.leading, 60)

                            Button {
                                openURL(URL(string: "https://fagore.com/terms/")!)
                            } label: {
                                CardItem(icon: "doc.text.fill", text: NSLocalizedString("menu.terms_of_service", comment: ""), iconColor: .blue)
                            }
                            .buttonStyle(.plain)

                            Rectangle().fill(Color(hex: "1C1C2E")).frame(height: 0.5).padding(.leading, 60)

                            Button {
                                openURL(URL(string: "https://fagore.com/help/")!)
                            } label: {
                                CardItem(icon: "questionmark.circle.fill", text: NSLocalizedString("menu.help_center", comment: ""), iconColor: .orange)
                            }
                            .buttonStyle(.plain)
                        }

                        // Version
                        Text("Bubsie v1.0.2")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Bubsie.textSecondary)
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarTitle(NSLocalizedString("menu.settings_title", comment: ""), displayMode: .inline)
            .navigationBarItems(leading: Button {
                dismiss.wrappedValue.dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
            })
            .sheet(isPresented: $showLanguagePicker) {
                languagePickerSheet
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Helpers
    func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Bubsie.textSecondary)
                .textCase(.uppercase)
                .tracking(0.6)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .background(Bubsie.card)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    var languagePickerSheet: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBG()
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(languages, id: \.1) { name, code in
                        Button {
                            languageManager.setLanguage(code)
                            showLanguagePicker = false
                        } label: {
                            HStack {
                                Text(name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundStyle(.white)
                                Spacer()
                                if languageManager.selectedLanguage == code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Bubsie.accent)
                                }
                            }
                            .padding(.horizontal, 20)
                            .frame(height: 52)
                        }
                        .buttonStyle(.plain)
                        Rectangle().fill(Color(hex: "1C1C2E")).frame(height: 0.5).padding(.leading, 20)
                    }
                    Spacer()
                }
                .padding(.top, 8)
            }
            .navigationBarTitle(NSLocalizedString("menu.language", comment: ""), displayMode: .inline)
            .navigationBarItems(leading: Button {
                showLanguagePicker = false
            } label: {
                Image(systemName: "xmark").foregroundStyle(.white)
            })
        }
        .presentationDetents([.medium])
        .preferredColorScheme(.dark)
    }
}

#Preview {
    Menu()
        .environmentObject(EntitlementManager())
}
