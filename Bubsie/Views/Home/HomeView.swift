import SwiftUI
import AVFoundation
import AVKit

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
    @State private var showAccount = false
    @StateObject private var counter = CoinCounter()
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var auth = AuthManager.shared
    @EnvironmentObject private var entitlementManager: EntitlementManager

    var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }

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
                    HStack(alignment: .center, spacing: 20) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        ProfileStyleHeader(
                            title: "Bubsie",
                            subtitle: "Every Giggle Matters"
                        )
                        
                        Spacer()
                        
                        Button {
                            showAccount = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "circle.lefthalf.filled")
                                    .font(.system(size: 13, weight: .bold))
                                Text("\(displayCredits)")
                                    .font(.system(size: 14, weight: .bold))
                            }
                            .foregroundStyle(Color(hex: "f9f5f2"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                } content: {
                    VStack(spacing: HomePalette.gridGap) {
                        heroSection
                        mediaModeSelector
                        modeSegment
                        templatesContent
                        Color.clear.frame(height: 120)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                }
            }
            .navigationBarHidden(true)
            .task { await homeVM.loadData() }
            .task(id: homeVM.selectedMode) {
                if homeVM.hasLoaded {
                    await homeVM.loadSlider()
                }
            }
            .sheet(isPresented: $isPremiumShow) { PremiumView() }
            .navigationDestination(isPresented: $showTransform) {
                if let template = selectedTemplate {
                    TransformView(template: template)
                }
            }
            .navigationDestination(isPresented: $showAccount) {
                AccountView()
            }
        }
    }

    private var heroSection: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    if homeVM.sliderItems.isEmpty {
                        HeroSliderPlaceholderCard()
                            .frame(width: geo.size.width)
                    } else {
                        ForEach(homeVM.sliderItems) { item in
                            HeroSliderCard(item: item)
                                .frame(width: geo.size.width)
                        }
                    }
                }
            }
        }
        .frame(height: 240)
    }

    private var mediaModeSelector: some View {
        HStack(spacing: 12) {
            Button {
                homeVM.selectedMode = 1
                homeVM.selectCategory(nil)
                homeVM.selectFilter(nil)
                homeVM.applyFilterForMode(1)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 18, weight: .medium))
                    Text("PHOTO")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(homeVM.selectedMode == 1 ? .white : HomePalette.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Group {
                        if homeVM.selectedMode == 1 {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(HomePalette.accent)
                        } else {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                homeVM.selectedMode = 0
                homeVM.selectCategory(nil)
                homeVM.selectFilter(nil)
                homeVM.applyFilterForMode(0)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "video")
                        .font(.system(size: 18, weight: .medium))
                    Text("VIDEO")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(homeVM.selectedMode == 0 ? .white : HomePalette.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    Group {
                        if homeVM.selectedMode == 0 {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(HomePalette.accent)
                        } else {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.ultraThinMaterial)
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.4), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, HomePalette.edgePadding)
    }

    private var modeSegment: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                modeChip(title: "All", icon: nil, isSelected: homeVM.selectedCategoryID == nil && homeVM.selectedFilter == nil) {
                    homeVM.selectCategory(nil)
                    homeVM.selectFilter(nil)
                }

                modeChip(title: "Popular", icon: "flame.fill", selectedColor: .blue, isSelected: homeVM.selectedFilter == "popular") {
                    homeVM.selectFilter("popular")
                }

                modeChip(title: "Viral", icon: "chart.line.uptrend.xyaxis", selectedColor: .red, isSelected: homeVM.selectedFilter == "trending") {
                    homeVM.selectFilter("trending")
                }

                if homeVM.selectedMode == 1 {
                    ForEach(homeVM.photoCategories) { category in
                        modeChip(title: category.name, icon: nil, isSelected: homeVM.selectedCategoryID == category.id) {
                            homeVM.selectCategory(category.id)
                        }
                    }
                } else {
                    ForEach(homeVM.videoCategories) { category in
                        modeChip(title: category.name, icon: nil, isSelected: homeVM.selectedCategoryID == category.id) {
                            homeVM.selectCategory(category.id)
                        }
                    }
                }
            }
            .padding(.horizontal, HomePalette.edgePadding)
        }
    }

    private func modeChip(title: String, icon: String? = nil, selectedColor: Color = HomePalette.accent, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : HomePalette.text)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(isSelected ? selectedColor : Color.white.opacity(0.45))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color(hex: "E0D0C8"), lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    private var templatesContent: some View {
        VStack(spacing: 24) {
            horizontalTemplatesRow(templates: homeVM.filteredTemplates)

            if homeVM.selectedCategoryID == nil && homeVM.selectedFilter == nil {
                categoryRows
            }
        }
    }

    private func horizontalTemplatesRow(templates: [TemplateItem]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: HomePalette.gridGap) {
                ForEach(templates) { template in
                    HomeTemplateCard(template: template, categoryName: homeVM.categoryName(for: template)) {
                        if entitlementManager.hasPro || displayCredits >= template.creditCost {
                            selectedTemplate = template
                            showTransform = true
                        } else {
                            isPremiumShow = true
                        }
                    }
                    .frame(width: 170)
                }
            }
            .padding(.horizontal, HomePalette.edgePadding)
        }
    }

    private var categoryRows: some View {
        let categories = homeVM.selectedMode == 1 ? homeVM.photoCategories : homeVM.videoCategories
        let allTemplates = homeVM.selectedMode == 0 ? homeVM.videoTemplates : homeVM.photoTemplates

        return VStack(spacing: 24) {
            ForEach(categories) { category in
                let catTemplates = allTemplates.filter { $0.categoryId == category.rawID }
                if !catTemplates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(category.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(HomePalette.text)
                            .padding(.horizontal, HomePalette.edgePadding)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: HomePalette.gridGap) {
                                ForEach(catTemplates) { template in
                                    HomeTemplateCard(template: template, categoryName: homeVM.categoryName(for: template)) {
                                        if entitlementManager.hasPro || displayCredits >= template.creditCost {
                                            selectedTemplate = template
                                            showTransform = true
                                        } else {
                                            isPremiumShow = true
                                        }
                                    }
                                    .frame(width: 170)
                                }
                            }
                            .padding(.horizontal, HomePalette.edgePadding)
                        }
                    }
                }
            }
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
            // Arka plan resmi veya gradient
            if let imageURL = item.imageUrl.flatMap(URL.init) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure(_):
                        gradientBackground
                    case .empty:
                        gradientBackground
                    @unknown default:
                        gradientBackground
                    }
                }
                .clipped()
            } else {
                gradientBackground
            }

            // Frame overlay (PNG)
            if let frameURL = item.frameUrl.flatMap(URL.init) {
                AsyncImage(url: frameURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        EmptyView()
                    }
                }
                .allowsHitTesting(false)
            }

            // Alt karartma gradient'i
            LinearGradient(
                colors:[.clear, .black.opacity(0.55)],
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

                    if let title = item.title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }

                    if let description = item.description, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.9))
                            .lineLimit(2)
                    }
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .stroke(Color.white.opacity(0.45), lineWidth: 1)
        )
    }

    private var gradientBackground: some View {
        LinearGradient(
            colors:[Color(hex: "D9CBC4"), Color(hex: "B5A69E")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct HeroSliderPlaceholderCard: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors:[Color(hex: "D8C8C0"), Color(hex: "9E8A7F")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors:[.clear, .black.opacity(0.45)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("NEW")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(Color(hex: "B27A62").opacity(0.95))
                    .clipShape(Capsule())

                Text("Loading...")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                // Arka plan rengi
                Color.black
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                // MEDYA KATI (Resim veya Video)
                // Color.clear.overlay kullanarak medyanın orijinal boyutunun ZStack'i ve dolayısıyla Grid'i esnetmesini tamamen ENGELLİYORUZ.
                Color.clear
                    .overlay(
                        mediaPreview
                    )
                    .clipped() // Overlay içindeki medyanın Color.clear (ve kartın) dışına taşmasını engeller.

                // Alt Kısım Karartması (Yazıların okunabilmesi için)
                LinearGradient(
                    colors:[.clear, .black.opacity(0.45)],
                    startPoint: .init(x: 0.5, y: 0.55),
                    endPoint: .bottom
                )
                .allowsHitTesting(false)

                // Üzerindeki Yazılar ve Bilgiler
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
            // Kart yüksekliğini minHeight ve maxHeight ile tamamen sabitleyip farklı boyutlara kaymasını engelliyoruz
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
        } else if let previewURL {
            AsyncImage(url: previewURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill() // Görüntüyü kartın sınırlarına kadar tam sığdırır (fill yapar)
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

        let videoHints  = [template.afterMediaType, template.beforeMediaType].compactMap { $0?.lowercased() }
        if videoHints.contains(where: { $0.contains("video") }) { return true }

        if let ext = previewURL?.pathExtension.lowercased() {
            return["mp4", "mov", "m4v", "webm"].contains(ext)
        }
        return false
    }

    private var placeholder: some View {
        LinearGradient(
            colors:[Color(hex: "2A1F1A"), Color(hex: "49382F")],
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
        
        // Videonun boşluksuz olarak kartı tam kaplaması için resizeAspectFill
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
