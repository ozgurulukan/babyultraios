import SwiftUI
import Photos
import AVKit

// MARK: - Result Screen (Warm Edition)
struct ResultView: View {
    let resultURL: String
    let actionType: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var auth = AuthManager.shared
    @StateObject private var counter = CoinCounter()

    @State private var savedAlert = false
    @State private var showToast = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var backgroundImage: Color = .clear

    // Design colors
    private let bgColor = Color(hex: "FFF8F6")
    private let primaryText = Color(hex: "231917")
    private let secondaryText = Color(hex: "53433F")
    private let accentBrown = Color(hex: "8E4C3A")
    private let accentCoral = Color(hex: "FFB5A0")
    private let starYellow = Color(hex: "FFDF8E")
    private let successGreen = Color(hex: "7ADDBD")
    private let darkText = Color(hex: "221A18")

    var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }
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
    private var mediaHeight: CGFloat {
        min(max(UIScreen.main.bounds.height * 0.42, 280), 340)
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            backgroundGlows

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, 24)
                        .padding(.top, 16)

                    resultCanvas
                        .padding(.horizontal, 24)
                        .padding(.top, 32)

                    if actionType == "remove_bg" {
                        bgPicker
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                    }

                    actionButtons
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 88)
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
    }

    // MARK: Background Glows
    private var backgroundGlows: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "FFB5A0").opacity(0.30))
                .frame(width: 384, height: 384)
                .blur(radius: 50)
                .offset(x: -120, y: -250)

            Circle()
                .fill(Color(hex: "FFDF8E").opacity(0.20))
                .frame(width: 480, height: 480)
                .blur(radius: 60)
                .offset(x: 50, y: 100)

            Circle()
                .fill(Color(hex: "7ADDBD").opacity(0.20))
                .frame(width: 400, height: 400)
                .blur(radius: 50)
                .offset(x: 80, y: 500)
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

            Text("Bubsie")
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(accentBrown)
                .tracking(-0.8)
                .padding(.leading, 10)

            Spacer()
        }
    }

    // MARK: Result Canvas
    private var resultCanvas: some View {
        ZStack {
            // Decorative blobs behind
            Circle()
                .fill(Color(hex: "FFDAD2").opacity(0.60))
                .frame(width: 256, height: 256)
                .blur(radius: 32)
                .offset(x: 60, y: -80)

            Circle()
                .fill(Color(hex: "FFDF8E").opacity(0.50))
                .frame(width: 192, height: 192)
                .blur(radius: 20)
                .offset(x: -60, y: 120)

            // Glassmorphism card
            VStack(spacing: 0) {
                Group {
                    if !isSupportedResultFormat {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 32))
                                .foregroundStyle(secondaryText)
                            Text("Unsupported format. Supported: jpg, jpeg, png, mp4")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.white.opacity(0.20))
                    } else if isVideoResult, let videoURL = URL(string: resultURL) {
                        VideoPlayer(player: AVPlayer(url: videoURL))
                    } else {
                        AsyncImage(url: URL(string: resultURL)) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                            case .failure:
                                VStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 32))
                                        .foregroundStyle(secondaryText)
                                    Text("Failed to load")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(secondaryText)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.white.opacity(0.20))
                            default:
                                ProgressView()
                                    .tint(accentBrown)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.white.opacity(0.20))
                            }
                        }
                    }
                }
                .frame(height: mediaHeight)
                .clipShape(RoundedRectangle(cornerRadius: 32))
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .fill(Color.black.opacity(0.03))
                )
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 2)

                // Floating badge
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accentBrown)

                    Text("Magic Enhanced")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(accentBrown)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.60))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.80), lineWidth: 1)
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "8E4C3A").opacity(0.20), radius: 24, x: 0, y: 8)
                .offset(y: -20)
            }
            .padding(12)
            .background(Color.white.opacity(0.30))
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(Color.white.opacity(0.60), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 40))
            .shadow(color: Color(hex: "8E4C3A").opacity(0.12), radius: 28, x: 0, y: 12)
        }
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
        VStack(spacing: 16) {
            // Save to Gallery
            Button {
                saveToPhotos()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    Text("Save to Gallery")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    LinearGradient(
                        colors: [
                            Color(hex: "8E4C3A").opacity(0.90),
                            Color(hex: "FFB5A0").opacity(0.90),
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "8E4C3A").opacity(0.40), radius: 32, x: 0, y: -8)
            }
            .buttonStyle(.plain)

            Button {
                dismiss()
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(darkText)

                    Text("Back to Templates")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(darkText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color.white.opacity(0.40))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.50), lineWidth: 1)
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "8E4C3A").opacity(0.08), radius: 24, x: 0, y: 8)
            }
            .buttonStyle(.plain)

            // Share to Social
            Button {
                prepareShare()
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(secondaryText)

                    Text("Share to Social")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(hex: "FFDF8E").opacity(0.40))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.50), lineWidth: 1)
                )
                .clipShape(Capsule())
                .shadow(color: Color(hex: "8E4C3A").opacity(0.08), radius: 24, x: 0, y: 8)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: Download Toast
    private var downloadToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(Color(hex: "002016"))

            Text("Download\nComplete")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(hex: "002016"))
                .lineLimit(2)

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(successGreen.opacity(0.70))
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.40), lineWidth: 1)
        )
        .clipShape(Capsule())
        .shadow(color: successGreen.opacity(0.30), radius: 32, x: 0, y: 8)
        .background(.ultraThinMaterial.opacity(0.3))
        .padding(.horizontal, 24)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.top, 80)
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

        // Convert SwiftUI Color to UIColor for rendering
        let uiBackgroundColor: UIColor
        if backgroundImage == .white {
            uiBackgroundColor = .white
        } else if backgroundImage == .black {
            uiBackgroundColor = .black
        } else {
            // For custom colors (like peach), extract components
            uiBackgroundColor = UIColor(backgroundImage)
        }

        let size = image.size
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Fill background
            uiBackgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            // Draw original image on top
            image.draw(in: CGRect(origin: .zero, size: size))
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
