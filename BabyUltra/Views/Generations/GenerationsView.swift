import SwiftUI

struct GenerationsView: View {
    @StateObject private var viewModel = GenerationsViewModel()
    @State private var selectedFilter = 0
    @State private var selectedResult: HistoryResultRoute?
    @State private var pendingDeleteItem: HistoryItem?
    private let filters = [
        NSLocalizedString("generations.filter_all", comment: ""),
        NSLocalizedString("generations.filter_success", comment: ""),
        NSLocalizedString("generations.filter_processing", comment: "")
    ]

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
                Image("bg")
                    .resizable()
                    .ignoresSafeArea()

                StickyBlurHeader(
                    maxBlurRadius: 10,
                    fadeExtension: 84,
                    tintOpacityTop: 0.58,
                    tintOpacityMiddle: 0.36
                ) {
                    ProfileStyleHeader(
                        title: NSLocalizedString("generations.title", comment: ""),
                        subtitle: NSLocalizedString("generations.subtitle", comment: "")
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
            .sheet(item: $selectedResult) { route in
                ResultView(resultURL: route.url, actionType: route.actionType)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
            .alert(NSLocalizedString("generations.delete_alert_title", comment: ""), isPresented: .constant(pendingDeleteItem != nil)) {
                Button(NSLocalizedString("common.delete", comment: ""), role: .destructive) {
                    if let item = pendingDeleteItem {
                        Task { await viewModel.deleteHistoryItem(id: item.id) }
                    }
                    pendingDeleteItem = nil
                }
                Button(NSLocalizedString("common.cancel", comment: ""), role: .cancel) { pendingDeleteItem = nil }
            } message: {
                Text(NSLocalizedString("generations.delete_alert_message", comment: ""))
            }
            .alert(NSLocalizedString("common.error", comment: ""), isPresented: .constant(viewModel.errorMessage != nil)) {
                Button(NSLocalizedString("common.ok", comment: "")) { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var cardsContent: some View {
        VStack(spacing: 14) {
            ForEach(filteredItems) { item in
                GenerationHistoryCard(item: item, viewModel: viewModel)
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
                            Label(NSLocalizedString("common.delete", comment: ""), systemImage: "trash")
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
                    ProgressView().tint(Color(hex: "FF4D85"))
                    Spacer()
                }
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Color(hex: "FF4D85"))
            Text(NSLocalizedString("generations.loading", comment: ""))
                .foregroundStyle(Color(hex: "8D7F7A"))
        }
        .frame(maxWidth: .infinity, minHeight: 280)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: selectedFilter == 2 ? "clock.badge.xmark.fill" : "photo.stack.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color(hex: "FF4D85").opacity(0.8))
            Text(selectedFilter == 2 ? NSLocalizedString("generations.no_processing_title", comment: "") : NSLocalizedString("generations.empty_title", comment: ""))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: "2D2422"))
            Text(selectedFilter == 2 ? NSLocalizedString("generations.no_processing_message", comment: "") : NSLocalizedString("generations.empty_message", comment: ""))
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "8D7F7A"))
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
                            .foregroundStyle(selectedFilter == idx ? .white : Color(hex: "8D7F7A"))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(
                                        selectedFilter == idx
                                        ? AnyShapeStyle(
                                            LinearGradient(
                                                colors: [Color(hex: "FF4D85"), Color(hex: "FF88A8")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        : AnyShapeStyle(Color(hex: "FFF3F1"))
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
        let actionType = "image"
        return HistoryResultRoute(id: item.id, url: url, actionType: actionType)
    }
}

private struct GenerationHistoryCard: View {
    let item: HistoryItem
    @ObservedObject var viewModel: GenerationsViewModel

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
                                    .foregroundStyle(Color(hex: "FF4D85"))
                            )
                        Text(NSLocalizedString("card.processing", comment: ""))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: "2D2422"))
                    }
                }


            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isSuccess ? String(format: NSLocalizedString("card.generated", comment: ""), relativeDate(item.createdAt)) : NSLocalizedString("card.generating_now", comment: ""))
                        .font(.system(size: 13))
                        .foregroundStyle(Color(hex: "8D7F7A"))
                }
                Spacer()
                Text(isSuccess ? NSLocalizedString("card.success", comment: "") : NSLocalizedString("card.processing", comment: ""))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSuccess ? Color(hex: "245A22") : Color(hex: "6F4600"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(isSuccess ? Color(hex: "DFF4DE") : Color(hex: "FF88A8")))
            }

            if !isSuccess {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 999)
                        .fill(Color(hex: "FFF3F1"))
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 999)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF4D85"), Color(hex: "FF88A8"), Color(hex: "FF4D85")],
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
                        placeholder.overlay(ProgressView().tint(Color(hex: "FF4D85")))
                    }
                }
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: 32, style: .continuous)
            .fill(Color(hex: "FFF3F1"))
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

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.view.isUserInteractionEnabled = false
        if let player = context.coordinator.player {
            player.isMuted = isMuted
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        var player: AVPlayer?
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: Coordinator) {
        uiViewController.player?.pause()
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
