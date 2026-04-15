import SwiftUI

// MARK: - Data Models
struct TrendingModel: Identifiable {
    let id = UUID()
    let title: String
    let badge: String
    let gradientStart: Color
    let gradientEnd: Color
    let description: String
}

struct ExploreCategory: Identifiable {
    let id = UUID()
    let title: String
    let emoji: String
    let gradientStart: Color
    let gradientEnd: Color
}

struct PhotoTool: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let operation: OperationType
}

// MARK: - Quick-access category row (matches reference: 4 icons in a row)
struct QuickCategory: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
}

private let quickCategories: [QuickCategory] = [
    .init(title: "Assistant", icon: "face.smiling"),
    .init(title: "Story teller", icon: "book.fill"),
    .init(title: "Researcher", icon: "brain.head.profile"),
    .init(title: "Business", icon: "arrow.up.right"),
]

// MARK: - Prompt suggestions (matches reference)
struct PromptSuggestion: Identifiable {
    let id = UUID()
    let text: String
    let emoji: String
}

private let promptSuggestions: [PromptSuggestion] = [
    .init(text: "Generate Summary", emoji: "💬"),
    .init(text: "Are they a good fit for my job post?", emoji: "🏆"),
    .init(text: "What is their training style?", emoji: "🏃"),
]

// MARK: - Sample Data
private let trendingData: [TrendingModel] = [
    .init(title: "Veo 3.1", badge: "NEW", gradientStart: Color(hex: "1A0530"), gradientEnd: Color(hex: "5B21B6"), description: "Google's latest video model"),
    .init(title: "Sora 2", badge: "HOT", gradientStart: Color(hex: "0F172A"), gradientEnd: Color(hex: "3B82F6"), description: "OpenAI cinematic generation"),
    .init(title: "Kling 2.0", badge: "FAST", gradientStart: Color(hex: "0F1A10"), gradientEnd: Color(hex: "22C55E"), description: "High-fidelity motion synthesis"),
    .init(title: "Runway Gen-4", badge: "PRO", gradientStart: Color(hex: "1A0520"), gradientEnd: Color(hex: "DB2777"), description: "Professional video creation"),
]

private let categoryData: [ExploreCategory] = [
    .init(title: "Cinematic", emoji: "🎬", gradientStart: Color(hex: "1A0520"), gradientEnd: Color(hex: "7C3AED")),
    .init(title: "Fantasy", emoji: "✨", gradientStart: Color(hex: "0D0025"), gradientEnd: Color(hex: "6D28D9")),
    .init(title: "Futuristic", emoji: "🤖", gradientStart: Color(hex: "0F172A"), gradientEnd: Color(hex: "0EA5E9")),
    .init(title: "Nature", emoji: "🌿", gradientStart: Color(hex: "0F1A10"), gradientEnd: Color(hex: "16A34A")),
    .init(title: "Anime", emoji: "🎌", gradientStart: Color(hex: "1A0520"), gradientEnd: Color(hex: "DB2777")),
    .init(title: "Retro", emoji: "📺", gradientStart: Color(hex: "1A1400"), gradientEnd: Color(hex: "D97706")),
]

private let photoTools: [PhotoTool] = [
    .init(title: "Image Generation", subtitle: "Create from text",     icon: "wand.and.sparkles",                    operation: .TextToImage),
    .init(title: "Upscale",          subtitle: "Enhance to 4K",        icon: "square.resize.up",                     operation: .Upscaling),
    .init(title: "Remove BG",        subtitle: "Clean cutouts",         icon: "person.and.background.striped.horizontal", operation: .RemoveBackground),
    .init(title: "Photo Restore",    subtitle: "Fix old photos",        icon: "photo.badge.plus",                    operation: .Reimagine),
]

