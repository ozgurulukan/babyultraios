import SwiftUI
import AVFoundation
import StoreKit
import SDWebImageSwiftUI

// MARK: - ViewModel
@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var onboardingItems: [OnboardingMedia] = []
    @Published var reviews: [UserReview] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            async let onboardingTask = BubsieAPI.shared.getOnboarding()
            async let reviewsTask = BubsieAPI.shared.getReviews()
            let (items, revs) = try await (onboardingTask, reviewsTask)
            print("[Onboarding] Loaded \(items.count) items, \(revs.count) reviews")
            for item in items {
                print("[Onboarding] item id=\(item.id) type=\(item.type) app_id=\(item.sortOrder) mediaUrl=\(item.mediaUrl)")
            }
            self.onboardingItems = items.sorted { $0.sortOrder < $1.sortOrder }
            self.reviews = revs.sorted { $0.sortOrder < $1.sortOrder }
        } catch {
            print("[Onboarding] ERROR: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    var firstItem: OnboardingMedia? {
        onboardingItems.first
    }

    var secondItem: OnboardingMedia? {
        onboardingItems.dropFirst().first
    }
}

// MARK: - Liquid Glass Button
private struct LiquidGlassButton: View {
    let title: String
    let action: () -> Void

    private let accentBrown = Color(hex: "A66A54")
    private let accentCoral = Color(hex: "F08C6E")

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [accentBrown, accentCoral],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .shadow(color: Color(hex: "904A33").opacity(0.35), radius: 20, x: 0, y: 8)
            .overlay(
                Capsule()
                    .stroke(Color.white.opacity(0.45), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Page 1: Photo Before/After
private struct OnboardingBeforeAfterView: View {
    let item: OnboardingMedia
    let onNext: () -> Void

    @State private var sliderPosition: CGFloat = 0.5
    @State private var dragStartPosition: CGFloat = 0.5
    @State private var isAutoAnimating = true

    private let bgColor = Color(hex: "F6ECE6")
    private let accent = Color(hex: "A66A54")

    var body: some View {
        GeometryReader { geo in
            ZStack {
                bgColor.ignoresSafeArea()
                VStack(spacing: 0) {
                    sliderSection
                    bottomBar
                }

                topBlurOverlay(height: geo.size.height * 0.25)
                    .ignoresSafeArea(edges: .top)
            }
        }
        .onAppear { startAutoAnimation() }
    }

    private func topBlurOverlay(height: CGFloat) -> some View {
        ZStack {
            // Material blur with gradient mask for smooth fade-out
            Color.clear
                .background(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // White tint overlay with fade-out
            LinearGradient(
                colors: [
                    Color.white.opacity(0.50),
                    Color.white.opacity(0.30),
                    Color.white.opacity(0.10),
                    Color.white.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: height)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func startAutoAnimation() {
        guard isAutoAnimating else { return }
        withAnimation(.easeInOut(duration: 1.2)) {
            sliderPosition = 0.7
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard self.isAutoAnimating else { return }
            withAnimation(.easeInOut(duration: 1.2)) {
                self.sliderPosition = 0.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.startAutoAnimation()
            }
        }
    }

    private var sliderSection: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let currentX = width * sliderPosition
            let clampedX = min(max(currentX, 0), width)
            ZStack {
                afterImage
                    .frame(width: width, height: height)
                    .clipped()
                beforeImage(clampedX: clampedX, height: height)
                    .frame(width: width, height: height)
                    .clipShape(LeftClipShape(width: clampedX, height: height))
                    .clipped()
                sliderHandle(clampedX: clampedX, height: height)
                infoCard
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width))
        }
    }

    private var afterImage: some View {
        WebImage(url: URL(string: item.mediaUrl)) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            placeholderGradient
        }
    }

    private func beforeImage(clampedX: CGFloat, height: CGFloat) -> some View {
        WebImage(url: item.thumbnailUrl.flatMap { URL(string: $0) }) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            placeholderGradient
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(hex: "D9CBC4"), Color(hex: "B5A69E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func sliderHandle(clampedX: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 3)
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 0)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 48, height: 48)
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                .overlay(
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
        }
        .position(x: clampedX, y: height / 2)
    }

    private var infoCard: some View {
        VStack(spacing: 10) {
            if let title = item.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
            }
            if let desc = item.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(accent.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 24)
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isAutoAnimating = false
                let newPosition = dragStartPosition + (value.translation.width / width)
                sliderPosition = min(max(newPosition, 0), 1)
            }
            .onEnded { _ in
                dragStartPosition = sliderPosition
            }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.5))
            LiquidGlassButton(title: "Next") {
                onNext()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 36)
            .background(
                Color.white.opacity(0.25)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            )
            .background(.ultraThinMaterial.opacity(0.35))
        }
    }

}

