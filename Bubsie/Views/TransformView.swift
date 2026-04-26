import SwiftUI

// MARK: - Transform Configuration Screen
struct TransformView: View {
    let template: TemplateItem

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionManager: SubscriptionsManager
    @StateObject private var auth = AuthManager.shared
    @StateObject private var counter = CoinCounter()

    @State private var selectedImage: UIImage?
    @State private var selectedAspectRatio: String = "1:1"
    @State private var showImagePicker = false
    @State private var isProcessing = false
    @State private var showAccountView = false
    @State private var goToMainTab = false
    @State private var shimmerPhase: CGFloat = -1.5
    @State private var showConsentSheet = false
    @State private var showTopup = false
    @State private var showPremium = false

    private var isPro: Bool { auth.currentUser?.isPro ?? entitlementManager.hasPro }

    private var hasAcceptedPhotoConsent: Bool {
        UserDefaults.standard.bool(forKey: "photoConsentAccepted")
    }

    private let aspectRatios = ["1:1", "4:5", "9:16", "16:9"]

    // Design colors
    private let bgColor = Color(hex: "FFF8F6")
    private let primaryText = Color(hex: "231917")
    private let secondaryText = Color(hex: "53433F")
    private let accentBrown = Color(hex: "8F4C38")
    private let accentGold = Color(hex: "755A2F")
    private let cardBg = Color.white.opacity(0.30)
    private let cardBorder = Color.white.opacity(0.60)

    var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            backgroundGlows

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        headerSection
                            .padding(.top, 24)

                        photoUploadSection
                            .padding(.horizontal, 24)

