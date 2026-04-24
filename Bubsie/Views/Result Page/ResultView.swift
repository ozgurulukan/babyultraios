import SwiftUI
import Photos
import AVKit

// MARK: - Result Screen (Liquid Glass Edition)
struct ResultView: View {
    let resultURL: String
    let actionType: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthManager.shared
    @StateObject private var counter = CoinCounter()

    @State private var showToast = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var backgroundImage: Color = .clear

    @State private var showReportSheet = false
    @State private var selectedReportReason: String? = nil
    @State private var reportDetails = ""
    @State private var reportSending = false
    @State private var showReportSent = false

    // Colors
    private let bgColor = Color(hex: "FFF8F6")
    private let secondaryText = Color(hex: "53433F")
    private let accentBrown = Color(hex: "8E4C3A")
    private let successGreen = Color(hex: "7ADDBD")
    private let darkText = Color(hex: "221A18")

    private var resultExtension: String {
        URL(string: resultURL)?.pathExtension.lowercased() ?? ""
    }
    private var isVideoResult: Bool {
        let videoExts = ["mp4", "mov", "m4v", "webm"]
        return actionType == "video" || videoExts.contains(resultExtension)
    }
    private var isSupportedResultFormat: Bool {
        let supported = ["jpg", "jpeg", "png", "mp4"]
        return supported.contains(resultExtension) || (actionType == "video" && resultExtension.isEmpty)
    }

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
                            dismiss()
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

                    // Result Card
                    resultCard
                        .padding(.horizontal, 20)

