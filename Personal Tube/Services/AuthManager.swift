//
//  Untitled.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//
import Foundation
import Combine
import GoogleSignIn

@MainActor
final class AuthManager: ObservableObject {
    enum State: Equatable { case checking, signedOut, signedIn, error(String) }
    @Published private(set) var state: State = .checking

    // Keep it minimal
    let youtubeReadOnlyScope = "https://www.googleapis.com/auth/youtube.readonly"

    func bootstrap() async {
        // Try restore silently
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard let self else { continuation.resume(); return }
                if let _ = error {
                    self.state = .signedOut
                    YouTubeAPI.shared.accessTokenProvider = { nil }
                    continuation.resume()
                    return
                }
                if let _ = user {
                    self.state = .signedIn
                    YouTubeAPI.shared.accessTokenProvider = { [weak self] in
                        self?.accessToken()
                    }
                } else {
                    self.state = .signedOut
                    YouTubeAPI.shared.accessTokenProvider = { nil }
                }
                continuation.resume()
            }
        }
    }

    func signIn(presentingVC: UIViewController) {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
            state = .error("Missing GIDClientID in Info.plist")
            return
        }

        // Configure the client ID for the shared instance
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

        // New API: signIn(withPresenting:hint:additionalScopes:)
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC, hint: nil, additionalScopes: [youtubeReadOnlyScope]) { [weak self] result, error in
            guard let self else { return }
            if let error = error {
                self.state = .error(error.localizedDescription)
                YouTubeAPI.shared.accessTokenProvider = { nil }
                return
            }
            if result?.user != nil {
                self.state = .signedIn
                YouTubeAPI.shared.accessTokenProvider = { [weak self] in
                    self?.accessToken()
                }
            } else {
                self.state = .signedOut
                YouTubeAPI.shared.accessTokenProvider = { nil }
            }
        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        state = .signedOut
        YouTubeAPI.shared.accessTokenProvider = { nil }
    }

    func disconnect() {
        // Revokes the granted scopes on Google side
        GIDSignIn.sharedInstance.disconnect { [weak self] _ in
            self?.state = .signedOut
            YouTubeAPI.shared.accessTokenProvider = { nil }
        }
    }

    func accessToken() -> String? {
        GIDSignIn.sharedInstance.currentUser?.accessToken.tokenString
    }
}

extension AuthManager {
    /// Ensures a valid access token exists before running an async operation.
    /// If no token is available, attempts Google Sign-In using the provided presentingVC.
    /// - Parameters:
    ///   - presentingVC: A UIViewController to present Google Sign-In if needed.
    ///   - operation: The async operation to run once signed in (or already signed in).
    @MainActor
    func runRequiringSignIn<T>(
        presentingVC: UIViewController?,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        // If we already have a token, run immediately.
        if let token = YouTubeAPI.shared.accessTokenProvider?(), !token.isEmpty {
            return try await operation()
        }

        // Otherwise, try to sign in if we can present.
        guard let presentingVC else {
            throw NSError(domain: "Auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Sign-in required"])
        }
        // Bridge the callback-based sign-in to async.
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String else {
                continuation.resume(throwing: NSError(domain: "Auth", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing GIDClientID in Info.plist"]))
                return
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)

            GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingVC,
                hint: nil,
                additionalScopes: [youtubeReadOnlyScope]
            ) { [weak self] result, error in
                guard let self else {
                    continuation.resume(throwing: NSError(domain: "Auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Auth manager deallocated"]))
                    return
                }
                if let error = error {
                    self.state = .error(error.localizedDescription)
                    YouTubeAPI.shared.accessTokenProvider = { nil }
                    continuation.resume(throwing: error)
                    return
                }
                if result?.user != nil {
                    self.state = .signedIn
                    YouTubeAPI.shared.accessTokenProvider = { [weak self] in
                        self?.accessToken()
                    }
                    continuation.resume()
                } else {
                    self.state = .signedOut
                    YouTubeAPI.shared.accessTokenProvider = { nil }
                    continuation.resume(throwing: NSError(domain: "Auth", code: 3, userInfo: [NSLocalizedDescriptionKey: "User cancelled sign-in"]))
                }
            }
        }

        // After successful sign-in, run the operation.
        return try await operation()
    }
}

