import SwiftUI
import Combine

@MainActor
final class ChatEditViewModel: ObservableObject {
    static let shared = ChatEditViewModel()
    @Published var inputText = ""
    @Published var chatItems: [ChatItem] = ChatItem.seed
    @Published var isLoading = false

    let suggestions = [
        NSLocalizedString("chat.suggestion1", comment: ""),
        NSLocalizedString("chat.suggestion2", comment: ""),
        NSLocalizedString("chat.suggestion3", comment: "")
    ]

    func selectSuggestion(_ text: String) {
        inputText = text
    }

    func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        chatItems.append(ChatItem(text: text, sender: .user, title: nil, bullets: []))
        inputText = ""
        isLoading = true

        Task {
            do {
                let reply = try await BabyUltraAPI.shared.sendChatMessage(text)
                isLoading = false
                chatItems.append(ChatItem(text: reply, sender: .ai, title: nil, bullets: []))
            } catch {
                isLoading = false
                chatItems.append(ChatItem(
                    text: "Sorry, I'm having trouble connecting right now. Please try again in a moment.",
                    sender: .ai,
                    title: nil,
                    bullets: []
                ))
            }
        }
    }

    func clearChat() {
        chatItems = [
            ChatItem(
                text: NSLocalizedString("chat.welcome_message", comment: ""),
                sender: .ai,
                title: nil,
                bullets: []
            )
        ]
    }
}