                    if actionType == "remove_bg" {
                        bgPicker
                            .padding(.horizontal, 20)
                    }

                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                }
            }

            if showToast {
                downloadToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showShareSheet) {
            if !shareItems.isEmpty {
                ActivityView(activityItems: shareItems)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            reportSheet
                .presentationDetents([.fraction(0.55)])
                .presentationDragIndicator(.visible)
        }
        .alert("Report Sent", isPresented: $showReportSent) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Thank you for helping keep our community safe.")
        }
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

    // MARK: Result Card
    private var resultCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.70), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)

            VStack(spacing: 16) {
                // Media
                Group {
                    if !isSupportedResultFormat {
                        errorPlaceholder(message: "Unsupported format. Supported: jpg, jpeg, png, mp4")
                    } else if isVideoResult, let videoURL = URL(string: resultURL) {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        AsyncImage(url: URL(string: resultURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                            case .failure:
                                errorPlaceholder(message: "Failed to load")
                            default:
                                ProgressView()
                                    .tint(accentBrown)
                                    .frame(maxWidth: .infinity, minHeight: 200)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )

                // Badge + Report
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(accentBrown)
                        Text("Magic Enhanced")
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

                    Button {
                        showReportSheet = true
                    } label: {
                        Text("🚩")
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.70))
                            .overlay(Capsule().stroke(Color.white.opacity(0.9), lineWidth: 1))
                    )
                    .shadow(color: Color(hex: "8E4C3A").opacity(0.12), radius: 8, x: 0, y: 4)
                }
            }
            .padding(12)
        }
    }

    private func errorPlaceholder(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 28))
                .foregroundStyle(secondaryText)
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .background(Color.white.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: Background Picker (for remove_bg)
    private var bgPicker: some View {
        HStack(spacing: 12) {
            Text("Background:")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(secondaryText)

            HStack(spacing: 10) {
                bgButton(color: .clear, label: "Transparent")
                bgButton(color: .white, label: "White")
                bgButton(color: .black, label: "Black")
                bgButton(color: Color(hex: "FFB5A0"), label: "Peach")
            }

            Spacer()
        }
    }

    private func bgButton(color: Color, label: String) -> some View {
        Button {
            backgroundImage = color
        } label: {
            VStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color == .clear ? Color.white.opacity(0.50) : color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.60), lineWidth: 1)
                    )
                    .frame(width: 32, height: 32)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(secondaryText)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Save to Gallery
            Button {
                saveToPhotos()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Save to Gallery")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "8E4C3A").opacity(0.90),
                                    Color(hex: "FFB5A0").opacity(0.90),
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
                .shadow(color: Color(hex: "8E4C3A").opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(darkText)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.50))
                            .overlay(Capsule().stroke(Color.white.opacity(0.60), lineWidth: 1))
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button {
                    prepareShare()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Share")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundStyle(secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(
                        Capsule()
                            .fill(Color(hex: "FFDF8E").opacity(0.45))
                            .overlay(Capsule().stroke(Color.white.opacity(0.60), lineWidth: 1))
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Download Toast
    private var downloadToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "002016"))

            Text("Saved to Gallery")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Color(hex: "002016"))

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(successGreen.opacity(0.85))
                .overlay(Capsule().stroke(Color.white.opacity(0.50), lineWidth: 1))
        )
        .shadow(color: successGreen.opacity(0.30), radius: 16, x: 0, y: 6)
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 60)
    }

    // MARK: Actions
    private func saveToPhotos() {
        guard let url = URL(string: resultURL) else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if isVideoResult {
                    let ext = resultExtension.isEmpty ? "mp4" : resultExtension
                    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("bubsie-result-\(UUID().uuidString).\(ext)")
                    try data.write(to: tempURL, options: .atomic)
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempURL)
                    }
                } else {
                    guard let image = UIImage(data: data) else { return }
                    let finalImage = applyBackgroundIfNeeded(to: image)
                    UIImageWriteToSavedPhotosAlbum(finalImage, nil, nil, nil)
                }

                await MainActor.run {
                    withAnimation(.spring(response: 0.4)) {
                        showToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showToast = false
                        }
                    }
                }
            } catch {
                print("Save error: \(error)")
            }
        }
    }

    private func prepareShare() {
        guard let url = URL(string: resultURL) else { return }
        Task {
            if isVideoResult {
                await MainActor.run {
                    shareItems = [url]
                    showShareSheet = true
                }
                return
            }

            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    let finalImage = applyBackgroundIfNeeded(to: image)
                    await MainActor.run {
                        shareItems = [finalImage]
                        showShareSheet = true
                    }
                }
            } catch {
                print("Share error: \(error)")
            }
        }
    }

    private func applyBackgroundIfNeeded(to image: UIImage) -> UIImage {
        guard actionType == "remove_bg", backgroundImage != .clear else { return image }

        let uiBackgroundColor: UIColor
        if backgroundImage == .white {
            uiBackgroundColor = .white
        } else if backgroundImage == .black {
            uiBackgroundColor = .black
        } else {
            uiBackgroundColor = UIColor(backgroundImage)
        }

        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            uiBackgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Report Sheet
    private var reportSheet: some View {
        let reasons = [
            ("Inappropriate content (explicit, violence)", "inappropriate"),
            ("Unauthorized child photo", "unauthorized_child"),
            ("Copyright infringement", "copyright"),
            ("Other", "other"),
        ]

        return VStack(spacing: 0) {
            // Handle + Title
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.4))
                    .frame(width: 36, height: 5)

                Text("Why are you reporting this?")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(darkText)
            }
            .padding(.top, 12)
            .padding(.bottom, 8)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach(reasons, id: \.1) { label, key in
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedReportReason = key
                            }
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: selectedReportReason == key ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(selectedReportReason == key ? accentBrown : secondaryText.opacity(0.5))

                                Text(label)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(darkText)
                                    .multilineTextAlignment(.leading)

                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(selectedReportReason == key ? Color(hex: "8E4C3A").opacity(0.08) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)

                        if key != reasons.last?.1 {
                            Divider()
                                .padding(.horizontal, 20)
                                .opacity(0.4)
                        }
                    }
                }
                .padding(.horizontal, 12)

                if selectedReportReason == "other" {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Details")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(secondaryText)

                        TextEditor(text: $reportDetails)
                            .font(.system(size: 14))
                            .frame(minHeight: 80, maxHeight: 120)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.50))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .stroke(Color.white.opacity(0.60), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                }
            }

            Spacer()

            // Submit
            Button {
                sendReport()
            } label: {
                HStack(spacing: 8) {
                    if reportSending {
                        ProgressView()
                            .tint(.white)
                            .scaleEffect(0.8)
                    }
                    Text(reportSending ? "Sending..." : "Submit")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    Capsule()
                        .fill(
                            selectedReportReason == nil || reportSending
                                ? AnyShapeStyle(Color.gray.opacity(0.35))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [
                                        Color(hex: "8E4C3A").opacity(0.90),
                                        Color(hex: "FFB5A0").opacity(0.90),
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                        )
                )
                .shadow(color: selectedReportReason == nil ? Color.clear : Color(hex: "8E4C3A").opacity(0.25), radius: 12, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(selectedReportReason == nil || reportSending)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .padding(.top, 8)
        }
        .background(bgColor.ignoresSafeArea())
    }

    private func sendReport() {
        guard let reason = selectedReportReason else { return }
        reportSending = true
        Task {
            do {
                try await BubsieAPI.shared.submitReport(
                    resultURL: resultURL,
                    reason: reason,
                    details: reportDetails.isEmpty ? nil : reportDetails
                )
                await MainActor.run {
                    reportSending = false
                    showReportSheet = false
                    selectedReportReason = nil
                    reportDetails = ""
                    showReportSent = true
                }
            } catch {
                await MainActor.run {
                    reportSending = false
                }
            }
        }
    }
}

#Preview {
    ResultView(
        resultURL: Bundle.main.url(forResource: "defaulttemplate", withExtension: "png")?.absoluteString ?? "",
        actionType: "image"
    )
    .environmentObject(EntitlementManager())
}
