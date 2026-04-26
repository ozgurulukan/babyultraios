import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications
import Combine
import RevenueCat
import ObjectiveC

// MARK: - Runtime Language Switching via Bundle Swizzling
private var associatedBundleKey: UInt8 = 0

class LocalizedBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let bundle = objc_getAssociatedObject(self, &associatedBundleKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return bundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    static func setLanguage(_ language: String) {
        object_setClass(Bundle.main, LocalizedBundle.self)
        if let path = Bundle.main.path(forResource: language, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            objc_setAssociatedObject(Bundle.main, &associatedBundleKey, bundle, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

@MainActor
final class LanguageManager: ObservableObject {
    static let shared = LanguageManager()

    @AppStorage("appLanguage") var selectedLanguage: String = "" {
        didSet {
            applyLanguage()
        }
    }

    @Published var currentLocale: Locale = Locale(identifier: "en")

    let supportedLanguages = [
        "en", "tr", "es", "fr", "de", "it", "pt", "ru",
        "ja", "ko", "zh", "ar", "da", "fi", "el", "nl",
        "sv", "nb", "ga", "th"
    ]

    private init() {
        if selectedLanguage.isEmpty {
            selectedLanguage = deviceLanguage()
        }
        applyLanguage()
    }

    func deviceLanguage() -> String {
        let preferred = Locale.preferredLanguages.first ?? "en"
        let code = Locale(identifier: preferred).language.languageCode?.identifier ?? "en"
        if supportedLanguages.contains(code) {
            return code
        }
        return "en"
    }

    private func applyLanguage() {
        currentLocale = Locale(identifier: selectedLanguage)
        Bundle.setLanguage(selectedLanguage)
        UserDefaults.standard.set([selectedLanguage], forKey: "AppleLanguages")
    }
}

@main
struct BubsieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var subscriptionManager: SubscriptionsManager
    @StateObject private var languageManager = LanguageManager.shared

    init() {
        // Configure RevenueCat early, before any @StateObject init accesses Purchases.shared.
        // Debug logging is disabled for launch speed; re-enable temporarily if debugging purchases.
        Purchases.configure(withAPIKey: REVENUECAT_API_KEY)

        let em = EntitlementManager()
        let sm = SubscriptionsManager(entitlementManager: em)
        self._entitlementManager = StateObject(wrappedValue: em)
        self._subscriptionManager = StateObject(wrappedValue: sm)
    }

    var body: some Scene {
        WindowGroup {
            Splash()
                .id(languageManager.currentLocale.identifier)
                .environmentObject(entitlementManager)
                .environmentObject(subscriptionManager)
                .environmentObject(languageManager)
                .environment(\.locale, languageManager.currentLocale)
                .task { await subscriptionManager.updatePurchasedProducts() }
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    private var cancellables = Set<AnyCancellable>()
    private var pendingFCMToken: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()

        // Sync Firebase UID with RevenueCat
        if let user = Auth.auth().currentUser {
            Task {
                _ = try? await Purchases.shared.logIn(user.uid)
            }
        }

        AuthManager.shared.startListening()

        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        DispatchQueue.main.async { application.registerForRemoteNotifications() }

        // Observe auth token changes and flush any pending FCM token
        AuthManager.shared.$idToken
            .dropFirst()
            .sink { [weak self] _ in
                guard let self, let token = self.pendingFCMToken else { return }
                self.pendingFCMToken = nil
                Task { await self.registerDeviceToken(token) }
            }
            .store(in: &cancellables)

        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        if AuthManager.shared.idToken != nil {
            Task { await registerDeviceToken(token) }
        } else {
            pendingFCMToken = token
        }
    }

    private func registerDeviceToken(_ token: String) async {
        do {
            print("[FCM] Registering device token: \(token.prefix(20))...")
            try await BubsieAPI.shared.registerDeviceToken(token)
            print("[FCM] Device token registered successfully")
        } catch {
            print("[FCM] Failed to register device token: \(error)")
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let data = response.notification.request.content.userInfo
        if let link = data["deep_link"] as? String, let url = URL(string: link) {
            UIApplication.shared.open(url)
        }
        completionHandler()
    }
}
