import SwiftUI

// MARK: - Transform Configuration Screen
struct TransformView: View {
    let template: TemplateItem

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @StateObject private var auth = AuthManager.shared
    @StateObject private var counter = CoinCounter()

    @State private var selectedImage: UIImage?
    @State private var selectedAspectRatio: String = "1:1"
    @State private var showImagePicker = false
    @State private var isProcessing = false

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
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                backgroundGlows

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        topBar
                            .padding(.horizontal, 24)
                            .padding(.top, 16)

                        VStack(spacing: 24) {
                            headerSection
                                .padding(.top, 32)

                            photoUploadSection
                                .padding(.horizontal, 24)

                            aspectRatioSection
                                .padding(.horizontal, 24)

                            Spacer(minLength: 40)
                        }
                    }
                }

                bottomCTA
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .navigationDestination(isPresented: $isProcessing) {
                if let img = selectedImage {
                    ProcessingImage(
                        image: img,
                        template: template,
                        aspectRatio: selectedAspectRatio
                    )
                }
            }
        }
        .preferredColorScheme(.light)
    }

    // MARK: Background Glows
    private var backgroundGlows: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFE0A8").opacity(0.50))
                .frame(width: 273, height: 273)
                .blur(radius: 50)
                .offset(x: -100, y: -300)

            Circle()
                .fill(Color(hex: "FFDBD1").opacity(0.40))
                .frame(width: 234, height: 234)
                .blur(radius: 50)
                .offset(x: 120, y: 50)

            Circle()
                .fill(Color(hex: "FFDBD1").opacity(0.50))
                .frame(width: 312, height: 312)
                .blur(radius: 50)
                .offset(x: 50, y: 400)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: Top Bar
    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentBrown)
                    .frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Bubsie")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accentBrown)
                .tracking(-0.45)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "star.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(hex: "97462E"))
                Text("\(displayCredits) Credits")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color(hex: "97462E"))
                    .tracking(-0.3)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: "FAF3E0").opacity(0.60))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.60), lineWidth: 1))
            .background(.ultraThinMaterial.opacity(0.3))

            Button {} label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentBrown)
                    .frame(width: 40, height: 40)
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

            Text("Upload a photo to see the magic happen.")
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    // MARK: Photo Upload
    private var photoUploadSection: some View {
        Button {
            showImagePicker = true
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
                    .frame(height: 120)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 40))

                if let img = selectedImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 420)
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

                        Text("Tap to upload photo")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(primaryText)

                        Text("Clear face, good lighting")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(secondaryText)
                    }
                    .padding(.vertical, 80)
                }
            }
            .frame(height: 420)
        }
        .buttonStyle(.plain)
    }

    // MARK: Aspect Ratio Selection
    private var aspectRatioSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Aspect Ratio")
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
                        showImagePicker = true
                        return
                    }
                    isProcessing = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Transform (\(template.creditCost) Credit\(template.creditCost == 1 ? "" : "s"))")
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
}
