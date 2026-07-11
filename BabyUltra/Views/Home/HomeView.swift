import SwiftUI
import AVFoundation
import AVKit
import WebKit
import SDWebImageSwiftUI

extension Notification.Name {
    static let templateAudioChanged = Notification.Name("templateAudioChanged")
}

private enum HomePalette {
    static let background = Color.clear // Let MainTabView's mesh show through
    static let card = Color.white.opacity(0.85)
    static let tile = Color.white.opacity(0.7)
    static let text = BabyUltra.textPrimary
    static let subtleText = BabyUltra.textSecondary
    static let accent = BabyUltra.accent
    static let gridGap: CGFloat = 12
    static let edgePadding: CGFloat = 16
}

struct HomeView: View {
    @State private var selectedTemplate: TemplateItem?
    @State private var showTransform = false
    @State private var isPremiumShow = false
    @State private var showAccount = false
    @State private var selectedCategoryForDetail: CategoryItem?
            @StateObject private var counter = CoinCounter()
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var auth = AuthManager.shared
    @EnvironmentObject private var entitlementManager: EntitlementManager

    var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("bg")
                    .resizable()
                    .ignoresSafeArea()

                StickyBlurHeader(
                    maxBlurRadius: 10,
                    fadeExtension: 44,
                    tintOpacityTop: 0.58,
                    tintOpacityMiddle: 0.36
                ) {
                    ZStack {
                        // Left Side
                        HStack(spacing: 4) {
                            Image("logo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                            Text("BabyUltra")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(HomePalette.accent)
                            
                            Spacer()
                        }
                        
                        // Right Side
                        HStack {
                            Spacer()
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
                                }
                                .foregroundStyle(HomePalette.accent)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.5))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(HomePalette.accent.opacity(0.3), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                } content: {
                    VStack(spacing: HomePalette.gridGap) {
                        heroSection


                        templatesContent
                        Color.clear.frame(height: 70)
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
            .task {
                if homeVM.hasLoaded {
                                    }
            }
            .sheet(isPresented: $isPremiumShow) { PremiumView() }
            .sheet(item: $selectedCategoryForDetail) { category in
                CategoryDetailView(
                    category: category,
                    templates: homeVM.photoTemplates.filter { $0.categoryId == category.rawID },
                    categoryName: homeVM.categoryName,
                    onTemplateTap: handleTemplateTap,
                    viewModel: homeVM
                )
            }
            .navigationDestination(isPresented: $showTransform) {
                if let template = selectedTemplate {
                    TransformView(template: template)
                }
            }
        }
        .onAppear {
            AppState.shared.hideTabBar = false
        }
    }

        private var heroSection: some View {
        let popularTemplates = homeVM.photoTemplates.filter { $0.isPopular }
        return VStack(spacing: 16) {
            ForEach(popularTemplates) { template in
                Button {
                    handleTemplateTap(template)
                } label: {
                    PopularTemplateCard(template: template, cardWidth: UIScreen.main.bounds.width - 32)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
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



    private var templatesContent: some View {
        VStack(spacing: 24) {
            if homeVM.selectedCategoryID == nil && homeVM.selectedFilter == nil {
                categoryRows
            }
        }
    }

    private var categoryRows: some View {
        let categories = homeVM.photoCategories

        return VStack(spacing: 24) {
            ForEach(categories) { category in
                let catTemplates = homeVM.templatesByCategory[category.rawID] ?? []
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
                            LazyHStack(spacing: HomePalette.gridGap) {
                                ForEach(catTemplates) { template in
                                    HomeTemplateCard(template: template, categoryName: homeVM.categoryName(for: template), cardID: "cat-\(category.rawID)-\(template.id)", viewModel: homeVM) {
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
                WebImage(url: url, options: [.retryFailed]) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(.white.opacity(0.8))
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

private struct PopularTemplateCard: View {
    let template: TemplateItem
    let cardWidth: CGFloat
    private let cardHeight: CGFloat = 210

    var body: some View {
        ZStack(alignment: .bottom) {
            // Arka plan resmi veya gradient
            if let imageURL = (template.afterMediaUrl.flatMap(URL.init) ?? template.beforeMediaUrl.flatMap(URL.init)) {
                WebImage(url: imageURL, options: [.retryFailed]) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(hex: "2D2422")
                }
                .frame(width: cardWidth, height: cardHeight)
                .clipped()
            } else {
                Color(hex: "2D2422")
                    .frame(width: cardWidth, height: cardHeight)
            }

            // Üstteki liquid glass başlık bölmesi (şimdi alt kısımda)
            HStack {
                Text(template.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(HomePalette.text)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
            }
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(10)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 3)
    }
}

private struct HomeTemplateCard: View {
    let template: TemplateItem
    let categoryName: String?
    let cardID: String
    let action: () -> Void
    private let cardHeight: CGFloat = 250
    private let previewURL: URL?
    @ObservedObject var viewModel: HomeViewModel

    init(template: TemplateItem, categoryName: String?, cardID: String, viewModel: HomeViewModel, action: @escaping () -> Void) {
        self.template = template
        self.categoryName = categoryName
        self.cardID = cardID
        self.viewModel = viewModel
        self.action = action
        let url = template.afterMediaUrl.flatMap(URL.init) ?? template.beforeMediaUrl.flatMap(URL.init)
        self.previewURL = url
    }

    var body: some View {
        ZStack {
            // Arka plan rengi
            Color.black
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // MEDYA KATI (Resim veya Video)
            Color.clear
                .overlay(mediaPreview)
                .clipped()

            // Header benzeri blur/tint alt katmanı
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.16)
                .overlay(Color(hex: "2D2422").opacity(0.32))
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

                HStack(alignment: .bottom) {
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


                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
        }
        .frame(maxWidth: .infinity, minHeight: cardHeight, maxHeight: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .onTapGesture {
            action()
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var mediaPreview: some View {
        if let previewURL {
            WebImage(url: previewURL, options: [.retryFailed]) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                placeholder
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        LinearGradient(
            colors:[Color(hex: "2D2422"), Color(hex: "8D7F7A")],
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

// MARK: - Template Video Player



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
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        if horizontalSizeClass == .regular {
            return [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ]
        }
        return [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("bg")
                    .resizable()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(templates) { template in
                            HomeTemplateCard(
                                template: template,
                                categoryName: categoryName(template),
                                cardID: "detail-\(category.rawID)-\(template.id)",
                                viewModel: viewModel
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