                        aspectRatioSection
                            .padding(.horizontal, 24)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomCTA
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
        .navigationDestination(isPresented: $isProcessing) {
            if let img = selectedImage {
                ProcessingImage(
                    image: img,
                    template: template,
                    aspectRatio: selectedAspectRatio,
                    videoURL: template.referenceVideoUrl,
                    onBackToTemplates: {
                        isProcessing = false
                        dismiss()
                    }
                )
            }
        }
        .navigationDestination(isPresented: $showAccountView) {
            AccountView(isPresented: $showAccountView, showBackButton: true)
                .environmentObject(entitlementManager)
                .environmentObject(subscriptionManager)
        }
        .navigationDestination(isPresented: $goToMainTab) {
            MainTabView()
                .environmentObject(entitlementManager)
                .environmentObject(subscriptionManager)
                .navigationBarHidden(true)
        }
            .preferredColorScheme(.light)
            .overlay(
                consentSheet
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showConsentSheet)
            )
            .sheet(isPresented: $showTopup) {
                TopupView()
                    .environmentObject(entitlementManager)
                    .environmentObject(subscriptionManager)
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
                    .environmentObject(entitlementManager)
                    .environmentObject(subscriptionManager)
            }
    }

    // MARK: Background Glows
    private var backgroundGlows: some View {
        LinearGradient(
            colors: [Color(hex: "FFF8F6"), Color(hex: "F7ECE7")],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: Top Bar
    private var topBar: some View {
        HStack {
            Button { goToMainTab = true } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(hex: "f9f5f2"))
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(Circle().fill(Color.black.opacity(0.18)))
                    )
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(NSLocalizedString("app.name", comment: ""))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(accentBrown)
                .tracking(-0.45)

            Spacer()

            Button {
                showAccountView = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.system(size: 13, weight: .bold))
                    Text("\(displayCredits)")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(Color(hex: "f9f5f2"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .overlay(Color.black.opacity(0.18))
                )
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(template.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(primaryText)
                .multilineTextAlignment(.center)

            Text(NSLocalizedString("transform.upload_prompt", comment: ""))
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.85), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 0.35)
                        .offset(x: shimmerPhase * geo.size.width)
                        .mask(
                            Text(NSLocalizedString("transform.upload_prompt", comment: ""))
                                .font(.system(size: 16, weight: .regular))
                                .multilineTextAlignment(.center)
                                .frame(width: geo.size.width, height: geo.size.height)
                        )
                    }
                )
                .onAppear {
                    withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                        shimmerPhase = 1.5
                    }
                }
        }
        .padding(.horizontal, 24)
    }

    // MARK: Photo Upload
    private var photoUploadSection: some View {
        Button {
            if !hasAcceptedPhotoConsent {
                showConsentSheet = true
            } else {
                showImagePicker = true
            }
        } label: {
            ZStack {
                // Glassmorphism background
                RoundedRectangle(cornerRadius: 40)
                    .fill(cardBg)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(cardBorder, lineWidth: 1)
                    )
                    .shadow(color: Color(hex: "8F4C38").opacity(0.15), radius: 32, x: 0, y: 8)

                // Liquid glass reflection gradient
                RoundedRectangle(cornerRadius: 40)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.20),
                                Color.white.opacity(0.00),
                                Color.white.opacity(0.40),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Top highlight gradient
                VStack {
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.white.opacity(0.00)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 92)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 40))

                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 340)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                } else {
                    // Placeholder content
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.50))
                                .frame(width: 96, height: 96)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.60), lineWidth: 1)
                                )
                                .shadow(color: Color(hex: "8F4C38").opacity(0.10), radius: 16, x: 0, y: 4)

                            Image(systemName: "camera.fill")
                                .font(.system(size: 28, weight: .medium))
                                .foregroundStyle(accentBrown)
                        }

                        Text(NSLocalizedString("transform.tap_upload", comment: ""))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(primaryText)

                        HStack {
                            Spacer()
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "face.smiling")
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 20, alignment: .center)
                                    Text(NSLocalizedString("transform.tip_clear_faces", comment: ""))
                                        .font(.system(size: 13, weight: .medium))
                                }
                                HStack(spacing: 6) {
                                    Image(systemName: "sun.max.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 20, alignment: .center)
                                    Text(NSLocalizedString("transform.tip_good_lighting", comment: ""))
                                        .font(.system(size: 13, weight: .medium))
                                }
                                HStack(spacing: 6) {
                                    Image(systemName: "person.fill.viewfinder")
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 20, alignment: .center)
                                    Text(NSLocalizedString("transform.tip_face_front", comment: ""))
                                        .font(.system(size: 13, weight: .medium))
                                }
                                HStack(spacing: 6) {
                                    Image(systemName: "eye.slash")
                                        .font(.system(size: 12, weight: .medium))
                                        .frame(width: 20, alignment: .center)
                                    Text(NSLocalizedString("transform.tip_no_accessories", comment: ""))
                                        .font(.system(size: 13, weight: .medium))
                                }
                            }
                            .foregroundStyle(secondaryText)
                            Spacer()
                        }
                    }
                    .padding(.vertical, 56)
                }
            }
            .frame(height: 340)
        }
        .buttonStyle(.plain)
    }

    // MARK: Aspect Ratio Selection
    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(NSLocalizedString("transform.aspect_ratio", comment: ""))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(primaryText)
                .padding(.horizontal, 8)

            HStack(spacing: 12) {
                ForEach(aspectRatios, id: \.self) { ratio in
                    AspectRatioButton(
                        ratio: ratio,
                        isSelected: selectedAspectRatio == ratio
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedAspectRatio = ratio
                        }
                    }
                }
            }
        }
    }

    // MARK: Bottom CTA
    private var bottomCTA: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.50))

            HStack {
                Spacer()

                Button {
                    guard selectedImage != nil else {
                        if !hasAcceptedPhotoConsent {
                            showConsentSheet = true
                        } else {
                            showImagePicker = true
                        }
                        return
                    }
                    guard displayCredits >= template.creditCost else {
                        if isPro {
                            showTopup = true
                        } else {
                            showPremium = true
                        }
                        return
                    }
                    isProcessing = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                        Text(String(format: NSLocalizedString("transform.cta_format", comment: ""), template.creditCost))
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [accentBrown, accentGold],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: accentBrown.opacity(0.30), radius: 24, x: 0, y: 8)
                }
                .buttonStyle(.plain)
                .disabled(!canTransform)
                .opacity(canTransform ? 1.0 : 0.6)

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 32)
            .background(
                Color.white.opacity(0.40)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.40), Color.white.opacity(0.00)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            )
            .background(.ultraThinMaterial.opacity(0.4))
        }
    }

    private var canTransform: Bool {
        selectedImage != nil
    }

    // MARK: - Photo Consent Sheet
    private var consentSheet: some View {
        ZStack {
            if showConsentSheet {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        showConsentSheet = false
                    }

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Text(NSLocalizedString("transform.consent_title", comment: ""))
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(primaryText)
                                .multilineTextAlignment(.center)

                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                    Text(NSLocalizedString("transform.consent_bullet1", comment: ""))
                                }
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                    Text(NSLocalizedString("transform.consent_bullet2", comment: ""))
                                }
                                HStack(alignment: .top, spacing: 6) {
                                    Text("•")
                                    Text(NSLocalizedString("transform.consent_bullet3", comment: ""))
                                }
                            }
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(secondaryText)
                        }

                        HStack(spacing: 12) {
                            Button {
                                showConsentSheet = false
                            } label: {
                                Text(NSLocalizedString("transform.consent_decline", comment: ""))
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(accentBrown)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.50))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.60), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button {
                                UserDefaults.standard.set(true, forKey: "photoConsentAccepted")
                                showConsentSheet = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    showImagePicker = true
                                }
                            } label: {
                                Text(NSLocalizedString("transform.consent_agree", comment: ""))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(accentBrown)
                                    )
                                    .shadow(color: accentBrown.opacity(0.25), radius: 12, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 32)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 32)
                                    .stroke(Color.white.opacity(0.50), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.10), radius: 20, x: 0, y: -4)
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Aspect Ratio Button
private struct AspectRatioButton: View {
    let ratio: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(isSelected ? Color(hex: "231917") : Color(hex: "53433F"), lineWidth: 2)
                        .frame(width: shapeWidth, height: shapeHeight)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .frame(height: 44)