// MARK: - Page 2: Photo/Video Before/After
private struct OnboardingBeforeAfterVideoView: View {
    let item: OnboardingMedia
    let onNext: () -> Void

    @State private var sliderPosition: CGFloat = 0.5
    @State private var dragStartPosition: CGFloat = 0.5
    @State private var isAutoAnimating = true

    private let bgColor = Color(hex: "F6ECE6")
    private let accent = Color(hex: "A66A54")

    var body: some View {
        GeometryReader { geo in
            ZStack {
                bgColor.ignoresSafeArea()
                VStack(spacing: 0) {
                    sliderSection
                    bottomBar
                }

                topBlurOverlay(height: geo.size.height * 0.25)
                    .ignoresSafeArea(edges: .top)
            }
        }
        .onAppear { startAutoAnimation() }
    }

    private func topBlurOverlay(height: CGFloat) -> some View {
        ZStack {
            // Material blur with gradient mask for smooth fade-out
            Color.clear
                .background(.ultraThinMaterial)
                .mask(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color.white.opacity(0.7),
                            Color.white.opacity(0.3),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // White tint overlay with fade-out
            LinearGradient(
                colors: [
                    Color.white.opacity(0.50),
                    Color.white.opacity(0.30),
                    Color.white.opacity(0.10),
                    Color.white.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: height)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private func startAutoAnimation() {
        guard isAutoAnimating else { return }
        withAnimation(.easeInOut(duration: 1.2)) {
            sliderPosition = 0.7
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            guard self.isAutoAnimating else { return }
            withAnimation(.easeInOut(duration: 1.2)) {
                self.sliderPosition = 0.3
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                self.startAutoAnimation()
            }
        }
    }

    private var sliderSection: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let currentX = width * sliderPosition
            let clampedX = min(max(currentX, 0), width)
            ZStack {
                afterVideo
                    .frame(width: width, height: height)
                    .clipped()
                beforeImage(clampedX: clampedX, height: height)
                    .frame(width: width, height: height)
                    .clipShape(LeftClipShape(width: clampedX, height: height))
                    .clipped()
                sliderHandle(clampedX: clampedX, height: height)
                infoCard
            }
            .frame(width: width, height: height)
            .contentShape(Rectangle())
            .gesture(dragGesture(width: width))
        }
    }

    private var afterVideo: some View {
        Group {
            if let mediaURL = URL(string: item.mediaUrl) {
                LoopingOnboardingVideoView(url: mediaURL)
            } else {
                placeholderGradient
            }
        }
    }

    private func beforeImage(clampedX: CGFloat, height: CGFloat) -> some View {
        WebImage(url: item.thumbnailUrl.flatMap { URL(string: $0) }) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            placeholderGradient
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(hex: "D9CBC4"), Color(hex: "B5A69E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func sliderHandle(clampedX: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.85))
                .frame(width: 3)
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 0)
            Circle()
                .fill(.ultraThinMaterial)
                .frame(width: 48, height: 48)
                .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                .overlay(
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
        }
        .position(x: clampedX, y: height / 2)
    }

    private var infoCard: some View {
        VStack(spacing: 10) {
            if let title = item.title, !title.isEmpty {
                Text(title)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 2)
            }
            if let desc = item.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(accent.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 24)
    }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                isAutoAnimating = false
                let newPosition = dragStartPosition + (value.translation.width / width)
                sliderPosition = min(max(newPosition, 0), 1)
            }
            .onEnded { _ in
                dragStartPosition = sliderPosition
            }
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.5))
            LiquidGlassButton(title: "Next") {
                onNext()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 36)
            .background(
                Color.white.opacity(0.25)
                    .overlay(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            )
            .background(.ultraThinMaterial.opacity(0.35))
        }
    }
}

