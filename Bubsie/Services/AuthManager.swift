import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseCore
import os

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private let logger = Logger(subsystem: "com.bubsie", category: "Auth")
    private init() {
        idToken = UserDefaults.standard.string(forKey: "bubsie_id_token")
    }

    @Published var idToken: String? {
        didSet {
            UserDefaults.standard.set(idToken, forKey: "bubsie_id_token")
            logger.info("idToken \(self.idToken != nil ? "SET" : "NIL")")
        }
    }
    @Published var currentUser: UserProfile?
    @Published var isLoadingUser = false
    @Published var isAuthenticating = false
    @Published var authError: String?

    var isAuthenticated: Bool { Auth.auth().currentUser != nil }

    private var isSigningIn = false

    func startListening() {
        logger.info("startListening. currentUser=\(String(describing: Auth.auth().currentUser?.uid))")
        if Auth.auth().currentUser != nil {
            refreshToken()
        } else {
            signInAnonymously()
        }
    }

    func signInAnonymously() {
        guard !isSigningIn else {
            logger.info("Already signing in, skipping")
            return
        }
        isSigningIn = true
        isAuthenticating = true
        authError = nil
        logger.info("Starting anonymous sign-in…")

        Task {
            do {
                let result = try await Auth.auth().signInAnonymously()
                logger.info("Anonymous sign-in OK: \(result.user.uid)")
                let token = try await result.user.getIDToken()
                self.idToken = token
                logger.info("Token obtained, length: \(token.count)")
                await self.fetchProfile()
            } catch {
                self.logger.error("Anonymous sign-in FAILED: \(error)")
                self.authError = "Sign-in failed: \(error.localizedDescription)"
                self.isSigningIn = false
                self.isAuthenticating = false
            }
        }
    }

    func signOut() {
        idToken = nil
        currentUser = nil
        do {
            try Auth.auth().signOut()
        } catch {
            logger.error("Sign out error: \(error)")
        }
    }

    private func refreshToken() {
        guard let user = Auth.auth().currentUser else { return }
        Task {
            do {
                let token = try await user.getIDToken()
                self.idToken = token
                logger.info("Token refreshed, length: \(token.count)")
                await self.fetchProfile()
            } catch {
                self.logger.error("Token refresh FAILED: \(error)")
            }
        }
    }

    func fetchProfile() async {
        guard idToken != nil else {
            logger.warning("fetchProfile: no idToken")
            return
        }
        guard !isLoadingUser else {
            logger.info("fetchProfile: already loading")
            return
        }
        isLoadingUser = true
        defer { isLoadingUser = false; isSigningIn = false; isAuthenticating = false }
        do {
            let profile = try await BubsieAPI.shared.getProfile()
            currentUser = profile
            logger.info("Profile OK: uid=\(profile.uid) credits=\(profile.credits) isPro=\(profile.isPro)")
        } catch let error as APIError {
            self.logger.error("Profile fetch API error: \(error.localizedDescription)")
            self.authError = error.localizedDescription
            if case .unauthorized = error {
                if let user = Auth.auth().currentUser {
                    do {
                        let token = try await user.getIDToken()
                        self.idToken = token
                        let profile = try await BubsieAPI.shared.getProfile()
                        currentUser = profile
                        logger.info("Profile OK after token refresh")
                    } catch {
                        self.logger.error("Profile still failing after refresh: \(error)")
                    }
                }
            }
        } catch {
            self.logger.error("Profile fetch error: \(error)")
            self.authError = error.localizedDescription
        }
    }
}