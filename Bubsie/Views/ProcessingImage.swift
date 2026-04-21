import SwiftUI
import UserNotifications

struct ProcessingImage: View {
    let image: UIImage?
    let template: TemplateItem
    var aspectRatio: String? = nil
    var promptText: String = ""
    var momImageURL: String? = nil
    var babyImageURL: String? = nil
    var dadImageURL: String? = nil
    var onBackToTemplates: (() -> Void)? = nil

    @State private var isResult = false
    @State private var resultURL: String? = nil
    @State private var errorMessage: String? = nil
    @State private var progress: CGFloat = 0
    @State private var statusText = "Preparing your transform..."
    @State private var spinnerRotation: Double = 0
    @State private var notifyWhenDone = true
    @State private var isSubmitting = false

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @StateObject private var auth = AuthManager.shared
    @StateObject private var counter = CoinCounter()

    private let statusMessages = [
        "Analyzing photo...",
        "Applying template...",
        "Generating details...",
        "Finalizing output..."
    ]

    var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }

    var body: some View {
        ZStack {
            Color(hex: "FFF8F6").ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)

                VStack(spacing: 24) {
                    previewCard
                    progressCard
                    actionsCard
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $isResult) {
            if let url = resultURL {
                ResultView(resultURL: url, actionType: template.actionType)
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear { startProcessing() }
    }

    private var topBar: some View {
        HStack {
            Text(template.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "8F4C38"))
                .lineLimit(1)

            Spacer()

            if !entitlementManager.hasPro {
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
        }
    }

    private var previewCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.75), lineWidth: 1)
                )

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
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .padding(14)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color(hex: "8F4C38").opacity(0.14), lineWidth: 1)
            )
        }
        .frame(height: 260)
    }

    private var progressCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                Circle()
                    .trim(from: 0.15, to: 0.95)
                    .stroke(
                        LinearGradient(colors: [Color(hex: "8F4C38"), Color(hex: "C07B64")], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 26, height: 26)
                    .rotationEffect(.degrees(spinnerRotation))
                Text(statusText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color(hex: "3A2A26"))
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: "8F4C38"))
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "E8D8D2"))
                    Capsule()
                        .fill(LinearGradient(colors: [Color(hex: "8F4C38"), Color(hex: "C07B64")], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(10, geo.size.width * progress))
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.78), lineWidth: 1)
        )
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button {
                notifyWhenDone.toggle()
            } label: {
                HStack {
                    Image(systemName: notifyWhenDone ? "bell.badge.fill" : "bell")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Notify me when it's completed")
                        .font(.system(size: 14, weight: .semibold))
                    Spacer()
                    Image(systemName: notifyWhenDone ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundStyle(Color(hex: "8F4C38"))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.72))
                )
            }
            .buttonStyle(.plain)

            Button {
                onBackToTemplates?()
                if onBackToTemplates == nil {
                    dismiss()
                }
            } label: {
                Text("Back to other templates")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "4B3935"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: "EFE1DB"))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.60))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.78), lineWidth: 1)
        )
    }

    private func startProcessing() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            spinnerRotation = 360
        }
        animateProgress()
        Task { await processImage() }
    }

    private func processImage() async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }

        do {
            guard let image else {
                errorMessage = "No image selected"
                return
            }

            let result = try await BubsieAPI.shared.uploadAndTransform(
                image: image,
                template: template,
                aspectRatio: aspectRatio ?? template.aspectRatio,
                momImageURL: momImageURL,
                babyImageURL: babyImageURL,
                dadImageURL: dadImageURL
            )

            await AuthManager.shared.fetchProfile()

            if notifyWhenDone {
                await sendCompletionNotification()
            }

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

    private func sendCompletionNotification() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your result is ready"
        content.body = "\(template.name) has completed. Tap to view it."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "bubsie-transform-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        try? await center.add(request)
    }
}
