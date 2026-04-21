import SwiftUI

struct GenerationsView: View {
    @StateObject private var viewModel = GenerationsViewModel()
    @State private var selectedFilter = 0
    @State private var selectedResult: HistoryResultRoute?
    @State private var pendingDeleteItem: HistoryItem?
    private let filters = ["All", "Success", "Processing"]

    private var filteredItems: [HistoryItem] {
        switch selectedFilter {
        case 1: return viewModel.history.filter { $0.status == "success" }
        case 2: return viewModel.history.filter { isProcessingStatus($0.status) }
        default: return viewModel.history
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FFF9EC").ignoresSafeArea()

                StickyBlurHeader(
                    maxBlurRadius: 10,
                    fadeExtension: 84,
                    tintOpacityTop: 0.58,
                    tintOpacityMiddle: 0.36
                ) {
                    ProfileStyleHeader(
                        title: "Generations",
                        subtitle: "Your magical moments, beautifully crafted."
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                } content: {
                    VStack(alignment: .leading, spacing: 20) {
                        filterBar

                        if viewModel.isLoading && viewModel.history.isEmpty {
                            loadingState
                        } else if filteredItems.isEmpty {
                            emptyState
                        } else {
                            cardsContent
                        }

                        Color.clear.frame(height: 120)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                }
                .environment(\.colorScheme, .light)
            }
            .task { await viewModel.loadHistory() }
            .refreshable { await viewModel.refresh() }
            .navigationDestination(item: $selectedResult) { route in
                ResultView(resultURL: route.url, actionType: route.actionType)
            }
            .alert("Delete generation?", isPresented: .constant(pendingDeleteItem != nil)) {
                Button("Delete", role: .destructive) {
                    if let item = pendingDeleteItem {
                        Task { await viewModel.deleteHistoryItem(id: item.id) }
                    }
                    pendingDeleteItem = nil
                }
                Button("Cancel", role: .cancel) { pendingDeleteItem = nil }
            } message: {
                Text("This will permanently remove it from your account.")
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var cardsContent: some View {
        VStack(spacing: 14) {
            ForEach(filteredItems) { item in
                GenerationHistoryCard(item: item)
                    .contentShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .onTapGesture {
                        if let route = historyRoute(for: item) {
                            selectedResult = route
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            pendingDeleteItem = item
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .onAppear {
                        if item.id == filteredItems.last?.id {
                            Task { await viewModel.loadMore() }
                        }
                    }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView().tint(Color(hex: "97462E"))
                    Spacer()
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Color(hex: "97462E"))
            Text("Loading generations…")
                .foregroundStyle(Color(hex: "55433E"))
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedFilter == 2 ? "clock.badge.xmark.fill" : "photo.stack.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color(hex: "97462E").opacity(0.8))
            Text(selectedFilter == 2 ? "No Processing Generations" : "No Generations Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: "1E1C10"))
            Text(selectedFilter == 2 ? "There are no generations in queue right now." : "Create your first AI transformation and it will appear here.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "55433E"))
                .padding(.horizontal, 26)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters.indices, id: \.self) { idx in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selectedFilter = idx }
                    } label: {
                        Text(filters[idx])
                            .font(.system(size: 16, weight: selectedFilter == idx ? .bold : .semibold))
                            .foregroundStyle(selectedFilter == idx ? .white : Color(hex: "55433E"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedFilter == idx
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "97462E"), Color(hex: "F08C6E")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(Color(hex: "FAF3E0"))
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func isProcessingStatus(_ status: String) -> Bool {
        let normalized = status.lowercased()
        return normalized == "processing" || normalized == "pending" || normalized == "queued" || normalized == "running"
    }

    private func historyRoute(for item: HistoryItem) -> HistoryResultRoute? {
        guard let url = item.resultUrl ?? item.imageUrl, !url.isEmpty else { return nil }
        let ext = URL(string: url)?.pathExtension.lowercased() ?? ""
        let videoExts = ["mp4", "mov", "m4v", "webm"]
        let actionType = videoExts.contains(ext) ? "video" : "image"
        return HistoryResultRoute(id: item.id, url: url, actionType: actionType)
    }
}

private struct GenerationHistoryCard: View {
    let item: HistoryItem

    private var isSuccess: Bool { item.status == "success" }
    private var displayURL: String? { item.resultUrl ?? item.imageUrl }
    private var title: String {
        if let prompt = item.prompt?.trimmingCharacters(in: .whitespacesAndNewlines), !prompt.isEmpty {
            if let explicit = prompt
                .components(separatedBy: .newlines)
                .first(where: { $0.lowercased().contains("template:") })?
                .components(separatedBy: ":")
                .dropFirst()
                .joined(separator: ":")
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !explicit.isEmpty {
                return explicit
            }

            let firstLine = prompt.components(separatedBy: .newlines).first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !firstLine.isEmpty && firstLine.lowercased() != "visual composition & style" {
                return String(firstLine.prefix(32))
            }
        }

        if let model = item.model, !model.isEmpty {
            return model
        }
        return item.provider.capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                media
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [.clear, Color(hex: "6E4639").opacity(0.34)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                        if !isSuccess {
                            RoundedRectangle(cornerRadius: 28, style: .continuous)
                                .fill(Color(hex: "E9E2D0").opacity(0.35))
                        }
                    }

                if !isSuccess {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 58, height: 58)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(Color(hex: "97462E"))
                            )
                        Text("Processing...")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: "1E1C10"))
                    }
                }
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isSuccess ? "Generated \(relativeDate(item.createdAt))" : "Generating now")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "55433E"))
                }
                Spacer()
                Text(isSuccess ? "Success" : "Processing")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSuccess ? Color(hex: "245A22") : Color(hex: "6F4600"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(isSuccess ? Color(hex: "DFF4DE") : Color(hex: "FEB246")))
            }

            if !isSuccess {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color(hex: "F4EEDB"))
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "97462E"), Color(hex: "F08C6E"), Color(hex: "97462E")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geo.size.width * 0.72)
                        }
                }
                .frame(height: 8)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(Color.white.opacity(0.32))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.62), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 6)
    }

    private var media: some View {
        Group {
            if let urlString = displayURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .blur(radius: isSuccess ? 0 : 2)
                            .saturation(isSuccess ? 1 : 0.5)
                    case .failure:
                        placeholder
                    default:
                        placeholder.overlay(ProgressView().tint(Color(hex: "97462E")))
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(Color(hex: "F4EEDB"))
    }

    private func relativeDate(_ iso: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = isoFormatter.date(from: iso) ?? ISO8601DateFormatter().date(from: iso)
        guard let date else { return "recently" }
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .full
        return rel.localizedString(for: date, relativeTo: Date())
    }
}

private struct HistoryResultRoute: Identifiable, Hashable {
    let id: Int
    let url: String
    let actionType: String
}

#Preview {
    GenerationsView()
}
