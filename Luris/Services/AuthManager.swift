import Foundation
import SwiftUI

// MARK: - Firebase Project Constants (from GoogleService-Info.plist)
// Bundle ID:    com.fagore.luris
// Project ID:   aiappbackend
// GCM Sender:   303104966117
// Google App:   1:303104966117:ios:c8909f390b734a4f55c30c
//
// To enable Firebase Auth:
// 1. Add Firebase iOS SDK via SPM: https://github.com/firebase/firebase-ios-sdk
//    — Add packages: FirebaseAuth, FirebaseCore
// 2. Uncomment `FirebaseApp.configure()` in LurisApp.swift
// 3. After sign-in, call: AuthManager.shared.setIDToken(try await user.getIDToken())

/// Manages the Firebase ID token and authenticated user state.
/// Call `setIDToken(_:)` after a successful Firebase Auth sign-in.
@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private init() {
        idToken = UserDefaults.standard.string(forKey: "luris_id_token")
    }

    @Published var idToken: String? {
        didSet {
            UserDefaults.standard.set(idToken, forKey: "luris_id_token")
        }
    }

    @Published var currentUser: UserProfile?
    @Published var isLoadingUser = false

    var isAuthenticated: Bool { idToken != nil }

    // MARK: - Called by Firebase Auth sign-in
    func setIDToken(_ token: String) {
        idToken = token
        Task { await fetchProfile() }
    }

    func signOut() {
        idToken = nil
        currentUser = nil
    }

    // MARK: - Profile Fetch
    func fetchProfile() async {
        guard isAuthenticated else { return }
        isLoadingUser = true
        defer { isLoadingUser = false }
        do {
            let response: APIResponse<UserProfile> = try await APIClient.shared.get("/api/v1/me")
            if response.success, let profile = response.data {
                currentUser = profile
            }
        } catch {
            // Token may have expired — clear it so user is prompted to re-auth
            if case APIError.unauthorized = error {
                signOut()
            }
        }
    }
}
