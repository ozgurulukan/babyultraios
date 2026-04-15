import SwiftUI

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
}

private let quickActions = ["Remove BG", "Upscale 4K", "Stylize", "Animate", "Restore"]

// MARK: - Chat Edit View
struct ChatEditView: View {
    @State private var messages: [ChatMessage] = [
        .init(content: "Hello! I'm Luris AI. Upload a photo or describe what you'd like to create or edit. What shall we make today?", isUser: false)
    ]
    @State private var inputText = ""
    @State private var isTyping = false
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            chatHeader
            quickActionPills
            Rectangle().fill(Color(hex: "1C1C2E")).frame(height: 0.5)
            messageList
            inputBar
        }
    }

    // MARK: Header (matches reference: menu icon left, Upgrade Pro center, action right)
    var chatHeader: some View {
        HStack {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            upgradePill

            Spacer()

            Button {
                withAnimation {
                    messages = [.init(content: "Hello! I'm Luris AI. Upload a photo or describe what you'd like to create or edit. What shall we make today?", isUser: false)]
                }
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(10)
                    .background(Luris.card)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.5))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    var upgradePill: some View {
        PremiumPill()
            .padding(.trailing, 8)
    }

    // MARK: Quick Actions
    var quickActionPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickActions, id: \.self) { action in
                    Button {
                        inputText = action
                    } label: {
                        Text(action)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Luris.card)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color(hex: "2A2A3E"), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 10)
    }

    // MARK: Messages
    var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(messages) { msg in
                        ChatBubble(message: msg)
                            .id(msg.id)
                    }
                    if isTyping { TypingIndicator() }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .onChange(of: messages.count) { _, _ in
                if let last = messages.last {
                    withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }
            .onChange(of: isTyping) { _, _ in
                withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
            }
        }
    }

    // MARK: Input Bar (matches reference: dark bar with + settings, text field, mic/send)
    var inputBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.white.opacity(0.04)).frame(height: 0.5)

            HStack(spacing: 10) {
                // Left icons
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                }

                // Text input with subtle gradient border when active
                HStack {
                    TextField("The future of AI i", text: $inputText, axis: .vertical)
                        .font(.system(size: 15))
                        .foregroundStyle(.white)
                        .tint(Luris.accent)
                        .lineLimit(1...4)
                        .focused($isFocused)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Luris.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isFocused
                                ? Luris.accentGradient
                                : LinearGradient(colors: [Color.white.opacity(0.06)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: isFocused ? 1.5 : 0.5
                        )
                )

                // Send / mic button
                Button { sendMessage() } label: {
                    Image(systemName: inputText.isEmpty ? "mic" : "arrow.up")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(inputText.isEmpty ? Luris.textSecondary : .white)
                        .frame(width: 34, height: 34)
                        .background(inputText.isEmpty ? Luris.surface : Luris.accent)
                        .clipShape(Circle())
                }
                .disabled(inputText.isEmpty)
                .animation(.spring(response: 0.2), value: inputText.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Luris.bg.opacity(0.96))
        }
    }

    func sendMessage() {
        guard !inputText.isEmpty else { return }
        let userMsg = ChatMessage(content: inputText, isUser: true)
        messages.append(userMsg)
        inputText = ""
        isFocused = false
        isTyping = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            isTyping = false
            let response = ChatMessage(
                content: "Got it! I can process that for you. To get started, upload an image or I can generate one from your description.",
                isUser: false
            )
            messages.append(response)
        }
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !message.isUser {
                AvatarView()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(message.isUser
                        ? AnyShapeStyle(Luris.accentGradient.opacity(0.25))
                        : AnyShapeStyle(Color(hex: "1A1A2E"))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                message.isUser ? Luris.accent.opacity(0.3) : Color(hex: "2A2A3E"),
                                lineWidth: 0.5
                            )
                    )

                if !message.isUser {
                    HStack(spacing: 16) {
                        ForEach(["hand.thumbsup", "hand.thumbsdown", "doc.on.doc", "ellipsis"], id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Luris.textSecondary)
                        }
                    }
                    .padding(.leading, 4)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.78, alignment: message.isUser ? .trailing : .leading)

            if message.isUser {
                Image(systemName: "person.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Luris.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(Luris.surface)
                    .clipShape(Circle())
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            AvatarView()
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(Luris.textSecondary)
                        .frame(width: 6, height: 6)
                        .offset(y: animate ? -5 : 0)
                        .animation(
                            .easeInOut(duration: 0.55).repeatForever().delay(Double(i) * 0.15),
                            value: animate
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "1A1A2E"))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            Spacer()
        }
        .id("typing")
        .onAppear { animate = true }
    }
}

// MARK: - Avatar
struct AvatarView: View {
    var body: some View {
        ZStack {
            Circle().fill(Luris.accentGradient).frame(width: 30, height: 30)
                .shadow(color: Luris.accent.opacity(0.4), radius: 8)
            Text("L").font(.system(size: 12, weight: .black)).foregroundStyle(.white)
        }
    }
}

#Preview {
    ChatEditView()
}
