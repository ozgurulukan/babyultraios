import SwiftUI

// Inline premium upgrade banner used where needed
struct PremiumCard: View {
    @State private var isPremiumShow = false

    var body: some View {
        Button { isPremiumShow = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Luris.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Premium")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Unlock unlimited AI generation")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Luris.textSecondary)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Luris.accent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                LinearGradient(
                    colors: [Color(hex: "0D1A00"), Color(hex: "1E3800")],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Luris.accent.opacity(0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPremiumShow) { PremiumView() }
    }
}

#Preview {
    PremiumCard()
        .padding()
        .background(Color.black)
        .environmentObject(EntitlementManager())
        .environmentObject(SubscriptionsManager(entitlementManager: EntitlementManager()))
}
