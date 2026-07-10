import SwiftUI

struct ChatEditView: View {
    @StateObject private var viewModel = ChatEditViewModel.shared
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @State private var showPaywall = false

    private var isPro: Bool {
        AuthManager.shared.currentUser?.isPro ?? entitlementManager.hasPro
    }

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            StickyBlurHeader(
                maxBlurRadius: 10,
                fadeExtension: 84,
                tintOpacityTop: 0.58,
                tintOpacityMiddle: 0.36
            ) {
                headerBar
                    .padding(.bottom, 8)
            } content: {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(viewModel.chatItems) { item in
                        ChatRow(item: item)
                    }

                    if viewModel.isLoading {
                        HStack {
                            botAvatar
                            ProgressView()
                                .padding(.vertical, 16)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                    }

                    tipCard
                    if viewModel.chatItems.count <= 1 {
                        suggestionChips
                    }
                    Color.clear.frame(height: 16)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .environment(\.colorScheme, .light)
        }
        .safeAreaInset(edge: .bottom) {
            inputBar
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 16)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "FFF3F1").opacity(0.0), Color(hex: "FFF3F1").opacity(0.92), Color(hex: "FFF3F1")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
        }
        .sheet(isPresented: $showPaywall) {
            PremiumView()
        }
    }

    private var chatBackground: some View {
        ZStack {
            Color(hex: "FFF3F1")
            RadialGradient(colors: [Color(hex: "FF88A8").opacity(0.12), .clear], center: .topLeading, startRadius: 10, endRadius: 260)
            RadialGradient(colors: [Color(hex: "FF88A8").opacity(0.12), .clear], center: .topTrailing, startRadius: 10, endRadius: 260)
            RadialGradient(colors: [Color(hex: "FF4D85").opacity(0.08), .clear], center: .bottomTrailing, startRadius: 10, endRadius: 260)
            RadialGradient(colors: [Color(hex: "FF88A8").opacity(0.10), .clear], center: .bottomLeading, startRadius: 10, endRadius: 260)
        }
    }

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("chat.title", comment: ""))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "2D2422"))
                Text(NSLocalizedString("chat.subtitle", comment: ""))
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "8D7F7A"))
            }
            Spacer()
            Button {
                viewModel.clearChat()
            } label: {
                Text(NSLocalizedString("chat.clear_chat", comment: ""))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color(hex: "FF4D85"))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: "FFF3F1")))
                    .overlay(Capsule().stroke(Color(hex: "E9E2D0").opacity(0.4), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "FF88A8"))
                .frame(width: 24, height: 24)

            Text(NSLocalizedString("chat.tip", comment: ""))
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "8D7F7A"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(hex: "FFF3F1")))
    }

    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                suggestionChip(viewModel.suggestions[0])
                suggestionChip(viewModel.suggestions[1])
            }
            suggestionChip(viewModel.suggestions[2])
        }
    }

    private func suggestionChip(_ text: String) -> some View {
        Button {
            viewModel.selectSuggestion(text)
        } label: {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "8D7F7A"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(hex: "FFF3F1")))
                .overlay(Capsule().stroke(Color(hex: "E9E2D0").opacity(0.3), lineWidth: 1))
                .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            ZStack(alignment: .leading) {
                if viewModel.inputText.isEmpty {
                    Text(NSLocalizedString("chat.input_placeholder", comment: ""))
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "8D7F7A"))
                        .shimmer()
                }
                TextField("", text: $viewModel.inputText)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "2D2422"))
                    .tint(Color(hex: "FF4D85"))
            }

            Button {
                guard isPro else {
                    showPaywall = true
                    return
                }
                viewModel.sendMessage()
            } label: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF4D85"), Color(hex: "FF88A8")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            .opacity(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading ? 0.6 : 1)
        }
        .padding(8)
        .background(
            Capsule()
                .fill(.white)
                .overlay(Capsule().stroke(Color(hex: "E9E2D0").opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        )
    }

    private var botAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "FF4D85"), Color(hex: "FF88A8")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: Color(hex: "FF4D85").opacity(0.25), radius: 8, y: 4)
    }
}

private struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.7), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 1.5)
                    .offset(x: phase * geo.size.width * 1.5)
                }
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

private extension View {
    func shimmer() -> some View {
        modifier(Shimmer())
    }
}

enum Sender {
    case ai
    case user
}

struct ChatItem: Identifiable {
    let id = UUID()
    let text: String
    let sender: Sender
    let title: String?
    let bullets: [String]

