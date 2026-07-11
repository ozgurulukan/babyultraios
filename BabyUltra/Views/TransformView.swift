import SwiftUI
import UIKit
import SDWebImageSwiftUI

// MARK: - Transform Configuration Screen
struct TransformView: View {
    let template: TemplateItem

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var subscriptionManager: SubscriptionsManager
    @StateObject private var counter = CoinCounter()
    @AppStorage("hasPro") private var hasPro: Bool = false

    @State private var selectedImage: UIImage?
    @State private var selectedImage2: UIImage?
    @State private var activePicker: Int = 1
    @State private var selectedAspectRatio: String = "1:1"
    @State private var showImagePicker = false
    @State private var isProcessing = false
    @State private var showAccountView = false
    @State private var goToMainTab = false
    @State private var shimmerPhase: CGFloat = -1.5
    @State private var showConsentSheet = false
    @State private var showTopup = false
    @State private var showPremium = false
    @State private var is4KEnabled = false
    @State private var showLightbox = false

    private var templatePreviewURL: URL? {
        template.afterMediaUrl.flatMap(URL.init) ?? template.beforeMediaUrl.flatMap(URL.init)
    }

    private var isPro: Bool { AuthManager.shared.currentUser?.isPro ?? hasPro }

    private var hasAcceptedPhotoConsent: Bool {
        UserDefaults.standard.bool(forKey: "photoConsentAccepted")
    }

    private let aspectRatios = ["1:1", "4:5", "9:16", "16:9"]

    // Design colors
    private let bgColor = Color(hex: "FFF3F1")
    private let primaryText = Color(hex: "2D2422")
    private let secondaryText = Color(hex: "8D7F7A")
    private let accentBrown = Color(hex: "FF4D85")
    private let accentGold = Color(hex: "FF88A8")
    private let cardBg = Color.white.opacity(0.30)
    private let cardBorder = Color.white.opacity(0.60)

    var displayCredits: Int { AuthManager.shared.currentUser?.credits ?? counter.coins }

