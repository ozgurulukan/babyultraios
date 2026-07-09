import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseCore
import RevenueCat
import os

@MainActor
final class AuthManager: ObservableObject {
    static let shared = AuthManager()
    private let logger = Logger(subsystem: "com.babyultra", category: "Auth")
    private init() {
        idToken = UserDefaults.standard.string(forKey: "babyultra_id_token")
    }

    @Published var idToken: String? {
        didSet {
            UserDefaults.standard.set(idToken, forKey: "babyultra_id_token")
            logger.info("idToken \(self.idToken != nil ? "SET" : "NIL")")
        }
    }
    @Published var currentUser: UserProfile?
    @Published var isLoadingUser = false
    @Published var isAuthenticating = false
    @Published var authError: String?
    @Published var isDeviceBanned = false

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
        isDeviceBanned = false
        logger.info("Starting anonymous sign-in…")

        Task {
            do {
                let result = try await Auth.auth().signInAnonymously()
                logger.info("Anonymous sign-in OK: \(result.user.uid)")
                let token = try await result.user.getIDToken()
                self.idToken = token
                logger.info("Token obtained, length: \(token.count)")
                await self.fetchProfile()
                await self.syncRevenueCatUserID()
            } catch let error as APIError {
                self.logger.error("Anonymous sign-in API error: \(error.localizedDescription)")
                self.handleAPIError(error)
                self.isSigningIn = false
                self.isAuthenticating = false
            } catch {
                self.logger.error("Anonymous sign-in FAILED: \(error)")
                self.authError = "Sign-in failed: \(error.localizedDescription)"
                self.isSigningIn = false
                self.isAuthenticating = false
            }
        }
    }

    private func handleAPIError(_ error: APIError) {
        if case .forbidden = error {
            let msg = error.localizedDescription.lowercased()
            if msg.contains("device") {
                self.isDeviceBanned = true
                self.authError = nil
                return
            }
        }
        self.authError = error.localizedDescription
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

    private func syncRevenueCatUserID() async {
        guard let user = Auth.auth().currentUser else { return }
        do {
            _ = try await Purchases.shared.logIn(user.uid)
            logger.info("RevenueCat logIn OK for uid=\(user.uid)")
        } catch {
            logger.error("RevenueCat logIn failed: \(error)")
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
                await self.syncRevenueCatUserID()
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
            let profile = try await BabyUltraAPI.shared.getProfile()
            currentUser = profile
            logger.info("Profile OK: uid=\(profile.uid) credits=\(profile.credits) isPro=\(profile.isPro)")
        } catch let error as APIError {
            self.logger.error("Profile fetch API error: \(error.localizedDescription)")
            self.handleAPIError(error)
            if case .unauthorized = error {
                if let user = Auth.auth().currentUser {
                    do {
                        let token = try await user.getIDToken()
                        self.idToken = token
                        let profile = try await BabyUltraAPI.shared.getProfile()
                        self.currentUser = profile
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