// MARK: - Looping Video Player for Onboarding
private struct LoopingOnboardingVideoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingOnboardingPlayerView {
        let view = LoopingOnboardingPlayerView()
        view.setVideoURL(url)
        return view
    }

    func updateUIView(_ uiView: LoopingOnboardingPlayerView, context: Context) {
        uiView.setVideoURL(url)
    }
}

private final class LoopingOnboardingPlayerView: UIView {
    private let player = AVQueuePlayer()
    private let playerLayer = AVPlayerLayer()
    private var looper: AVPlayerLooper?
    private var currentURL: URL?
    private var itemObserver: NSKeyValueObservation?
    private var timeObserver: Any?

    override init(frame: CGRect) {
        super.init(frame: frame)
        player.isMuted = true
        player.actionAtItemEnd = .none
        player.automaticallyWaitsToMinimizeStalling = false
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setVideoURL(_ url: URL) {
        guard currentURL != url else { return }
        currentURL = url
        player.removeAllItems()
        looper = nil
        itemObserver?.invalidate()
        if let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 6

        itemObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard item.status == .readyToPlay, let self = self, self.currentURL == url else { return }
            self.looper = AVPlayerLooper(player: self.player, templateItem: item)
            self.player.play()
            // Fade in player layer once playback actually starts
            self.timeObserver = self.player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.05, preferredTimescale: 600), queue: .main) { [weak self] time in
                guard let self = self else { return }
                if time.seconds > 0 && self.playerLayer.opacity == 0 {
                    self.playerLayer.opacity = 1
                }
            }
        }

        player.insert(item, after: nil)
        playerLayer.opacity = 0  // Hide until first frame renders
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

// MARK: - Page 3: Reviews
private struct OnboardingReviewsView: View {
    let reviews: [UserReview]
    let onGetStarted: () -> Void

    @Environment(\.requestReview) private var requestReview
    @State private var visibleReviews: [Bool]
    @State private var hasRequestedReview = false

    private let bgColor = Color(hex: "F6ECE6")
    private let textColor = Color(hex: "3F2D28")
    private let subtleText = Color(hex: "796B64")

    init(reviews: [UserReview], onGetStarted: @escaping () -> Void) {
        self.reviews = reviews
        self.onGetStarted = onGetStarted
        _visibleReviews = State(initialValue: Array(repeating: false, count: reviews.count))
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Loved by Parents")
                        .font(.system(size: 32, weight: .heavy))
                        .foregroundStyle(textColor)
                        .tracking(-0.8)

                    Text("Join thousands of happy families")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(subtleText)
                }
                .padding(.top, 24)
                .padding(.horizontal, 24)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(Array(reviews.enumerated()), id: \.element.id) { index, review in
                            ReviewBubble(
                                review: review,
                                isVisible: visibleReviews[safe: index] ?? false
                            )
                            .offset(x: visibleReviews[safe: index] == true ? 0 : 60)
                            .opacity(visibleReviews[safe: index] == true ? 1 : 0)
                            .animation(
                                .spring(response: 0.6, dampingFraction: 0.75)
                                .delay(Double(index) * 0.15),
                                value: visibleReviews[safe: index]
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 120)
                }
            }

            VStack(spacing: 0) {
                Spacer()

                LinearGradient(
                    colors: [bgColor.opacity(0), bgColor.opacity(0.95)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .allowsHitTesting(false)

                VStack(spacing: 0) {
                    Divider()
                        .background(Color.white.opacity(0.5))

                    LiquidGlassButton(title: "Get Started") {
                        onGetStarted()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 36)
                    .background(
                        Color.white.opacity(0.25)
                            .overlay(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.0)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                    )
                    .background(.ultraThinMaterial.opacity(0.35))
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                for index in reviews.indices {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.15) {
                        if visibleReviews.indices.contains(index) {
                            visibleReviews[index] = true
                        }
                    }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if !hasRequestedReview {
                    hasRequestedReview = true
                    requestReview()
                }
            }
        }
    }
}

// MARK: - Review Bubble (Liquid Glass)
private struct ReviewBubble: View {
    let review: UserReview
    let isVisible: Bool

