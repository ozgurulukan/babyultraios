import SwiftUI
import AVFoundation
import AVKit

private struct HomeQuickAction: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let actionTypes: [String]
}

private let homeQuickActions: [HomeQuickAction] = [
    .init(title: "Remove BG", icon: "scissors", actionTypes: ["remove_bg"]),
    .init(title: "Upscale", icon: "viewfinder.rectangular", actionTypes: ["upscale"]),
    .init(title: "Video Dance", icon: "movieclapper", actionTypes: ["video"]),
    .init(title: "Family AI", icon: "figure.2.and.child.holdinghands", actionTypes: ["ai_chat", "video"])
]

private enum HomePalette {
    static let background = Color(hex: "F6ECE6")
    static let card = Color(hex: "EFE2DC")
    static let tile = Color(hex: "F4ECE8")
    static let text = Color(hex: "3F2D28")
    static let subtleText = Color(hex: "796B64")
    static let accent = Color(hex: "A66A54")
    static let gridGap: CGFloat = 12
    static let edgePadding: CGFloat = 16
}

struct HomeView: View {
    @State private var selectedTemplate: TemplateItem?
    @State private var showTransform = false
    @State private var isPremiumShow = false
    @StateObject private var counter = CoinCounter()
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var auth = AuthManager.shared
    @EnvironmentObject private var entitlementManager: EntitlementManager

    var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }

    private var featuredSliderItems: [SliderItem] {
        homeVM.sliderItems
    }

    private var shownTemplates: [TemplateItem] {
        if homeVM.selectedCategoryID != nil || homeVM.selectedFilter != nil {
            return homeVM.filteredTemplates
        }
        return homeVM.selectedMode == 0 ? homeVM.videoTemplates : homeVM.photoTemplates
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HomePalette.background.ignoresSafeArea()

                StickyBlurHeader(
                    maxBlurRadius: 8,
                    fadeExtension: 84,
                    tintOpacityTop: 0.58,
                    tintOpacityMiddle: 0.36
                ) {
                    // Logo ve Header metinlerini yan yana getiren HStack
                    HStack(alignment: .center, spacing: 20) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        ProfileStyleHeader(
                            title: "Bubsie",
                            subtitle: "Discover your magical AI creations."
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                } content: {
                    VStack(spacing: HomePalette.gridGap) {
                        heroSection
                        quickActionsSection
                        modeSegment
                        templatesGrid
                        Color.clear.frame(height: 120)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
            }
            .navigationBarHidden(true)
            .task { await homeVM.loadData() }
            .sheet(isPresented: $isPremiumShow) { PremiumView() }
            .navigationDestination(isPresented: $showTransform) {
                if let template = selectedTemplate {
                    TransformView(template: template)
                }
            }
        }
    }

    private var heroSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HomePalette.gridGap) {
                if featuredSliderItems.isEmpty {
                    HeroSliderPlaceholderCard()
                } else {
                    ForEach(featuredSliderItems) { item in
                        HeroSliderCard(item: item)
                    }
                }
            }
            .padding(.horizontal, HomePalette.edgePadding)
        }
    }

    private var quickActionsSection: some View {
        HStack(spacing: HomePalette.gridGap) {
            ForEach(homeQuickActions) { action in
                Button {
                    openTemplate(for: action.actionTypes)
                } label: {
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.45))
                                .frame(width: 72, height: 72)
                                .overlay(Circle().stroke(Color(hex: "E5D5CD"), lineWidth: 1))
                            Image(systemName: action.icon)
                                .font(.system(size: 25, weight: .medium))
                                .foregroundStyle(Color(hex: "8E614D"))
                        }
                        Text(action.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(HomePalette.text)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, HomePalette.edgePadding)
    }

    private var modeSegment: some View {
        HStack(spacing: 10) {
            modeChip(title: "All", isSelected: homeVM.selectedMode == 1 && homeVM.selectedFilter == nil && homeVM.selectedCategoryID == nil) {
                homeVM.selectedMode = 1
                homeVM.selectFilter(nil)
                homeVM.selectCategory(nil)
                homeVM.applyFilterForMode(1)
            }

            modeChip(title: "Photos", isSelected: homeVM.selectedMode == 1 && homeVM.selectedFilter == nil && homeVM.selectedCategoryID != nil) {
                homeVM.selectedMode = 1
                if let firstPhoto = homeVM.photoCategories.first {
                    homeVM.selectCategory(firstPhoto.id)
                } else {
                    homeVM.selectCategory(nil)
                }
                homeVM.applyFilterForMode(1)
            }

            modeChip(title: "Videos", isSelected: homeVM.selectedMode == 0) {
                homeVM.selectedMode = 0
                homeVM.selectCategory(nil)
                homeVM.selectFilter(nil)
                homeVM.applyFilterForMode(0)
            }

            modeChip(title: "Trend", isSelected: homeVM.selectedFilter == "trending") {
                homeVM.selectedMode = 1
                homeVM.selectFilter("trending")
                homeVM.applyFilterForMode(1)
            }
        }
        .padding(.horizontal, HomePalette.edgePadding)
    }

    private func modeChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : HomePalette.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(isSelected ? HomePalette.accent : Color.white.opacity(0.45))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "E0D0C8"), lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    private var templatesGrid: some View {
        let templates = shownTemplates

        return LazyVGrid(
            columns: [
                GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: HomePalette.gridGap, alignment: .top),
                GridItem(.flexible(minimum: 0, maximum: .infinity), spacing: HomePalette.gridGap, alignment: .top)
            ],
            spacing: HomePalette.gridGap
        ) {
            ForEach(templates) { template in
                HomeTemplateCard(template: template, categoryName: homeVM.categoryName(for: template)) {
                    if entitlementManager.hasPro || displayCredits >= template.creditCost {
                        selectedTemplate = template
                        showTransform = true
                    } else {
                        isPremiumShow = true
                    }
                }
            }
        }
        .padding(.horizontal, HomePalette.edgePadding)
    }

    private func openTemplate(for actionTypes: [String]) {
        let allTemplates = homeVM.photoTemplates + homeVM.videoTemplates
        let wanted = Set(actionTypes)

        if let template = allTemplates.first(where: { wanted.contains($0.actionType) }) {
            selectedTemplate = template
            showTransform = true
            return
        }

        if let fallback = allTemplates.first {
            selectedTemplate = fallback
            showTransform = true
        }
    }
}

