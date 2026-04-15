import SwiftUI

// Deprecated: Header is now inlined into each view.
// Kept as a thin wrapper to avoid breaking any remaining references.
struct Header: View {
    @Binding var isTapped: Bool

    var body: some View {
        HStack {
            Text("Luris")
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Luris.accent)
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
