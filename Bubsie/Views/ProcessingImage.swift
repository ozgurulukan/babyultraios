import SwiftUI

struct ProcessingImage: View {
    let image: UIImage?
    let template: TemplateItem
    var aspectRatio: String? = nil
    var promptText: String = ""
    var momImageURL: String? = nil
    var babyImageURL: String? = nil
    var dadImageURL: String? = nil
    var videoURL: String? = nil
    var onBackToTemplates: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var isResult = false
    @State private var resultURL: String? = nil
    @State private var errorMessage: String? = nil
    @State private var progress: CGFloat = 0
    @State private var statusText = NSLocalizedString("processing.status_preparing", comment: "")
    @State private var notifyWhenDone = true
    @State private var isSubmitting = false

    private let statusMessages = [
        NSLocalizedString("processing.status_catching", comment: ""),
        NSLocalizedString("processing.status_styling", comment: ""),
        NSLocalizedString("processing.status_wonder", comment: ""),
        NSLocalizedString("processing.status_debut", comment: "")
    ]

    private let bgColor = Color(hex: "FFF8F6")
    private let accentBrown = Color(hex: "8E4C3A")

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            backgroundGlows

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // Close button
                    HStack {
                        Spacer()
                        Button {
                            if let onBack = onBackToTemplates {
                                onBack()
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color(hex: "231917"))
                                .frame(width: 32, height: 32)
                                .background(
                                    Circle()
                                        .fill(.ultraThinMaterial)
                                        .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Preview Card
                    previewCard
                        .padding(.horizontal, 20)

                    // Progress Card
                    progressCard
                        .padding(.horizontal, 20)

                    // Actions
                    actionsCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isResult) {
            if let url = resultURL {
                ResultView(resultURL: url, actionType: template.actionType)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
        .alert(NSLocalizedString("common.error", comment: ""), isPresented: .constant(errorMessage != nil)) {
            Button(NSLocalizedString("common.ok", comment: "")) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear { startProcessing() }
    }

    // MARK: Background Glows
    private var backgroundGlows: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFB5A0").opacity(0.30))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .offset(x: -100, y: -200)

            Circle()
                .fill(Color(hex: "FFDF8E").opacity(0.20))
                .frame(width: 350, height: 350)
                .blur(radius: 70)
                .offset(x: 80, y: 50)
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: Preview Card
    private var previewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.70), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)

            VStack(spacing: 12) {
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        ZStack {
                            Color(hex: "F3E7E2")
                            Image(systemName: "photo")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundStyle(Color(hex: "8F4C38").opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, minHeight: 200)
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )

                // Status badge
                HStack(spacing: 6) {
                    ProgressView()
                        .tint(accentBrown)
                        .scaleEffect(0.8)
                    Text(NSLocalizedString("processing.status_processing", comment: ""))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(accentBrown)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.70))
                        .overlay(Capsule().stroke(Color.white.opacity(0.9), lineWidth: 1))
                )
                .shadow(color: Color(hex: "8E4C3A").opacity(0.12), radius: 8, x: 0, y: 4)
            }
            .padding(12)
        }
    }

    // MARK: Progress Card
    private var progressCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Text(statusText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "3A2A26"))

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(accentBrown)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "E8D8D2"))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "8F4C38"), Color(hex: "C07B64")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(10, geo.size.width * progress))
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.70), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)
        )
    }

    // MARK: Actions Card
    private var actionsCard: some View {
        VStack(spacing: 12) {
            // Notify toggle
            Button {
                notifyWhenDone.toggle()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: notifyWhenDone ? "bell.badge.fill" : "bell")
                        .font(.system(size: 16, weight: .semibold))
                    Text(NSLocalizedString("processing.notify_me", comment: ""))
                        .font(.system(size: 15, weight: .semibold))
                    Spacer()
                    Image(systemName: notifyWhenDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundStyle(accentBrown)
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 16)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.50))
                        .overlay(Capsule().stroke(Color.white.opacity(0.60), lineWidth: 1))
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // Back to templates
            Button {
                if let onBack = onBackToTemplates {
                    onBack()
                } else {
                    dismiss()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 16, weight: .semibold))
                    Text(NSLocalizedString("processing.back_to_templates", comment: ""))
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(Color(hex: "221A18"))
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.50))
                        .overlay(Capsule().stroke(Color.white.opacity(0.60), lineWidth: 1))
                )
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Processing
    private func startProcessing() {
        guard !isSubmitting else { return }
        isSubmitting = true

        animateProgress()
        Task { await processImage() }
    }

    private func processImage() async {
        defer { isSubmitting = false }

        do {
            guard let image else {
                errorMessage = NSLocalizedString("processing.no_image_error", comment: "")
                return
            }

            let result = try await BubsieAPI.shared.uploadAndTransform(
                image: image,
                template: template,
                aspectRatio: aspectRatio ?? template.aspectRatio,
                momImageURL: momImageURL,
                babyImageURL: babyImageURL,
                dadImageURL: dadImageURL,
                videoURL: videoURL ?? template.referenceVideoUrl,
                notifyWhenDone: notifyWhenDone
            )

            await AuthManager.shared.fetchProfile()

            resultURL = result.resultUrl
            isResult = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func animateProgress() {
        for i in 0..<statusMessages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.2) {
                withAnimation(.easeInOut(duration: 0.45)) {
                    progress = CGFloat(i + 1) / CGFloat(statusMessages.count + 1)
                    statusText = statusMessages[i]
                }
            }
        }
    }
}

#Preview {
    ProcessingImage(
        image: UIImage(systemName: "photo"),
        template: TemplateItem(
            id: 1,
            appId: "preview",
            slug: "preview",
            name: "Preview",
            description: nil,
            actionType: "image",
            prompt: "",
            negativePrompt: nil,
            provider: "",
            model: nil,
            categoryId: 1,
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
            isFeatured: false,
            isPopular: false,
            isViral: false,
            isPremium: false,
            sortOrder: 0
        )
    )
}
