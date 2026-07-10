import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var photoCategories: [CategoryItem] = []
    @Published var virtualFilters: [CategoryItem] = []
    @Published var photoTemplates: [TemplateItem] = []
    @Published var filteredTemplates: [TemplateItem] = []
        @Published var selectedCategoryID: String? = nil
    @Published var selectedFilter: String? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false
    @Published var debugInfo: String = ""

    /// O(1) category name lookup cache. Rebuilt whenever categories change.
    private(set) var categoryNameCache: [Int: String] = [:]

    /// Pre-grouped templates by category ID for category rows.
    /// Rebuilt whenever templates or mode changes.
    @Published var templatesByCategory: [Int: [TemplateItem]] = [:]

    private var currentTemplates: [TemplateItem] {
        photoTemplates
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
            photoTemplates = try await BabyUltraAPI.shared.getTemplates(type: "photo")
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

        

        applyFilter()
        hasLoaded = hasLoaded || didLoadAnySection || !photoTemplates.isEmpty

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

    }
