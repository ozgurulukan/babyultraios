import SwiftUI
import VariableBlur

// Deprecated: Header is now inlined into each view.
// Kept as a thin wrapper to avoid breaking any remaining references.
struct Header: View {
    @Binding var isTapped: Bool

    var body: some View {
        HStack {
            Text("Bubsie")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Bubsie.accent)
            Spacer()
            Button {
                withAnimation { isTapped.toggle() }
            } label: {
                Image(systemName: isTapped ? "xmark" : "line.3.horizontal")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .contentTransition(.symbolEffect(.replace))
            }
        }
        .frame(height: 56)
        .padding(.horizontal, 20)
    }
}

struct ProfileStyleHeader: View {
    let title: String
    let subtitle: String
    var spacing: CGFloat = 4

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "1E1C10"))
            Text(subtitle)
                .font(.system(size: 16))
                .foregroundStyle(Color(hex: "55433E"))
                .lineLimit(1)
        }
    }
}

private struct HeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Walks up the view hierarchy to find the enclosing UIScrollView and disables
/// `delaysContentTouches` so buttons inside the SwiftUI ScrollView respond immediately.
private struct ScrollViewDelayFixer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            var current: UIView? = view
            while let superview = current?.superview {
                if let scrollView = superview as? UIScrollView {
                    scrollView.delaysContentTouches = false
                    break
                }
                current = superview
            }
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}

struct StickyBlurHeader<Header: View, Content: View>: View {
    private let fadeExtension: CGFloat
    private let tintOpacityTop: Double
    private let tintOpacityMiddle: Double
    private let maxBlurRadius: CGFloat
    private let header: () -> Header
    private let content: () -> Content

    @State private var headerHeight: CGFloat = 76
    @Environment(\.colorScheme) private var colorScheme

    init(
        maxBlurRadius: CGFloat = 5,
        fadeExtension: CGFloat = 64,
        tintOpacityTop: Double = 0.7,
        tintOpacityMiddle: Double = 0.5,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.maxBlurRadius = maxBlurRadius
        self.fadeExtension = fadeExtension
        self.tintOpacityTop = tintOpacityTop
        self.tintOpacityMiddle = tintOpacityMiddle
        self.header = header
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                content()
                ScrollViewDelayFixer()
                    .frame(height: 0)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                Color.clear.frame(height: headerHeight)
            }

            let totalHeight = headerHeight + fadeExtension
            VariableBlurView(
                maxBlurRadius: maxBlurRadius,
                direction: .blurredTopClearBottom
            )
                .overlay {
                    LinearGradient(
                        stops: [
                            .init(color: fadeTint.opacity(tintOpacityTop), location: 0),
                            .init(color: fadeTint.opacity(tintOpacityMiddle), location: 90 / totalHeight),
                            .init(color: fadeTint.opacity(0), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
                .frame(height: totalHeight)
                .ignoresSafeArea(edges: .top)
                .allowsHitTesting(false)

            header()
                .frame(height: headerHeight)
                .overlay {
                    GeometryReader { geo in
                        Color.clear.preference(key: HeaderHeightKey.self, value: geo.size.height)
                    }
                }
        }
        .onPreferenceChange(HeaderHeightKey.self) { newValue in
            if abs(newValue - headerHeight) > 1 {
                headerHeight = newValue
            }
        }
    }

    private var fadeTint: Color {
        colorScheme == .dark ? .black : .white
    }
}