                Text(ratio)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? Color(hex: "231917") : Color(hex: "53433F"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                ? Color.white.opacity(0.50)
                : Color.white.opacity(0.20)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white.opacity(0.60) : Color.white.opacity(0.30), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: isSelected
                    ? Color(hex: "8F4C38").opacity(0.08)
                    : Color.black.opacity(0.03),
                radius: 16, x: 0, y: 4
            )
        }
        .buttonStyle(.plain)
    }

    private var shapeWidth: CGFloat {
        switch ratio {
        case "1:1": return 24
        case "4:5": return 24
        case "9:16": return 20
        case "16:9": return 36
        default: return 24
        }
    }

    private var shapeHeight: CGFloat {
        switch ratio {
        case "1:1": return 24
        case "4:5": return 32
        case "9:16": return 36
        case "16:9": return 20
        default: return 24
        }
    }
}

#Preview {
    TransformView(template: TemplateItem(
        id: 1,
        appId: "test",
        slug: "baby-dance",
        name: "Baby Dance",
        description: "Make your baby dance!",
        actionType: "video",
        prompt: "dance",
        negativePrompt: nil,
        provider: "test",
        model: nil,
        categoryId: nil,
        beforeMediaUrl: nil,
        beforeMediaType: nil,
        afterMediaUrl: nil,
        afterMediaType: nil,
        referenceImageCount: nil,
        referenceVideoUrl: nil,
        requireMomPhoto: nil,
        requireBabyPhoto: nil,
        requireDadPhoto: nil,
        hideFromAll: nil,
        aspectRatio: nil,
        supportedAspectRatios: nil,
        iconUrl: nil,
        params: nil,
        creditCost: 1,
        isActive: true,
        isFeatured: true,
        isPopular: true,
        isViral: false,
        isPremium: false,
        sortOrder: 0
    ))
    .environmentObject(EntitlementManager())
    .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
