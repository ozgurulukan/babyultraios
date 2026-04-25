import SwiftUI
import AVFoundation
import AVKit
import WebKit

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
    @State private var selectedCategoryForDetail: CategoryItem?
    @State private var currentSliderIndex = 0
    @State private var sliderTimer: Timer?
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
                    maxBlurRadius: 10,
                    fadeExtension: 84,
                    tintOpacityTop: 0.58,
                    tintOpacityMiddle: 0.36
                ) {
                    HStack(alignment: .center, spacing: 20) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 54, height: 54)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        ProfileStyleHeader(
                            title: NSLocalizedString("app.name", comment: ""),
                            subtitle: NSLocalizedString("home.ai_studio", comment: ""),
                            spacing: 1
                        )
                        
                        Spacer()

                        HStack(spacing: 6) {
                            if !hasProAccess {
                                Button {
                                    isPremiumShow = true
                                } label: {
                                    Text(NSLocalizedString("home.pro_button", comment: ""))
                                        .font(.system(size: 11, weight: .heavy))
                                        .foregroundStyle(.white)
                                        .lineLimit(1)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(
                                            ZStack {
                                                Capsule()
                                                    .fill(HomePalette.accent.opacity(0.88))
                                                Capsule()
                                                    .fill(.ultraThinMaterial)
                                                LinearGradient(
                                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            }
                                            .clipShape(Capsule())
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.55), lineWidth: 1)
                                        )
                                        .shadow(color: HomePalette.accent.opacity(0.35), radius: 6, x: 0, y: 3)
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showAccount = true
                                }
                            } label: {
                                HStack(spacing: 5) {
                                    Image(systemName: "circle.lefthalf.filled")
                                        .font(.system(size: 13, weight: .bold))
                                    Text("\(displayCredits)")
                                        .font(.system(size: 14, weight: .bold))
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                                .foregroundStyle(Color(hex: "f9f5f2"))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(.ultraThinMaterial)
                                        .overlay(Color.black.opacity(0.18))
                                )
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.white.opacity(0.4), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
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
                    .padding(.top, -8)
                    .padding(.bottom, 8)
                }
                .environment(\.colorScheme, .light)

                if showAccount {
                    AccountView(isPresented: $showAccount, showBackButton: true)
                        .transition(.move(edge: .trailing))
                        .zIndex(1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .sheet(item: $selectedCategoryForDetail) { category in
                CategoryDetailView(
                    category: category,
                    templates: (homeVM.selectedMode == 0
                        ? homeVM.videoTemplates.filter { $0.categoryId == category.rawID }
                        : homeVM.photoTemplates.filter { $0.categoryId == category.rawID }).shuffled(),
                    categoryName: homeVM.categoryName,
                    onTemplateTap: handleTemplateTap
                )
            }
            .navigationDestination(isPresented: $showTransform) {
                if let template = selectedTemplate {
                    TransformView(template: template)
                }
            }
        }
    }

    private var heroSection: some View {
        GeometryReader { geo in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        if homeVM.sliderItems.isEmpty {
                            HeroSliderPlaceholderCard()
                                .frame(width: geo.size.width, height: 280)
                        } else {
                            ForEach(0..<homeVM.sliderItems.count, id: \.self) { index in
                                let item = homeVM.sliderItems[index]
                                Button {
                                    handleSliderTap(item)
                                } label: {
                                    HeroSliderCard(item: item)
                                        .frame(width: geo.size.width, height: 280)
                                }
                                .buttonStyle(.plain)
                                .id(index)
                            }
                        }
                    }
                }
                .onAppear {
                    startAutoScroll(proxy: proxy)
                }
                .onDisappear {
                    sliderTimer?.invalidate()
                }
                .onChange(of: homeVM.sliderItems.count) {
                    currentSliderIndex = 0
                    startAutoScroll(proxy: proxy)
                }
            }
        }
        .frame(height: 280)
    }

    private func startAutoScroll(proxy: ScrollViewProxy) {
        sliderTimer?.invalidate()
        let count = homeVM.sliderItems.count
        guard count > 1 else { return }

        let timer = Timer(timeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSliderIndex = (currentSliderIndex + 1) % count
                proxy.scrollTo(currentSliderIndex, anchor: .leading)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        sliderTimer = timer
    }

    private func handleSliderTap(_ item: SliderItem) {
        guard let template = homeVM.templateForSlider(item) else { return }
        handleTemplateTap(template)
    }

    private var hasProAccess: Bool {
        entitlementManager.hasPro || (auth.currentUser?.isPro == true)
    }

    private func handleTemplateTap(_ template: TemplateItem) {
        if template.isPremium && !hasProAccess {
            isPremiumShow = true
            return
        }

        if hasProAccess || displayCredits >= template.creditCost {
            selectedTemplate = template
            showTransform = true
        } else {
            isPremiumShow = true
        }
    }

    private var mediaModeSelector: some View {
        HStack(spacing: 12) {
            Button {
                homeVM.switchMode(1)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.system(size: 18, weight: .medium))
                    Text(NSLocalizedString("home.photo", comment: ""))
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundStyle(homeVM.selectedMode == 1 ? .white : HomePalette.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(homeVM.selectedMode == 1 ? HomePalette.accent : Color.white.opacity(0.22))
                        .overlay {
                            if homeVM.selectedMode != 1 {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .fill(Color.black.opacity(0.10))
                                    )
                            }
                        }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(homeVM.selectedMode == 1 ? Color.white.opacity(0.72) : Color.white.opacity(0.35), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(homeVM.selectedMode == 1 ? Color(hex: "FCECE5").opacity(0.55) : Color.black.opacity(0.10), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                 homeVM.switchMode(0)
             } label: {
                 HStack(spacing: 8) {
                     Image(systemName: "video")
                         .font(.system(size: 18, weight: .medium))
                     Text(NSLocalizedString("home.video", comment: ""))
                         .font(.system(size: 15, weight: .semibold))
                 }
                .foregroundStyle(homeVM.selectedMode == 0 ? .white : HomePalette.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(homeVM.selectedMode == 0 ? HomePalette.accent : Color.white.opacity(0.22))
                        .overlay {
                            if homeVM.selectedMode != 0 {
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .fill(Color.black.opacity(0.10))
                                    )
                            }
                        }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(homeVM.selectedMode == 0 ? Color.white.opacity(0.72) : Color.white.opacity(0.35), lineWidth: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(homeVM.selectedMode == 0 ? Color(hex: "FCECE5").opacity(0.55) : Color.black.opacity(0.10), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, HomePalette.edgePadding)
    }

    private var modeSegment: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                modeChip(title: NSLocalizedString("home.filter_all", comment: ""), icon: nil, isSelected: homeVM.selectedCategoryID == nil && homeVM.selectedFilter == nil) {
                    homeVM.selectCategory(nil)
                }

                modeChip(title: NSLocalizedString("home.filter_popular", comment: ""), icon: "flame.fill", selectedColor: .blue, isSelected: homeVM.selectedFilter == "popular") {
                    homeVM.selectFilter("popular")
                }

                modeChip(title: NSLocalizedString("home.filter_viral", comment: ""), icon: "chart.line.uptrend.xyaxis", selectedColor: .red, isSelected: homeVM.selectedFilter == "trending") {
                    homeVM.selectFilter("trending")
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
                        handleTemplateTap(template)
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
                let catTemplates = allTemplates.filter { $0.categoryId == category.rawID }.shuffled()
                if !catTemplates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Button {
                            selectedCategoryForDetail = category
                        } label: {
                            HStack(spacing: 8) {
                                if let iconUrl = category.iconUrl, let url = URL(string: iconUrl) {
                                    SVGAsyncImage(url: url, size: CGSize(width: 22, height: 22))
                                }

                                Text(category.name)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(HomePalette.text)

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(HomePalette.subtleText)
                            }
                            .padding(.horizontal, HomePalette.edgePadding)
                        }
                        .buttonStyle(.plain)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: HomePalette.gridGap) {
                                ForEach(catTemplates) { template in
                                    HomeTemplateCard(template: template, categoryName: homeVM.categoryName(for: template)) {
                                        handleTemplateTap(template)
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
    private let cardWidth: CGFloat = 376 * 0.86
    private let cardHeight: CGFloat = 240
    private let framePadding: CGFloat = 20

    var body: some View {
        ZStack {
            // Frame URL — slider'ın arkasındaki çerçeve katmanı
            // Karttan büyük, kenarları sarar, clipShape'e maruz kalmaz
            if let frameURL = item.frameUrl.flatMap(URL.init) {
                AsyncImage(url: frameURL) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        EmptyView()
                    }
                }
                .frame(width: cardWidth + framePadding * 2, height: cardHeight + framePadding * 2)
            }

            // Kart içeriği — yuvarlak köşeli ve kırpılmış
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
                    .frame(width: cardWidth, height: cardHeight)
                    .clipped()
                } else {
                    gradientBackground
                        .frame(width: cardWidth, height: cardHeight)
                }

                // Header benzeri blur/tint alt katmanı
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.18)
                    .overlay(Color(hex: "2F1E18").opacity(0.34))
                    .frame(width: cardWidth, height: cardHeight)
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.46),
                                .init(color: .black, location: 0.82),
                                .init(color: .black, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                )
                LinearGradient(
                    colors: [Color(hex: "4A2E25").opacity(0.50), Color(hex: "4A2E25").opacity(0.28), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(width: cardWidth, height: cardHeight)
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.5),
                            .init(color: .black, location: 0.88),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("home.new_badge", comment: ""))
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
            .frame(width: cardWidth, height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(Color.white.opacity(0.45), lineWidth: 1)
            )
        }
        .frame(width: cardWidth, height: cardHeight)
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
        ZStack {
            // Kart içeriği — yuvarlak köşeli ve kırpılmış
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors:[Color(hex: "D8C8C0"), Color(hex: "9E8A7F")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 376 * 0.86, height: 240)

                LinearGradient(
                    colors:[.clear, .black.opacity(0.45)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: 376 * 0.86, height: 240)

                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("home.new_badge", comment: ""))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(Color(hex: "B27A62").opacity(0.95))
                        .clipShape(Capsule())

                    Text(NSLocalizedString("home.loading", comment: ""))
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

                // Header benzeri blur/tint alt katmanı
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.16)
                    .overlay(Color(hex: "2F1E18").opacity(0.32))
                    .mask(
                        LinearGradient(
                            stops: [
                                .init(color: .clear, location: 0.56),
                                .init(color: .black, location: 0.86),
                                .init(color: .black, location: 1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
                LinearGradient(
                    colors: [Color(hex: "4A2E25").opacity(0.46), Color(hex: "4A2E25").opacity(0.26), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.58),
                            .init(color: .black, location: 0.9),
                            .init(color: .black, location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)

                // Üzerindeki Yazılar ve Bilgiler
                VStack {
                    HStack {
                        if template.isPremium {
                            Text(NSLocalizedString("home.pro_badge", comment: ""))
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
            return NSLocalizedString("home.filter_photo", comment: "")
        case "video":
            return NSLocalizedString("home.filter_video", comment: "")
        case "ai_chat":
            return NSLocalizedString("home.filter_concept", comment: "")
        default:
            return NSLocalizedString("home.filter_ai_template", comment: "")
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

// MARK: - SVG Support

struct SVGAsyncImage: View {
    let url: URL
    var size: CGSize = CGSize(width: 22, height: 22)

    var body: some View {
        if url.pathExtension.lowercased() == "svg" {
            SVGWebImage(url: url)
                .frame(width: size.width, height: size.height)
        } else {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                default:
                    EmptyView()
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }
}

struct SVGWebImage: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"/>
            <style>
                body { margin: 0; padding: 0; overflow: hidden; background: transparent; }
                img { width: 100%; height: 100%; object-fit: contain; display: block; }
            </style>
        </head>
        <body>
            <img src="\(url.absoluteString)" />
        </body>
        </html>
        """
        uiView.loadHTMLString(html, baseURL: nil)
    }
}

struct CategoryDetailView: View {
    let category: CategoryItem
    let templates: [TemplateItem]
    let categoryName: (TemplateItem) -> String?
    let onTemplateTap: (TemplateItem) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                HomePalette.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(templates) { template in
                            HomeTemplateCard(
                                template: template,
                                categoryName: categoryName(template)
                            ) {
                                onTemplateTap(template)
                            }
                        }
                    }
                    .padding(.horizontal, HomePalette.edgePadding)
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 8) {
                        if let iconUrl = category.iconUrl, let url = URL(string: iconUrl) {
                            SVGAsyncImage(url: url, size: CGSize(width: 20, height: 20))
                        }

                        Text(category.name)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(HomePalette.text)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(HomePalette.subtleText)
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(EntitlementManager())
}