    private let textColor = Color(hex: "3F2D28")
    private let subtleText = Color(hex: "796B64")
    private let accent = Color(hex: "A66A54")

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.opacity(0.15))
                    .frame(width: 48, height: 48)

                if let photoURL = review.photoUrl, let url = URL(string: photoURL) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        default:
                            initialsView
                        }
                    }
                    .frame(width: 46, height: 46)
                    .clipShape(Circle())
                } else {
                    initialsView
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(review.nickname)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(textColor)

                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(0..<5) { i in
                            Image(systemName: i < review.rating ? "star.fill" : "star")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(i < review.rating ? Color(hex: "D4A017") : Color.gray.opacity(0.4))
                        }
                    }
                }

                Text(review.review)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(subtleText)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.white.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: Color(hex: "3F2D28").opacity(0.06), radius: 12, x: 0, y: 4)
    }

    private var initialsView: some View {
        Text(initials(from: review.nickname))
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(accent)
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ")
        let first = parts.first?.prefix(1) ?? ""
        let second = parts.dropFirst().first?.prefix(1) ?? ""
        return String(first + second).uppercased()
    }
}

// MARK: - Left Clip Shape (for before/after slider)
private struct LeftClipShape: Shape, Animatable {
    var width: CGFloat
    var height: CGFloat

    var animatableData: CGFloat {
        get { width }
        set { width = newValue }
    }

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: 0, y: 0, width: width, height: height))
    }
}

// MARK: - Safe Array Access
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Main Onboarding Container
struct Intro: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var currentPage = 0
    @State private var showPaywall = false
    @State private var navigateToMain = false

    @EnvironmentObject private var entitlementManager: EntitlementManager
    @EnvironmentObject private var subscriptionsManager: SubscriptionsManager

    private let bgColor = Color(hex: "F6ECE6")

    var body: some View {
        NavigationStack {
            ZStack {
                bgColor.ignoresSafeArea()

                if viewModel.isLoading {
                    loadingView
                } else if let error = viewModel.errorMessage {
                    errorView(message: error)
                } else {
                    contentView
                }
            }
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView()
                    .navigationBarBackButtonHidden()
            }
        }
        .navigationBarBackButtonHidden()
        .preferredColorScheme(.light)
        .sheet(isPresented: $showPaywall, onDismiss: {
            hasSeenOnboarding = true
            navigateToMain = true
        }) {
            PremiumView()
        }
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private var contentView: some View {
        let screenWidth = UIScreen.main.bounds.width

        ZStack {
            if let first = viewModel.firstItem {
                OnboardingBeforeAfterView(item: first) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentPage = 1
                    }
                }
                .offset(x: currentPage == 0 ? 0 : -screenWidth)
            } else {
                emptyPlaceholder
                    .offset(x: currentPage == 0 ? 0 : -screenWidth)
            }

            if let second = viewModel.secondItem {
                OnboardingBeforeAfterVideoView(item: second) {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        currentPage = 2
                    }
                }
                .offset(x: offsetForPage(1, screenWidth: screenWidth))
            } else {
                emptyPlaceholder
                    .offset(x: offsetForPage(1, screenWidth: screenWidth))
            }

            OnboardingReviewsView(reviews: viewModel.reviews) {
                showPaywall = true
            }
            .offset(x: currentPage == 2 ? 0 : screenWidth)
        }
        .animation(.easeInOut(duration: 0.35), value: currentPage)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private func offsetForPage(_ page: Int, screenWidth: CGFloat) -> CGFloat {
        if currentPage < page {
            return screenWidth
        } else if currentPage > page {
            return -screenWidth
        } else {
            return 0
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.4)
                .tint(Color(hex: "A66A54"))

            Text("Loading magic...")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Color(hex: "796B64"))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(Color(hex: "A66A54"))

            Text("Oops!")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(hex: "3F2D28"))

            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color(hex: "796B64"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                Task { await viewModel.load() }
            } label: {
                Text("Try Again")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color(hex: "A66A54"))
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    private var emptyPlaceholder: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(hex: "A66A54").opacity(0.6))
            Text("No onboarding content")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: "3F2D28"))
            Text("Check admin panel: app_id must be \"bubsie\" and is_active must be true.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "796B64"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}
