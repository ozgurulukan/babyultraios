import SwiftUI

// MARK: - Generations View
struct GenerationsView: View {
    @StateObject private var viewModel = GenerationsViewModel()
    @State private var selectedFilter = 0
    private let filters = ["All", "Success", "Processing"]
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var filteredItems: [HistoryItem] {
        switch selectedFilter {
        case 1: return viewModel.history.filter { $0.status == "success" }
        case 2: return viewModel.history.filter { $0.status != "success" }
        default: return viewModel.history
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 0) {
                header
                filterBar
                Rectangle().fill(Color(hex: "1C1C2E")).frame(height: 0.5)

                if viewModel.isLoading && viewModel.history.isEmpty {
                    loadingState
                } else if filteredItems.isEmpty {
                    emptyState
                } else {
                    galleryGrid
                }
            }
        }
        .task { await viewModel.loadHistory() }
        .refreshable { await viewModel.refresh() }
    }

    // MARK: Header
    var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Generations")
                    .font(.system(size: 28, weight: .heavy))
                    .foregroundStyle(.white)
                Text("Your AI creations")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Luris.textSecondary)
            }
            Spacer()
            Button { Task { await viewModel.refresh() } } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Luris.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(hex: "2A2A3E"), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
    }

    // MARK: Filter Bar
    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters.indices, id: \.self) { idx in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedFilter = idx }
                    } label: {
                        Text(filters[idx])
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(selectedFilter == idx ? .white : Luris.textSecondary)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 8)
                            .background(selectedFilter == idx ? Luris.accent : Luris.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selectedFilter == idx ? Color.clear : Color(hex: "2A2A3E"), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }

    // MARK: Loading State
    var loadingState: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .tint(Luris.accent)
                .scaleEffect(1.4)
            Text("Loading generations…")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Luris.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Empty State
    var emptyState: some View {
        VStack(spacing: 24) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Luris.accent.opacity(0.10))
                    .frame(width: 110, height: 110)
                Circle()
                    .fill(Luris.accent.opacity(0.05))
                    .frame(width: 150, height: 150)
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Luris.accent)
            }
            VStack(spacing: 8) {
                Text("No Generations Yet")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                Text("Create your first AI transformation\nand it will appear here")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Luris.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Gallery Grid
    var galleryGrid: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(filteredItems) { item in
                    HistoryCell(item: item)
                        .onAppear {
                            if item.id == filteredItems.last?.id {
                                Task { await viewModel.loadMore() }
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)

            if viewModel.isLoadingMore {
                ProgressView().tint(Luris.accent).padding()
            }
        }
    }
}

// MARK: - History Cell
struct HistoryCell: View {
    let item: HistoryItem

    var displayURL: String? { item.resultUrl ?? item.imageUrl }
    var isSuccess: Bool { item.status == "success" }

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Image
            if let urlStr = displayURL, let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure:
                        placeholderGradient
                    default:
                        Luris.card.overlay(ProgressView().tint(Luris.accent))
                    }
                }
                .frame(maxWidth: .infinity)
                .clipped()
            } else {
                placeholderGradient
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.78)],
                startPoint: .center, endPoint: .bottom
            )

            // Meta
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(isSuccess ? Luris.accent : Color.orange)
                        .frame(width: 6, height: 6)
                    Text(item.provider)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Luris.accent)
                        .lineLimit(1)
                }
                if let prompt = item.prompt, !prompt.isEmpty {
                    Text(prompt)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                }
                Text(relativeDate(item.createdAt))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(10)
        }
        .aspectRatio(0.75, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    var placeholderGradient: some View {
        LinearGradient(
            colors: [Color(hex: "0F0520"), Color(hex: "1A0A35")],
            startPoint: .topLeading, endPoint: .bottomTrailing
        )
    }

    func relativeDate(_ iso: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: iso) {
            let rel = RelativeDateTimeFormatter()
            rel.unitsStyle = .abbreviated
            return rel.localizedString(for: date, relativeTo: Date())
        }
        return iso
    }
}

#Preview {
    GenerationsView()
}