private struct AvatarBadge: View {
    let photoURL: String?

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: "0F516A"))
                .frame(width: 54, height: 54)

            if let photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 26))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .frame(width: 52, height: 52)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 26))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }
}

private struct HeroSliderCard: View {
    let item: SliderItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = item.imageUrl.flatMap(URL.init) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        LinearGradient(
                            colors: [Color(hex: "D9CBC4"), Color(hex: "B5A69E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .frame(width: 376 * 0.86, height: 240)
                .clipped()
            } else {
                LinearGradient(
                    colors: [Color(hex: "D9CBC4"), Color(hex: "B5A69E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 376 * 0.86, height: 240)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("NEW")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Color(hex: "B27A62").opacity(0.95))
                        .clipShape(Capsule())

                    Text(item.title ?? "Featured")
                        .font(.system(size: 40 * 0.6, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }

                Spacer()

                Circle()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 52, height: 52)
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
                    .overlay(
                        Image(systemName: "arrow.right")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    )
            }
            .padding(18)
        }
        .frame(width: 376 * 0.86, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
    }
}

private struct HeroSliderPlaceholderCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(hex: "D8C8C0"), Color(hex: "9E8A7F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 376 * 0.86, height: 240)

            VStack(alignment: .leading, spacing: 8) {
                Text("NEW")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Color(hex: "B27A62").opacity(0.95))
                    .clipShape(Capsule())

                Text("Featured Style")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(18)
        }
        .frame(width: 376 * 0.86, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
    }
}

private struct HomeTemplateCard: View {
    let template: TemplateItem
    let categoryName: String?
    let action: () -> Void
    private let cardHeight: CGFloat = 250

    var body: some View {
        Button(action: action) {
            ZStack {
                mediaPreview
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()

                LinearGradient(
                    colors: [.clear, .black.opacity(0.35)],
                    startPoint: .init(x: 0.5, y: 0.5),
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                VStack {
                    HStack {
                        if template.isPremium {
                            Text("PRO")
                                .font(.system(size: 10, weight: .black))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(Color.black.opacity(0.38))
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                        }

                        Spacer()

                        HStack(spacing: 4) {
                            Image(systemName: "circle.lefthalf.filled")
                                .font(.system(size: 10, weight: .bold))
                            Text("\(template.creditCost)")
                                .font(.system(size: 16 * 0.7, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.45))
                        .clipShape(Capsule())
                    }
                    .padding(10)

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(categoryName ?? kindText(for: template.actionType))
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.82))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        .ultraThinMaterial.opacity(0.4)
                    )
                }
            }
            .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var mediaPreview: some View {
        if shouldShowVideo, let previewURL {
            LoopingTemplateVideoView(url: previewURL)
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else if let previewURL {
            AsyncImage(url: previewURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var previewURL: URL? {
        template.afterMediaUrl.flatMap(URL.init) ?? template.beforeMediaUrl.flatMap(URL.init)
    }

    private var shouldShowVideo: Bool {
        if template.actionType == "video" { return true }

        let videoHints = [template.afterMediaType, template.beforeMediaType].compactMap { $0?.lowercased() }
        if videoHints.contains(where: { $0.contains("video") }) { return true }

        if let ext = previewURL?.pathExtension.lowercased() {
            return ["mp4", "mov", "m4v", "webm"].contains(ext)
        }
        return false
    }

    private var placeholder: some View {
        LinearGradient(
            colors: [Color(hex: "2A1F1A"), Color(hex: "49382F")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func kindText(for actionType: String) -> String {
        switch actionType {
        case "remove_bg", "upscale", "photo_restoration":
            return "Photo Transform"
        case "video":
            return "Video Animation"
        case "ai_chat":
            return "Concept"
        default:
            return "AI Template"
        }
    }
}

private struct LoopingTemplateVideoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingTemplatePlayerView {
        let view = LoopingTemplatePlayerView()
        view.setVideoURL(url)
        return view
    }

    func updateUIView(_ uiView: LoopingTemplatePlayerView, context: Context) {
        uiView.setVideoURL(url)
    }
}

private final class LoopingTemplatePlayerView: UIView {
    private let player = AVQueuePlayer()
    private let playerLayer = AVPlayerLayer()
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    override init(frame: CGRect) {
        super.init(frame: frame)
        player.isMuted = true
        player.actionAtItemEnd = .none
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
        looper = AVPlayerLooper(player: player, templateItem: AVPlayerItem(url: url))
        player.play()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer.frame = bounds
    }
}

#Preview {
    HomeView()
        .environmentObject(EntitlementManager())
}
