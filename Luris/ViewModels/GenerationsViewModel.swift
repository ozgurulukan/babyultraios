import Foundation
import SwiftUI

@MainActor
final class GenerationsViewModel: ObservableObject {
    @Published var history: [HistoryItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = true
    @Published var errorMessage: String?

    private var currentPage = 1
    private let pageSize = 20

    // MARK: - Initial Load
    func loadHistory() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        currentPage = 1
        do {
            let items = try await LurisAPI.shared.getHistory(page: 1, limit: pageSize)
            history = items
            hasMore = items.count == pageSize
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load More (pagination)
    func loadMore() async {
        guard hasMore, !isLoadingMore, !isLoading else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        let nextPage = currentPage + 1
        do {
            let items = try await LurisAPI.shared.getHistory(page: nextPage, limit: pageSize)
            if items.isEmpty {
                hasMore = false
            } else {
                history.append(contentsOf: items)
                currentPage = nextPage
                hasMore = items.count == pageSize
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Refresh
    func refresh() async {
        await loadHistory()
    }

    // MARK: - Filtered by status
    var successItems: [HistoryItem] {
        history.filter { $0.status == "success" }
    }
}