// MARK: - HomeView
struct HomeView: View {
    @State private var selectedMode = 0
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var selectedOperation: OperationType = .TextToImage
    @State private var selectedTemplate: TemplateItem?
    @State private var isPremiumShow = false
    @State private var promptText = ""
    @FocusState private var isInputFocused: Bool
    @StateObject private var counter = CoinCounter()
    @StateObject private var homeVM = HomeViewModel()
    @StateObject private var auth = AuthManager.shared
    @EnvironmentObject private var entitlementManager: EntitlementManager

    var displayCredits: Int { auth.currentUser?.credits ?? counter.coins }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear

                VStack(spacing: 0) {
                    // Top header
                    headerBar

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 0) {
                            // 4 category icons row (matches reference)
                            quickCategoryRow

                            // Prompt suggestions (matches reference)
                            promptSuggestionsSection

                            // Mode segment + content
                            modeSegment

                            if selectedMode == 0 {
                                VideoTab(
                                    showImagePicker: $showImagePicker,
                                    selectedOperation: $selectedOperation,
                                    isPremiumShow: $isPremiumShow,
                                    counter: counter,
                                    entitlementManager: entitlementManager
                                )
                            } else {
                                PhotoTab(
                                    showImagePicker: $showImagePicker,
                                    selectedOperation: $selectedOperation,
                                    selectedTemplate: $selectedTemplate,
                                    isPremiumShow: $isPremiumShow,
                                    counter: counter,
                                    entitlementManager: entitlementManager,
                                    homeVM: homeVM
                                )
                            }
                            Color.clear.frame(height: 140)
                        }
                    }

                    // Bottom input bar (matches reference)
                    homeInputBar
                }
            }
            .navigationBarHidden(true)
            .task { await homeVM.loadData() }
            .sheet(isPresented: $isPremiumShow) { PremiumView() }
            .sheet(isPresented: $showImagePicker, onDismiss: {
                if selectedImage != nil { isProcessing = true }
            }) {
                ImagePicker(image: $selectedImage)
            }
            .navigationDestination(isPresented: $isProcessing) {
                if let img = selectedImage {
                    ProcessingImage(image: img, operation: selectedOperation, promptText: promptText)
                } else {
                    ProcessingImage(operation: selectedOperation, promptText: promptText)
                }
            }
        }
    }

    // MARK: Header (matches reference: hamburger left, Upgrade Pro center, icon right)
    var headerBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            PremiumPill { isPremiumShow = true }

            Spacer()

            Image(systemName: "gearshape")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: Quick Category Row (matches reference: 4 rounded-square icons)
    var quickCategoryRow: some View {
        HStack(spacing: 14) {
            ForEach(quickCategories) { cat in
                Button {
                    promptText = cat.title
                    selectedOperation = .TextToImage
                } label: {
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Luris.card)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                                )
                            Image(systemName: cat.icon)
                                .font(.system(size: 22, weight: .light))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Text(cat.title)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 20)
    }

    // MARK: Prompt Suggestions (matches reference: dark cards with text + emoji)
    var promptSuggestionsSection: some View {
        VStack(alignment: .trailing, spacing: 10) {
            ForEach(promptSuggestions) { suggestion in
                Button {
                    promptText = suggestion.text
                } label: {
                    HStack(spacing: 8) {
                        Text(suggestion.text)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                        Text(suggestion.emoji)
                            .font(.system(size: 14))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Luris.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
            }

            Button { } label: {
                Text("Show more")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Luris.textSecondary)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: Mode Segment
    var modeSegment: some View {
        HStack(spacing: 4) {
            ForEach(["Video", "Photo"].indices, id: \.self) { idx in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedMode = idx
                    }
                } label: {
                    Text(["Video", "Photo"][idx])
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(selectedMode == idx ? .white : Luris.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if selectedMode == idx {
                                    Luris.accentGradient
                                } else {
                                    LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                                }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 13))
                        .shadow(color: selectedMode == idx ? Luris.accent.opacity(0.35) : .clear, radius: 6)
                }
            }
        }
        .padding(4)
        .background(Luris.card)
        .clipShape(RoundedRectangle(cornerRadius: 17))
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: Bottom Input Bar (matches reference: + settings icons, "Ask me anything...", send icon)
    var homeInputBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                }

                TextField("Ask me anything...", text: $promptText)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                    .tint(Luris.accent)
                    .focused($isInputFocused)

                Spacer()

                Button {
                    if !promptText.isEmpty {
                        selectedOperation = .TextToImage
                        if entitlementManager.hasPro || counter.coins > 0 {
                            if !entitlementManager.hasPro { counter.useCoin() }
                            showImagePicker = true
                        } else {
                            isPremiumShow = true
                        }
                    }
                } label: {
                    Image(systemName: promptText.isEmpty ? "mic" : "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(promptText.isEmpty ? Luris.textSecondary : .white)
                        .frame(width: 34, height: 34)
                        .background(promptText.isEmpty ? Luris.surface : Luris.accent)
                        .clipShape(Circle())
                }
                .animation(.spring(response: 0.2), value: promptText.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Luris.card.opacity(0.95))
        }
    }
}

