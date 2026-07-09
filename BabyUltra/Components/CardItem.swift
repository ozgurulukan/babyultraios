import SwiftUI

// Generic list row used in settings/menu
struct CardItem: View {
    var icon: String
    var text: String
    var iconColor: Color = BabyUltra.textSecondary

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(iconColor)
            }
            Text(LocalizedStringKey(text))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(BabyUltra.textSecondary)
        }
        .frame(height: 54)
        .padding(.horizontal, 14)
    }
}
