import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import UserNotifications
import Combine

@main
struct BubsieApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var entitlementManager: EntitlementManager
    @StateObject private var subscriptionManager: SubscriptionsManager

    init() {
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

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    private var cancellables = Set<AnyCancellable>()
    private var pendingFCMToken: String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
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
