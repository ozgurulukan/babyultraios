import SwiftUI

struct GenerationsView: View {
    @StateObject private var viewModel = GenerationsViewModel()
    @State private var selectedFilter = 0
    private let filters = ["All", "Success", "Processing"]

    private var filteredItems: [HistoryItem] {
        switch selectedFilter {
        case 1: return viewModel.history.filter { $0.status == "success" }
        case 2: return viewModel.history.filter { $0.status != "success" }
        default: return viewModel.history
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "FFF9EC").ignoresSafeArea()

                StickyBlurHeader(
                    maxBlurRadius: 8,
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
                    if viewModel.isLoading && viewModel.history.isEmpty {
                        loadingState
                    } else if filteredItems.isEmpty {
                        emptyState
                    } else {
                        mainContent
                    }
                }
            }
            .task {
                await viewModel.loadHistory()
            }
            .refreshable { await viewModel.refresh() }
        }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            filterBar

            VStack(spacing: 20) {
                ForEach(filteredItems) { item in
                    GenerationHistoryCard(item: item)
                        .onAppear {
                            if item.id == filteredItems.last?.id {
                                Task { await viewModel.loadMore() }
                            }
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

            Color.clear.frame(height: 120)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }

    private var loadingState: some View {
        VStack(spacing: 14) {
            ProgressView().tint(Color(hex: "97462E"))
            Text("Loading generations…")
                .foregroundStyle(Color(hex: "55433E"))
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .padding(.horizontal, 24)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 42))
                .foregroundStyle(Color(hex: "97462E").opacity(0.8))
            Text("No Generations Yet")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: "1E1C10"))
            Text("Create your first AI transformation and it will appear here.")
                .font(.system(size: 15))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: "55433E"))
                .padding(.horizontal, 26)
        }
        .frame(maxWidth: .infinity, minHeight: 320)
        .padding(.horizontal, 24)
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
}

private struct GenerationHistoryCard: View {
    let item: HistoryItem

    private var isSuccess: Bool { item.status == "success" }
    private var displayURL: String? { item.resultUrl ?? item.imageUrl }
    private var title: String {
        if let prompt = item.prompt?.trimmingCharacters(in: .whitespacesAndNewlines), !prompt.isEmpty {
            return String(prompt.prefix(26))
        }
        return item.provider.capitalized
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                media
                    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                    .overlay {
                        if !isSuccess {
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .fill(Color(hex: "E9E2D0").opacity(0.35))
                        }
                    }

                if !isSuccess {
                    VStack(spacing: 8) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Image(systemName: "sparkles")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(Color(hex: "97462E"))
                            )
                        Text("Weaving magic...")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color(hex: "1E1C10"))
                        Text("Estimating 2 mins left")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "55433E"))
                    }
                }
            }
            .frame(height: 360)

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

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color(hex: "1E1C10"))
                        .lineLimit(1)
                    Text(isSuccess ? "Generated \(relativeDate(item.createdAt))" : "Generating now")
                        .font(.system(size: 14))
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
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 40, style: .continuous).fill(.white))
        .shadow(color: .black.opacity(0.06), radius: 14, y: 8)
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

#Preview {
    GenerationsView()
}
