import Foundation
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var categories: [CategoryItem] = []
    @Published var templates: [TemplateItem] = []
    @Published var filteredTemplates: [TemplateItem] = []
    @Published var sliderItems: [SliderItem] = []
    @Published var selectedCategoryID: Int? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasLoaded = false

    // MARK: - Load Everything
    func loadData() async {
        guard !hasLoaded else { return }
        isLoading = true
        defer { isLoading = false }

        async let cats = LurisAPI.shared.getCategories()
        async let tmps = LurisAPI.shared.getTemplates()
        async let sldr = LurisAPI.shared.getSlider()

        do {
            let (c, t, s) = try await (cats, tmps, sldr)
            categories = c
            templates = t
            sliderItems = s
            applyFilter()
            hasLoaded = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        hasLoaded = false
        await loadData()
    }

    // MARK: - Category Filter
    func selectCategory(_ id: Int?) {
        selectedCategoryID = id
        applyFilter()
    }

    private func applyFilter() {
        if let id = selectedCategoryID {
            filteredTemplates = templates.filter { $0.categoryId == id }
        } else {
            filteredTemplates = templates
        }
    }

    // MARK: - Computed Subsets
    var featuredTemplates: [TemplateItem] {
        templates.filter { $0.isFeatured }.prefix(6).map { $0 }
    }

    var freeTemplates: [TemplateItem] {
        filteredTemplates.filter { !$0.isPremium }
    }

    var premiumTemplates: [TemplateItem] {
        filteredTemplates.filter { $0.isPremium }
    }

    // MARK: - Credit Check
    func canAfford(_ template: TemplateItem, credits: Int) -> Bool {
        credits >= template.creditCost
    }
}
