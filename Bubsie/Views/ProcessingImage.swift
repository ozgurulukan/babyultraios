import SwiftUI

struct ProcessingImage: View {
    let image: UIImage?
    let template: TemplateItem
    var aspectRatio: String? = nil
    var promptText: String = ""
    var momImageURL: String? = nil
    var babyImageURL: String? = nil
    var dadImageURL: String? = nil

    @State private var isResult = false
    @State private var resultURL: String? = nil
    @State private var errorMessage: String? = nil
    @State private var progress: CGFloat = 0
    @State private var statusText = "Initializing..."
    @State private var spinnerRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    @EnvironmentObject private var entitlementManager: EntitlementManager
    @StateObject private var counter = CoinCounter()

    private let statusMessages = [
        "Analyzing content...",
        "Applying AI model...",
        "Generating output...",
        "Refining details...",
        "Almost ready...",
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedMeshBG()

                VStack(spacing: 0) {
                    topBar
                    Spacer()
                    loadingCore
                    Spacer()
                    Spacer()
                }
            }
            .toolbar(.hidden)
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
        }
        .preferredColorScheme(.dark)
        .onAppear { startProcessing() }
    }

    var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Processing your request")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Bubsie.textSecondary)
            }
            Spacer()
            if !entitlementManager.hasPro {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Bubsie.accent)
                    Text("\(counter.coins) left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Bubsie.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "2A2A3E"), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    var loadingCore: some View {
        VStack(spacing: 36) {
            ZStack {
                Circle()
                    .stroke(Bubsie.surface, lineWidth: 4)
                    .frame(width: 264, height: 264)

                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.black.opacity(0.45))
                        )
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Bubsie.card)
                            .frame(width: 220, height: 220)
                        Image(systemName: "wand.and.sparkles")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(Bubsie.accent.opacity(0.5))
                    }
                }

                SpinnerArc()
                    .frame(width: 264, height: 264)

                Circle()
                    .fill(Bubsie.accentRose)
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulseScale)
                    .offset(y: -132)
                    .rotationEffect(.degrees(spinnerRotation))
                    .shadow(color: Bubsie.accentRose.opacity(0.7), radius: 8)
            }

            VStack(spacing: 10) {
                Text("Generating animation...")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)

                Text(statusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Bubsie.textSecondary)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id(statusText)
                    .animation(.easeInOut(duration: 0.4), value: statusText)
            }

            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Bubsie.surface)
                            .frame(height: 7)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Bubsie.progressGradient)
                            .frame(width: geo.size.width * progress, height: 7)
                            .animation(.easeInOut(duration: 0.6), value: progress)
                            .shadow(color: Bubsie.accentRose.opacity(0.5), radius: 6)
                    }
                }
                .frame(height: 7)

                HStack {
                    Text("Processing")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Bubsie.textSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [Bubsie.accent, Bubsie.accentRose], startPoint: .leading, endPoint: .trailing)
                        )
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 36)
        }
    }

    func startProcessing() {
        animateSpinner()
        animateProgress()
        Task { await processImage() }
    }

    func processImage() async {
        do {
            guard let image = image else {
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
            resultURL = result.resultUrl
            isResult = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func animateSpinner() {
        withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
            spinnerRotation = 360
        }
        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
            pulseScale = 1.6
        }
    }

    func animateProgress() {
        for i in 0..<statusMessages.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 1.8) {
                withAnimation { progress = CGFloat(i + 1) / CGFloat(statusMessages.count) }
                statusText = statusMessages[i]
            }
        }
    }
}

struct SpinnerArc: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.28)
            .stroke(Bubsie.spinnerGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .rotationEffect(.degrees(rotation))
            .shadow(color: Bubsie.accentRose.opacity(0.5), radius: 8)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}