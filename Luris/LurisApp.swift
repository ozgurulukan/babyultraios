import SwiftUI
// import FirebaseCore  ← Uncomment after adding Firebase SDK via SPM

@main
struct LurisApp: App {

    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var subscriptionManager: SubscriptionsManager

    init() {
        // FirebaseApp.configure()  ← Uncomment after adding Firebase SDK via SPM
        // GoogleService-Info.plist is bundled in the project root — Firebase picks it up automatically.

        let em = EntitlementManager()
        let sm = SubscriptionsManager(entitlementManager: em)
        self._entitlementManager = StateObject(wrappedValue: em)
        self._subscriptionManager = StateObject(wrappedValue: sm)
    }

    var body: some Scene {
        WindowGroup {
            Splash()
                .preferredColorScheme(.dark)
                .environmentObject(entitlementManager)
                .environmentObject(subscriptionManager)
                .task { await subscriptionManager.updatePurchasedProducts() }
        }
    }
}
