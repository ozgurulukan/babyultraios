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

    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        debugInfo = "Loading..."

        var didLoadAnySection = false
        var rateLimitWait: Int?
        var firstErrorMessage: String?

        do {
            let c = try await BubsieAPI.shared.getCategories()
            virtualFilters = c.filter { $0.isVirtual == true }
            photoCategories = c.filter { $0.isVirtual != true && $0.type == "photo" }
            videoCategories = c.filter { $0.isVirtual != true && $0.type == "video" }
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
            let t = try await BubsieAPI.shared.getTemplates()
            // Match templates to photo categories by rawID (not stableID)
            photoTemplates = t.filter { template in
                guard let catId = template.categoryId else { return true }
                return photoCategories.contains { $0.rawID == catId } || catId == 0
            }
            // Fallback: if category filtering yields nothing (or no categories exist), show all non-video templates
            if photoTemplates.isEmpty {
                photoTemplates = t.filter { $0.actionType != "video" }
            }
            videoTemplates = t.filter { $0.actionType == "video" }
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
            let s = try await BubsieAPI.shared.getSlider()
            sliderItems = s
            didLoadAnySection = true
        } catch APIError.rateLimited(let secs) {
            rateLimitWait = max(rateLimitWait ?? 0, secs)
        } catch {
            if firstErrorMessage == nil {
                firstErrorMessage = error.localizedDescription
            }
        }

        do {
            let b = try await BubsieAPI.shared.getQuickButtons(type: "photo")
            quickButtons = b
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

    func selectCategory(_ id: String?) {
        selectedCategoryID = id
        selectedFilter = nil
        applyFilterForMode(selectedMode)
    }

    func selectFilter(_ filter: String?) {
        selectedFilter = filter
        selectedCategoryID = nil
        applyFilterForMode(selectedMode)
    }

    func applyFilterForMode(_ mode: Int) {
        selectedMode = mode
        let allTemplates = mode == 0 ? videoTemplates : photoTemplates

        if let filter = selectedFilter {
            switch filter {
            case "popular":
                filteredTemplates = Array(allTemplates.filter { $0.isFeatured }.prefix(10))
            case "trending":
                filteredTemplates = Array(allTemplates.prefix(10))
            default:
                filteredTemplates = allTemplates
            }
        } else if let id = selectedCategoryID, let catId = Int(id.components(separatedBy: "_").first ?? "") {
            filteredTemplates = allTemplates.filter { $0.categoryId == catId }
        } else {
            filteredTemplates = allTemplates.filter { !($0.hideFromAll ?? false) }
        }
    }

    private func applyFilter() {
        applyFilterForMode(selectedMode)
    }

    func canAfford(_ template: TemplateItem, credits: Int) -> Bool {
        credits >= template.creditCost
    }

    func templateForQuickButton(_ button: QuickButtonItem) -> TemplateItem? {
        guard let tid = button.templateId else { return nil }
        return photoTemplates.first { $0.id == tid }
    }
}
