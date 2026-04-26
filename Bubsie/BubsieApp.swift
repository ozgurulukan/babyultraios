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
        let t0 = CFAbsoluteTimeGetCurrent()
        if selectedLanguage.isEmpty {
            selectedLanguage = deviceLanguage()
        }
        applyLanguage()
        let t1 = CFAbsoluteTimeGetCurrent()
        print("[LaunchTime] LanguageManager init: \(String(format: "%.3f", (t1 - t0) * 1000)) ms")
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
        UserDefaults.standard.synchronize()
    }
}

@main
struct BubsieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var subscriptionManager: SubscriptionsManager
    @StateObject private var languageManager = LanguageManager.shared

    init() {
        let t0 = CFAbsoluteTimeGetCurrent()

        // Configure RevenueCat early, before any @StateObject init accesses Purchases.shared
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: REVENUECAT_API_KEY)
        let t1 = CFAbsoluteTimeGetCurrent()
        print("[LaunchTime] RevenueCat.configure: \(String(format: "%.3f", (t1 - t0) * 1000)) ms")

        let em = EntitlementManager()
        let t2 = CFAbsoluteTimeGetCurrent()
        print("[LaunchTime] EntitlementManager init: \(String(format: "%.3f", (t2 - t1) * 1000)) ms")

        let sm = SubscriptionsManager(entitlementManager: em)
        let t3 = CFAbsoluteTimeGetCurrent()
        print("[LaunchTime] SubscriptionsManager init: \(String(format: "%.3f", (t3 - t2) * 1000)) ms")

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
        let t0 = CFAbsoluteTimeGetCurrent()
        FirebaseApp.configure()
        let t1 = CFAbsoluteTimeGetCurrent()
        print("[LaunchTime] FirebaseApp.configure: \(String(format: "%.3f", (t1 - t0) * 1000)) ms")

        // Sync Firebase UID with RevenueCat
        if let user = Auth.auth().currentUser {
            Task {
                _ = try? await Purchases.shared.logIn(user.uid)
            }
        }

        AuthManager.shared.startListening()
        let t2 = CFAbsoluteTimeGetCurrent()
        print("[LaunchTime] AuthManager.startListening: \(String(format: "%.3f", (t2 - t1) * 1000)) ms")

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

        let t3 = CFAbsoluteTimeGetCurrent()
        print("[LaunchTime] AppDelegate total: \(String(format: "%.3f", (t3 - t0) * 1000)) ms")
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
