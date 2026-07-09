import Foundation
import AppTrackingTransparency
import AdSupport
import FacebookCore

@MainActor
public final class TrackingManager: ObservableObject {
    public static let shared = TrackingManager()
    
    @Published public var authorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    private init() {
        self.authorizationStatus = ATTrackingManager.trackingAuthorizationStatus
    }
    
    /// Requests App Tracking Transparency authorization and updates Meta SDK settings.
    public func requestTrackingPermission() async -> ATTrackingManager.AuthorizationStatus {
        let status = await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        self.authorizationStatus = status
        self.applyTrackingSettings(for: status)
        return status
    }
    
    /// Re-applies tracking status settings (e.g. on application launch or status change).
    public func applyCurrentTrackingSettings() {
        let status = ATTrackingManager.trackingAuthorizationStatus
        self.authorizationStatus = status
        self.applyTrackingSettings(for: status)
    }
    
    private func applyTrackingSettings(for status: ATTrackingManager.AuthorizationStatus) {
        let isAuthorized = (status == .authorized)
        print("[TrackingManager] Applying tracking settings. Authorized: \(isAuthorized)")
        
        // Manual property sync is only necessary for iOS versions below 17.0.
        // Starting with iOS 17.0+, the Meta SDK automatically queries Apple's ATTrackingManager.
        if #unavailable(iOS 17) {
            Settings.shared.isAdvertiserTrackingEnabled = isAuthorized
            print("[TrackingManager] Manual ATE flag set to \(isAuthorized) (iOS < 17)")
        } else {
            print("[TrackingManager] Meta SDK handles ATE automatically on iOS 17+")
        }
        
        // Align auto logging and advertiser ID collection settings with the tracking consent status
        Settings.shared.isAutoLogAppEventsEnabled = isAuthorized
        Settings.shared.isAdvertiserIDCollectionEnabled = isAuthorized
    }
}