    static let seed: [ChatItem] = [
        ChatItem(
            text: NSLocalizedString("chat.welcome_message", comment: ""),
            sender: .ai,
            title: nil,
            bullets: []
        )
    ]
}

private struct ChatRow: View {
    let item: ChatItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if item.sender == .ai {
                botAvatar
            } else {
                Spacer(minLength: 0)
            }

            bubble
                .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: item.sender == .ai ? .leading : .trailing)

            if item.sender == .user {
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: item.sender == .ai ? .leading : .trailing)
    }

    private var botAvatar: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [Color(hex: "FF4D85"), Color(hex: "FF88A8")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 32, height: 32)
            .overlay(
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            )
            .shadow(color: Color(hex: "FF4D85").opacity(0.25), radius: 8, y: 4)
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 10) {
            if item.sender == .ai {
                FormattedMessageView(text: item.text)
            } else {
                Text(item.text)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "2D2422"))
                    .lineSpacing(4)
            }

            if let title = item.title {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "FF4D85"))
            }

            if !item.bullets.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(item.bullets, id: \.self) { bullet in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "845400"))
                                .padding(.top, 2)
                            Text(bullet)
                                .font(.system(size: 14))
                                .foregroundStyle(Color(hex: "2D2422"))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(item.sender == .ai ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color(hex: "FF4D85").opacity(0.10)))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: item.sender == .ai ? 2 : 48,
                bottomLeadingRadius: 48,
                bottomTrailingRadius: 48,
                topTrailingRadius: item.sender == .ai ? 48 : 2,
                style: .continuous
            )
        )
        .overlay {
            UnevenRoundedRectangle(
                topLeadingRadius: item.sender == .ai ? 2 : 48,
                bottomLeadingRadius: 48,
                bottomTrailingRadius: 48,
                topTrailingRadius: item.sender == .ai ? 48 : 2,
                style: .continuous
            )
            .stroke(item.sender == .ai ? Color(hex: "E9E2D0").opacity(0.6) : .clear, lineWidth: 1)
        }
        .shadow(color: .black.opacity(item.sender == .ai ? 0.06 : 0.03), radius: 12, y: 6)
    }
}

private struct FormattedMessageView: View {
    let text: String

    var body: some View {
        let lines = text.components(separatedBy: "\n")
        VStack(alignment: .leading, spacing: 6) {
            ForEach(0..<lines.count, id: \.self) { index in
                formatLine(lines[index])
            }
        }
    }

    @ViewBuilder
    private func formatLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("* ") || trimmed.hasPrefix("- ") {
            let content = String(trimmed.dropFirst(2))
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "845400"))
                    .padding(.top, 2)
                inlineFormattedText(content)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        } else {
            inlineFormattedText(trimmed)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func inlineFormattedText(_ input: String) -> Text {
        var result = Text("")
        var remaining = input

        while !remaining.isEmpty {
            if let boldRange = remaining.range(of: "**") {
                let before = String(remaining[..<boldRange.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "2D2422"))
                }

                let afterBoldStart = String(remaining[boldRange.upperBound...])
                if let endBoldRange = afterBoldStart.range(of: "**") {
                    let boldContent = String(afterBoldStart[..<endBoldRange.lowerBound])
                    result = result + Text(boldContent)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color(hex: "FF4D85"))
                    remaining = String(afterBoldStart[endBoldRange.upperBound...])
                } else {
                    result = result + Text(remaining)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "2D2422"))
                    remaining = ""
                }
            } else if let underlineRange = remaining.range(of: "*") {
                let before = String(remaining[..<underlineRange.lowerBound])
                if !before.isEmpty {
                    result = result + Text(before)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "2D2422"))
                }

                let afterUnderlineStart = String(remaining[underlineRange.upperBound...])
                if let endUnderlineRange = afterUnderlineStart.range(of: "*") {
                    let underlineContent = String(afterUnderlineStart[..<endUnderlineRange.lowerBound])
                    result = result + Text(underlineContent)
                        .font(.system(size: 14))
                        .underline()
                        .foregroundStyle(Color(hex: "2D2422"))
                    remaining = String(afterUnderlineStart[endUnderlineRange.upperBound...])
                } else {
                    result = result + Text(remaining)
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "2D2422"))
                    remaining = ""
                }
            } else {
                result = result + Text(remaining)
                    .font(.system(size: 14))
                    .foregroundStyle(Color(hex: "2D2422"))
                remaining = ""
            }
        }

        return result
    }
}

#Preview {
    ChatEditView()
        .environmentObject(EntitlementManager())
}
