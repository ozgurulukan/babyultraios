import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var photoCategories: [CategoryItem] = []
    @Published var videoCategories: [CategoryItem] = []
    @Published var virtualFilters: [CategoryItem] = []
    @Published var photoTemplates: [TemplateItem] = []
    @Published var videoTemplates: [TemplateItem] = []
    @Published var filteredTemplates: [TemplateItem] = []
    @Published var sliderItems: [SliderItem] = []
    @Published var quickButtons: [QuickButtonItem] = []
    @Published var selectedCategoryID: String? = nil
    @Published var selectedFilter: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false
    @Published var debugInfo: String = ""
    @Published var selectedMode: Int = 1
    @Published var activeAudioCardID: String? = nil {
        didSet {
            NotificationCenter.default.post(
                name: .templateAudioChanged,
                object: nil,
                userInfo: ["cardID": activeAudioCardID as Any]
            )
        }
    }

    /// O(1) category name lookup cache. Rebuilt whenever categories change.
    private(set) var categoryNameCache: [Int: String] = [:]

    /// Pre-grouped templates by category ID for category rows.
    /// Rebuilt whenever templates or mode changes.
    @Published var templatesByCategory: [Int: [TemplateItem]] = [:]

    private var currentTemplates: [TemplateItem] {
        selectedMode == 0 ? videoTemplates : photoTemplates
    }

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        debugInfo = "Loading..."

        var didLoadAnySection = false
        var rateLimitWait: Int?
        var firstErrorMessage: String?

        do {
            let c = try await BabyUltraAPI.shared.getCategories()
            virtualFilters = c.filter { $0.isVirtual == true }
            photoCategories = c.filter { $0.isVirtual != true && $0.type == "photo" }
            videoCategories = c.filter { $0.isVirtual != true && $0.type == "video" }
            rebuildCategoryNameCache()
            didLoadAnySection = true
        } catch APIError.rateLimited(let secs) {
            rateLimitWait = max(rateLimitWait ?? 0, secs)
            debugInfo = "Categories rate-limited (\(secs)s), using existing data."
        } catch APIError.unauthorized {
            firstErrorMessage = "Not signed in. Please restart the app."
        } catch APIError.forbidden {
            firstErrorMessage = "Your account has been restricted."
        } catch {
            firstErrorMessage = error.localizedDescription
        }

        do {
            async let photosTask = BabyUltraAPI.shared.getTemplates(type: "photo")
            async let videosTask = BabyUltraAPI.shared.getTemplates(type: "video")
            photoTemplates = try await photosTask
            videoTemplates = try await videosTask
            didLoadAnySection = true
        } catch APIError.rateLimited(let secs) {
            rateLimitWait = max(rateLimitWait ?? 0, secs)
            debugInfo = "Templates rate-limited (\(secs)s), using existing data."
        } catch APIError.unauthorized {
            firstErrorMessage = "Not signed in. Please restart the app."
        } catch APIError.forbidden {
            firstErrorMessage = "Your account has been restricted."
        } catch {
            firstErrorMessage = error.localizedDescription
        }

        do {
            let sliderType = selectedMode == 0 ? "video" : "photo"
            let s = try await BabyUltraAPI.shared.getSlider(type: sliderType)
            sliderItems = s
            didLoadAnySection = true
        } catch APIError.rateLimited(let secs) {
            rateLimitWait = max(rateLimitWait ?? 0, secs)
        } catch {
            if firstErrorMessage == nil {
                firstErrorMessage = error.localizedDescription
            }
        }

        applyFilter()
        hasLoaded = hasLoaded || didLoadAnySection || !photoTemplates.isEmpty || !videoTemplates.isEmpty

        if let wait = rateLimitWait, !hasLoaded {
            errorMessage = "Rate limit reached. Try again in \(wait)s."
            debugInfo = "Rate limited \(wait)s"
        } else if let wait = rateLimitWait, errorMessage == nil {
            errorMessage = "Some data is temporarily rate-limited. Showing available content."
            debugInfo = "Rate limited \(wait)s (partial data shown)"
        } else if let firstErrorMessage {
            errorMessage = firstErrorMessage
            if debugInfo.isEmpty {
                debugInfo = firstErrorMessage
            }
        } else {
            debugInfo = ""
        }

        isLoading = false
    }

    func refresh() async {
        hasLoaded = false
        await loadData()
    }

    func loadSlider() async {
        do {
            let sliderType = selectedMode == 0 ? "video" : "photo"
            sliderItems = try await BabyUltraAPI.shared.getSlider(type: sliderType)
        } catch {
            debugInfo = "Slider load failed: \(error.localizedDescription)"
        }
    }

    func selectCategory(_ id: String?) {
        selectedCategoryID = id
        selectedFilter = nil
        applyFilter()
    }

    func selectFilter(_ filter: String?) {
        selectedFilter = filter
        selectedCategoryID = nil
        applyFilter()
    }

    func switchMode(_ mode: Int) {
        guard selectedMode != mode || selectedCategoryID != nil || selectedFilter != nil else { return }
        selectedMode = mode
        selectedCategoryID = nil
        selectedFilter = nil
        applyFilter()
    }

    func applyFilterForMode(_ mode: Int) {
        selectedMode = mode
        applyFilter()
    }

    private func applyFilter() {
        let allTemplates = currentTemplates
        if let filter = selectedFilter {
            switch filter {
            case "popular":
                filteredTemplates = allTemplates.filter { $0.isPopular }
            case "trending":
                filteredTemplates = allTemplates.filter { $0.isViral }
            default:
                filteredTemplates = allTemplates
            }
        } else if let id = selectedCategoryID, let catId = Int(id.components(separatedBy: "_").first ?? "") {
            filteredTemplates = allTemplates.filter { $0.categoryId == catId }
        } else {
            filteredTemplates = allTemplates.filter { !($0.hideFromAll ?? false) }
        }
        rebuildTemplatesByCategory()
    }

    private func rebuildCategoryNameCache() {
        var map: [Int: String] = [:]
        for cat in photoCategories { map[cat.rawID] = cat.name }
        for cat in videoCategories { map[cat.rawID] = cat.name }
        categoryNameCache = map
    }

    private func rebuildTemplatesByCategory() {
        let all = currentTemplates
        var map: [Int: [TemplateItem]] = [:]
        for t in all {
            guard let cid = t.categoryId else { continue }
            map[cid, default: []].append(t)
        }
        templatesByCategory = map
    }

    func canAfford(_ template: TemplateItem, credits: Int) -> Bool {
        credits >= template.creditCost
    }

    func categoryName(for template: TemplateItem) -> String? {
        guard let catId = template.categoryId else { return nil }
        return categoryNameCache[catId]
    }

    func templateForQuickButton(_ button: QuickButtonItem) -> TemplateItem? {
        guard let tid = button.templateId else { return nil }
        return photoTemplates.first { $0.id == tid }
    }

    func templateForSlider(_ item: SliderItem) -> TemplateItem? {
        guard let templateId = item.templateId else { return nil }
        return (photoTemplates + videoTemplates).first { $0.id == templateId }
    }
}
