import SwiftUI

struct ChatEditView: View {
    @State private var inputText = ""
    @State private var chatItems: [ChatItem] = ChatItem.seed

    var body: some View {
        ZStack {
            chatBackground.ignoresSafeArea()

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
                    timestampPill

                    ForEach(chatItems) { item in
                        ChatRow(item: item)
                    }

                    tipCard
                    suggestionChips
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
                        colors: [Color(hex: "FFF9EC").opacity(0.0), Color(hex: "FFF9EC").opacity(0.92), Color(hex: "FFF9EC")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
        }
    }

    private var chatBackground: some View {
        ZStack {
            Color(hex: "FFF9EC")
            RadialGradient(colors: [Color(hex: "F08C6E").opacity(0.12), .clear], center: .topLeading, startRadius: 10, endRadius: 260)
            RadialGradient(colors: [Color(hex: "FEB246").opacity(0.12), .clear], center: .topTrailing, startRadius: 10, endRadius: 260)
            RadialGradient(colors: [Color(hex: "97462E").opacity(0.08), .clear], center: .bottomTrailing, startRadius: 10, endRadius: 260)
            RadialGradient(colors: [Color(hex: "FB856D").opacity(0.10), .clear], center: .bottomLeading, startRadius: 10, endRadius: 260)
        }
    }

    private var headerBar: some View {
        ProfileStyleHeader(
            title: "BubsieAI",
            subtitle: "Ask Bubsie anything about your little one."
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var timestampPill: some View {
        HStack {
            Spacer()
            Text("Today, 10:42 AM")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color(hex: "55433E"))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color(hex: "FAF3E0")))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
            Spacer()
        }
    }

    private var tipCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.max.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(hex: "FEB246"))
                .frame(width: 24, height: 24)

            Text("Remember, this is temporary!\nYou're doing a great job.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color(hex: "55433E"))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(hex: "FAF3E0")))
    }

    private var suggestionChips: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                suggestionChip("How long does it last?")
                suggestionChip("Should I feed her?")
            }
            suggestionChip("Create sleep schedule")
        }
    }

    private func suggestionChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color(hex: "55433E"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(hex: "FAF3E0")))
            .overlay(Capsule().stroke(Color(hex: "E9E2D0").opacity(0.3), lineWidth: 1))
            .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            CircleButton(icon: "photo.badge.plus")

            TextField("Ask Bubsie anything about Emma...", text: $inputText)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "1E1C10"))
                .tint(Color(hex: "97462E"))

            Button {
                sendMessage()
            } label: {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "97462E"), Color(hex: "F08C6E")],
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
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1)
        }
        .padding(8)
        .background(
            Capsule()
                .fill(.white)
                .overlay(Capsule().stroke(Color(hex: "E9E2D0").opacity(0.35), lineWidth: 1))
                .shadow(color: .black.opacity(0.08), radius: 12, y: 6)
        )
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        chatItems.append(ChatItem(text: text, sender: .user, title: nil, bullets: []))
        inputText = ""
    }
}

private struct CircleButton: View {
    let icon: String

    var body: some View {
        Circle()
            .fill(Color.clear)
            .frame(width: 40, height: 40)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: "55433E"))
            )
    }
}

private enum Sender {
    case ai
    case user
}

private struct ChatItem: Identifiable {
    let id = UUID()
    let text: String
    let sender: Sender
    let title: String?
    let bullets: [String]

    static let seed: [ChatItem] = [
        ChatItem(
            text: "Hi there! I'm Bubsie, your Parent Assistant. How is your little one doing today? I'm here to help with sleep schedules, feeding questions, or just to offer a listening ear.",
            sender: .ai,
            title: nil,
            bullets: []
        ),
        ChatItem(
            text: "Emma has been waking up every 2 hours at night recently. She's 4 months old. Is this the sleep regression everyone talks about?",
            sender: .user,
            title: nil,
            bullets: []
        ),
        ChatItem(
            text: "It sounds very likely! The 4-month mark is a classic time for a sleep progression (often called a regression). Emma's sleep cycles are maturing and becoming more like an adult's.",
            sender: .ai,
            title: "Here are a few gentle things you can try:",
            bullets: [
                "Consistent Bedtime Routine: A bath, book, and soothing song can signal it's time to wind down.",
                "Dark Environment: Ensure her room is very dark to encourage melatonin production.",
                "Practice Independent Sleep: Try putting her down awake but drowsy when possible."
            ]
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
                .frame(maxWidth: UIScreen.main.bounds.width * 0.82, alignment: item.sender == .ai ? .leading : .trailing)

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
                    colors: [Color(hex: "97462E"), Color(hex: "F08C6E")],
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
            .shadow(color: Color(hex: "97462E").opacity(0.25), radius: 8, y: 4)
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.text)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "1E1C10"))
                .lineSpacing(4)

            if let title = item.title {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "97462E"))
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
                                .foregroundStyle(Color(hex: "1E1C10"))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(item.sender == .ai ? AnyShapeStyle(Color.white) : AnyShapeStyle(Color(hex: "97462E").opacity(0.10)))
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

#Preview {
    ChatEditView()
}