// MARK: - Video Tab
struct VideoTab: View {
    @Binding var showImagePicker: Bool
    @Binding var selectedOperation: OperationType
    @Binding var isPremiumShow: Bool
    @ObservedObject var counter: CoinCounter
    @ObservedObject var entitlementManager: EntitlementManager

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            trendingSection
            exploreCategorySection
        }
    }

    // MARK: Trending
    var trendingSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Trending Models", subtitle: "Powered by latest AI")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(trendingData) { model in
                        TrendingCard(model: model, action: trigger)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: Explore Categories
    var exploreCategorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Explore by Category", subtitle: "Find your visual style")

            LazyVGrid(
                columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                spacing: 10
            ) {
                ForEach(categoryData) { cat in
                    CategoryCard(model: cat, action: trigger)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    func trigger() {
        selectedOperation = .TextToImage
        if entitlementManager.hasPro || counter.coins > 0 {
            if !entitlementManager.hasPro { counter.useCoin() }
            showImagePicker = true
        } else {
            isPremiumShow = true
        }
    }
}

// MARK: - Photo Tab
struct PhotoTab: View {
    @Binding var showImagePicker: Bool
    @Binding var selectedOperation: OperationType
    @Binding var selectedTemplate: TemplateItem?
    @Binding var isPremiumShow: Bool
    @ObservedObject var counter: CoinCounter
    @ObservedObject var entitlementManager: EntitlementManager
    @ObservedObject var homeVM: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            heroBanner
            if homeVM.isLoading {
                ProgressView().tint(Luris.accent).frame(maxWidth: .infinity).padding(.top, 20)
            } else if !homeVM.filteredTemplates.isEmpty {
                apiTemplatesSection
            } else {
                toolsGrid
            }
        }
    }

    // MARK: Backend Template Grid
    var apiTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            if !homeVM.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryPill(title: "All", isSelected: homeVM.selectedCategoryID == nil) {
                            homeVM.selectCategory(nil)
                        }
                        ForEach(homeVM.categories) { cat in
                            CategoryPill(title: cat.name, isSelected: homeVM.selectedCategoryID == cat.id) {
                                homeVM.selectCategory(cat.id)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            SectionHeader(title: "AI Templates", subtitle: "Tap a template to transform your photo")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(homeVM.filteredTemplates) { template in
                    TemplateCard(template: template) {
                        selectedTemplate = template
                        trigger(operation: .TextToImage)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: Luris.cardRadius)
                .fill(LinearGradient(
                    colors: [Color(hex: "0F0520"), Color(hex: "1A0A35"), Luris.accent.opacity(0.2)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))
                .frame(height: 190)

            Circle()
                .fill(Luris.accent.opacity(0.10))
                .frame(width: 130)
                .offset(x: 210, y: -50)
            Circle()
                .fill(Luris.accentRose.opacity(0.06))
                .frame(width: 80)
                .offset(x: 255, y: -95)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text("🍌").font(.system(size: 24))
                    Text("NEW")
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Luris.accentGradient)
                        .clipShape(Capsule())
                }
                Text("Nano Banana Pro")
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Next-gen photo intelligence")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Luris.accent)

                Button { trigger(operation: .TextToImage) } label: {
                    Text("Try Now →")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18).padding(.vertical, 7)
                        .background(Luris.accentGradient)
                        .clipShape(Capsule())
                        .accentGlow(radius: 6)
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .padding(.horizontal, 20)
        .clipped()
    }

    var toolsGrid: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Photo Tools", subtitle: "One-tap AI processing")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(photoTools) { tool in
                    PhotoToolCard(tool: tool) {
                        selectedOperation = tool.operation
                        trigger(operation: tool.operation)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    func trigger(operation: OperationType = .TextToImage) {
        selectedOperation = operation
        if entitlementManager.hasPro || counter.coins > 0 {
            if !entitlementManager.hasPro { counter.useCoin() }
            showImagePicker = true
        } else {
            isPremiumShow = true
        }
    }
}

// MARK: - Reusable Components

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Luris.textSecondary)
        }
        .padding(.horizontal, 20)
    }
}

