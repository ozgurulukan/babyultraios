import SwiftUI

// MARK: - Processing / Generation Loading View
struct ProcessingImage: View {
    @State var image: UIImage?
    var operation: OperationType
    var promptText: String = ""

    @State private var vm = Operation()
    @State private var isResult  = false
    @State private var isUpscale = false
    @State private var isPrompt  = false
    @State private var processedImage: UIImage?

    // Loading animation state
    @State private var progress: CGFloat = 0
    @State private var statusText = "Initializing..."
    @State private var spinnerRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    @StateObject private var counter = CoinCounter()
    @EnvironmentObject private var entitlementManager: EntitlementManager

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
                    // Top bar
                    topBar
                    Spacer()
                    // Central loading UI
                    loadingCore
                    Spacer()
                    Spacer()
                }
            }
            .toolbar(.hidden)
            .navigationDestination(isPresented: $isUpscale) {
                Upscaling(image: image, operation: .Upscaling)
            }
            .navigationDestination(isPresented: $isResult) {
                ResultView(resultImage: processedImage, operationType: operation)
            }
            .navigationDestination(isPresented: $isPrompt) {
                PrompotView(image: image, operation: operation)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { startProcessing() }
    }

    // MARK: Top Bar
    var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(operation.rawValue)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                Text("Processing your request")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Luris.textSecondary)
            }
            Spacer()
            if !entitlementManager.hasPro {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Luris.accent)
                    Text("\(counter.coins) left")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Luris.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "2A2A3E"), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    // MARK: Loading Core
    var loadingCore: some View {
        VStack(spacing: 36) {
            // Spinner + preview
            ZStack {
                // Background track ring
                Circle()
                    .stroke(Luris.surface, lineWidth: 4)
                    .frame(width: 264, height: 264)

                // Image preview or placeholder
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
                            .fill(Luris.card)
                            .frame(width: 220, height: 220)
                        Image(systemName: "wand.and.sparkles")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(Luris.accent.opacity(0.5))
                    }
                }

                // Lime spinner arc
                SpinnerArc()
                    .frame(width: 264, height: 264)

                // Pulsing dot indicator
                Circle()
                    .fill(Luris.accentRose)
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulseScale)
                    .offset(y: -132)
                    .rotationEffect(.degrees(spinnerRotation))
                    .shadow(color: Luris.accentRose.opacity(0.7), radius: 8)
            }

            // Status text
            VStack(spacing: 10) {
                Text("Generating animation...")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)

                Text(statusText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Luris.textSecondary)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                    .id(statusText)
                    .animation(.easeInOut(duration: 0.4), value: statusText)
            }

            // Progress bar + percentage
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Luris.surface)
                            .frame(height: 7)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Luris.progressGradient)
                            .frame(width: geo.size.width * progress, height: 7)
                            .animation(.easeInOut(duration: 0.6), value: progress)
                            .shadow(color: Luris.accentRose.opacity(0.5), radius: 6)
                    }
                }
                .frame(height: 7)

                HStack {
                    Text("Processing")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [Luris.accent, Luris.accentRose], startPoint: .leading, endPoint: .trailing)
                        )
                        .monospacedDigit()
                }
            }
            .padding(.horizontal, 36)
        }
    }

    // MARK: Processing Logic
    func startProcessing() {
        animateSpinner()
        animateProgress()

        switch operation {
        case .Upscaling:
            isUpscale = true

        case .Reimagine:
            vm.reimagineImage(var: image) { img in
                processedImage = img
                if img != nil { isResult = true }
            }

        case .RemoveBackground:
            vm.RemoveBackground(var: image) { img in
                processedImage = img
                if img != nil { isResult = true }
            }

        case .RemoveText:
            vm.RemoveText(var: image) { img in
                processedImage = img
                if img != nil { isResult = true }
            }

        case .ReplaceBackground, .SketchToImage:
            isPrompt = true

        case .TextToImage:
            vm.TextToImage(text: promptText) { img in
                processedImage = img
                if img != nil { isResult = true }
            }
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

// MARK: - Spinning Arc
struct SpinnerArc: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.28)
            .stroke(Luris.spinnerGradient, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .rotationEffect(.degrees(rotation))
            .shadow(color: Luris.accentRose.opacity(0.5), radius: 8)
            .onAppear {
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
