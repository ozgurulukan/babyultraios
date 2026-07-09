import SwiftUI
import Combine

@MainActor
final class ChatEditViewModel: ObservableObject {
    static let shared = ChatEditViewModel()
    @Published var inputText = ""
    @Published var chatItems: [ChatItem] = ChatItem.seed
    @Published var isLoading = false

    let suggestions = [
        "How do I start sleep training?",
        "What should my 6-month-old eat?",
        "Tips for toddler tantrums?"
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
                text: "Hi there! I'm BabyUltraAI, your Parent Assistant. How is your little one doing today? I'm here to help with sleep schedules, feeding questions, or just to offer a listening ear.",
                sender: .ai,
                title: nil,
                bullets: []
            )
        ]
    }
}