struct TrendingCard: View {
    let model: TrendingModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(LinearGradient(
                        colors: [model.gradientStart, model.gradientEnd],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: 210, height: 140)

                VStack(alignment: .leading, spacing: 0) {
                    Text(model.badge)
                        .font(.system(size: 9, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Luris.accentGradient)
                        .clipShape(Capsule())

                    Spacer()

                    Text(model.title)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundStyle(.white)
                    Text(model.description)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .padding(16)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CategoryCard: View {
    let model: ExploreCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [model.gradientStart, model.gradientEnd],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .aspectRatio(1, contentMode: .fit)
                VStack(spacing: 5) {
                    Text(model.emoji).font(.system(size: 26))
                    Text(model.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Category Filter Pill
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? .white : Luris.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(isSelected ? Luris.accent : Luris.card)
                .clipShape(Capsule())
                .overlay(Capsule().stroke(isSelected ? Color.clear : Color(hex: "2A2A3E"), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Card (Backend)
struct TemplateCard: View {
    let template: TemplateItem
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .topLeading) {
                    if let afterURL = template.afterMediaUrl.flatMap(URL.init) {
                        AsyncImage(url: afterURL) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                            default:
                                Luris.card
                                    .overlay(Image(systemName: "photo").foregroundStyle(Luris.textSecondary))
                            }
                        }
                        .frame(height: 100)
                        .clipped()
                    } else {
                        LinearGradient(
                            colors: [Color(hex: "0F0520"), Color(hex: "1A0A35")],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        .frame(height: 100)
                        .overlay(
                            Image(systemName: iconFor(template.actionType))
                                .font(.system(size: 28))
                                .foregroundStyle(Luris.accent)
                        )
                    }

                    if template.isPremium {
                        Text("PRO")
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Luris.accentGradient)
                            .clipShape(Capsule())
                            .padding(8)
                    }
                }
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 16))

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(Luris.accent)
                        Text("\(template.creditCost) credit")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Luris.accent)
                        Spacer()
                        Text(template.provider)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Luris.textSecondary)
                            .lineLimit(1)
                    }
                }
                .padding(10)
                .background(Luris.card)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "2A2A3E"), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    func iconFor(_ actionType: String) -> String {
        switch actionType {
        case "ai_chat": return "bubble.left.and.bubble.right.fill"
        case "upscale": return "square.resize.up"
        case "remove_bg": return "person.and.background.striped.horizontal"
        case "photo_restoration": return "photo.badge.plus"
        default: return "wand.and.sparkles"
        }
    }
}

struct PhotoToolCard: View {
    let tool: PhotoTool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: tool.icon)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(Luris.accent)

                Spacer()

                VStack(alignment: .leading, spacing: 3) {
                    Text(tool.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    Text(tool.subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                }

                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Luris.accent)
                    Text("1 Credit")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Luris.accent)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Luris.textSecondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 140)
            .background(Luris.card)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "2A2A3E"), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeView()
        .environmentObject(EntitlementManager())
}