    var body: some View {
        ZStack {
            Image("bg")
                .resizable()
                .ignoresSafeArea()
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
            ImagePicker(image: activePicker == 1 ? $selectedImage : $selectedImage2)
        }
        .navigationDestination(isPresented: $isProcessing) {
            if let img = selectedImage {
                ProcessingImage(
                    image: img,
                    image2: selectedImage2,
                    template: template,
                    aspectRatio: selectedAspectRatio,
                    onBackToTemplates: {
                        isProcessing = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            dismiss()
                        }
                    }
                )
            }
        }
        .navigationDestination(isPresented: $showAccountView) {
            AccountView(isPresented: $showAccountView, showBackButton: true)
        }
        .navigationDestination(isPresented: $goToMainTab) {
            MainTabView()
                .navigationBarHidden(true)
        }
            .preferredColorScheme(.light)
            .onAppear { AppState.shared.hideTabBar = true }
            .overlay(
                consentSheet
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showConsentSheet)
            )
            .sheet(isPresented: $showTopup) {
                TopupView()
            }
            .sheet(isPresented: $showPremium) {
                PremiumView()
            }
            .overlay(
                Group {
                    if showLightbox {
                        lightboxOverlay
                    }
                }
            )
    }

    // MARK: Background Glows
    private var backgroundGlows: some View {
        LinearGradient(
            colors: [Color(hex: "FFF3F1"), Color(hex: "FFF3F1")],
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
                showTopup = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                    UserCreditsBadge(counter: counter, fontSize: 13)
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
        HStack(spacing: 16) {
            if let previewURL = templatePreviewURL {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showLightbox = true
                    }
                } label: {
                    WebImage(url: previewURL)
                        .resizable()
                        .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 3)
                    .overlay(
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(4)
                            .background(Color.black.opacity(0.35))
                            .clipShape(Circle())
                            .padding(4),
                        alignment: .bottomTrailing
                    )
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(template.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryText)
                    .multilineTextAlignment(.leading)

                Text(NSLocalizedString("transform.upload_prompt", comment: ""))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(secondaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
                                    .font(.system(size: 14, weight: .regular))
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .frame(width: geo.size.width, height: geo.size.height, alignment: .leading)
                            )
                        }
                    )
                    .clipped()
            }
            .onAppear {
                withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmerPhase = 1.5
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Photo Upload
    private var photoUploadSection: some View {
        Group {
            if template.requireMomPhoto == true && template.requireDadPhoto == true {
                HStack(spacing: 12) {
                    uploadBox(title: NSLocalizedString("transform.photo_1", comment: ""), image: selectedImage, pickerIndex: 1, showTips: true, isCompact: true)
                    uploadBox(title: NSLocalizedString("transform.photo_2", comment: ""), image: selectedImage2, pickerIndex: 2, showTips: true, isCompact: true)
                }
                .frame(height: 320)
            } else {
                uploadBox(title: NSLocalizedString("transform.tap_upload", comment: ""), image: selectedImage, pickerIndex: 1, showTips: true, isCompact: false)
                    .frame(height: 340)
            }
        }
    }

    private func uploadBox(title: String, image: UIImage?, pickerIndex: Int, showTips: Bool, isCompact: Bool = false) -> some View {
        Button {
            activePicker = pickerIndex
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
                    .shadow(color: Color(hex: "FF4D85").opacity(0.15), radius: 32, x: 0, y: 8)

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
                    .frame(height: showTips ? 92 : 64)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 40))

                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 40))
                } else {
                    // Placeholder content
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.50))
                                .frame(width: showTips ? (isCompact ? 64 : 96) : 64, height: showTips ? (isCompact ? 64 : 96) : 64)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.60), lineWidth: 1)
                                )
                                .shadow(color: Color(hex: "FF4D85").opacity(0.10), radius: 16, x: 0, y: 4)

                            Image(systemName: showTips ? (isCompact ? "plus" : "camera.fill") : "plus")
                                .font(.system(size: showTips ? (isCompact ? 24 : 28) : 24, weight: .medium))
                                .foregroundStyle(accentBrown)
                        }

                        Text(title)
                            .font(.system(size: showTips ? (isCompact ? 16 : 18) : 16, weight: .semibold))
                            .foregroundStyle(primaryText)

                        if showTips {
                            HStack {
                                Spacer()
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "face.smiling")
                                            .font(.system(size: 12, weight: .medium))
                                            .frame(width: 20, alignment: .center)
                                        Text(NSLocalizedString("transform.tip_clear_faces", comment: ""))
                                            .font(.system(size: isCompact ? 10 : 13, weight: .medium))
                                    }
                                    HStack(spacing: 6) {
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 12, weight: .medium))
                                            .frame(width: 20, alignment: .center)
                                        Text(NSLocalizedString("transform.tip_good_lighting", comment: ""))
                                            .font(.system(size: isCompact ? 10 : 13, weight: .medium))
                                    }
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.fill.viewfinder")
                                            .font(.system(size: 12, weight: .medium))
                                            .frame(width: 20, alignment: .center)
                                        Text(NSLocalizedString("transform.tip_face_front", comment: ""))
                                            .font(.system(size: isCompact ? 10 : 13, weight: .medium))
                                    }
                                    HStack(spacing: 6) {
                                        Image(systemName: "eye.slash")
                                            .font(.system(size: 12, weight: .medium))
                                            .frame(width: 20, alignment: .center)
                                        Text(NSLocalizedString("transform.tip_no_accessories", comment: ""))
                                            .font(.system(size: isCompact ? 10 : 13, weight: .medium))
                                    }
                                }
                                .foregroundStyle(secondaryText)
                                Spacer()
                            }
                        }
                    }
                    .padding(.vertical, showTips ? (isCompact ? 24 : 56) : 24)
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Aspect Ratio Selection
    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(NSLocalizedString("transform.aspect_ratio", comment: ""))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(primaryText)
                    .padding(.horizontal, 8)
                
                Spacer()
                
                // 4K Toggle
                HStack(spacing: 8) {
                    Text("4K")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(is4KEnabled ? accentBrown : secondaryText)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(is4KEnabled ? accentBrown : secondaryText.opacity(0.4), lineWidth: 1.5)
                        )
                    
                    Toggle("", isOn: Binding(
                        get: { is4KEnabled },
                        set: { newValue in
                            if isPro {
                                is4KEnabled = newValue
                            } else {
                                showPremium = true
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(accentBrown)
                }
                .padding(.horizontal, 8)
            }

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
                    let requiresDual = (template.requireMomPhoto == true && template.requireDadPhoto == true)
                    let isValid = requiresDual ? (selectedImage != nil && selectedImage2 != nil) : (selectedImage != nil)
                    guard isValid else {
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
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        showConsentSheet = false
                    }

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 16) {
                        // Title & Subtitle
                        VStack(spacing: 8) {
                            Text(NSLocalizedString("transform.consent_title", comment: ""))
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(primaryText)
                                .multilineTextAlignment(.center)

                            Text(NSLocalizedString("transform.consent_subtitle", comment: ""))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(secondaryText)
                                .multilineTextAlignment(.center)
                        }

                        // Scrollable disclosure sections
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(alignment: .leading, spacing: 16) {
                                // Section 1: What data we collect & send
                                consentSection(
                                    icon: "doc.text.magnifyingglass",
                                    title: NSLocalizedString("transform.consent_section1_title", comment: ""),
                                    body: NSLocalizedString("transform.consent_section1_body", comment: "")
                                )

                                // Section 2: Who receives your data
                                consentSection(
                                    icon: "building.2",
                                    title: NSLocalizedString("transform.consent_section2_title", comment: ""),
                                    body: NSLocalizedString("transform.consent_section2_body", comment: "")
                                )

                                // Section 3: How data is used & stored
                                consentSection(
                                    icon: "externaldrive.badge.checkmark",
                                    title: NSLocalizedString("transform.consent_section3_title", comment: ""),
                                    body: NSLocalizedString("transform.consent_section3_body", comment: "")
                                )

                                // Section 4: User confirmation
                                consentSection(
                                    icon: "checkmark.shield",
                                    title: NSLocalizedString("transform.consent_section4_title", comment: ""),
                                    body: NSLocalizedString("transform.consent_section4_body", comment: "")
                                )
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(maxHeight: UIScreen.main.bounds.height * 0.40)

                        // Privacy Policy link
                        Button {
                            if let url = URL(string: NSLocalizedString("app.privacy_url", comment: "")) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Text(NSLocalizedString("transform.consent_privacy_link", comment: ""))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(accentBrown)
                                .underline()
                        }
                        .buttonStyle(.plain)

                        // Buttons
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

    // MARK: - Consent Section Helper
    private func consentSection(icon: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accentBrown)
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(primaryText)
            }

            Text(body)
                .font(.system(size: 11.5, weight: .regular))
                .foregroundStyle(secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.50), lineWidth: 1)
        )
    }

    // MARK: - Lightbox Overlay
    private var lightboxOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissLightbox()
                }
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismissLightbox()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
                
                Spacer()
                
                if let previewURL = templatePreviewURL {
                    WebImage(url: previewURL)
                        .resizable()
                        .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 500)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: Color.black.opacity(0.35), radius: 24, x: 0, y: 12)
                    .padding(.horizontal, 24)
                }
                
                Spacer()
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.92)))

    }


    
    private func dismissLightbox() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showLightbox = false
        }
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
                        .stroke(isSelected ? Color(hex: "2D2422") : Color(hex: "8D7F7A"), lineWidth: 2)
                        .frame(width: shapeWidth, height: shapeHeight)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
                .frame(height: 44)

                Text(ratio)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(isSelected ? Color(hex: "2D2422") : Color(hex: "8D7F7A"))
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
                    ? Color(hex: "FF4D85").opacity(0.08)
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
