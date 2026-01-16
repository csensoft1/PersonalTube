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
    private let youtubeReadOnlyScope = "https://www.googleapis.com/auth/youtube.readonly"

    func bootstrap() async {
        // Try restore silently
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                guard let self else { continuation.resume(); return }
                if let _ = error {
                    self.state = .signedOut
                    continuation.resume()
                    return
                }
                self.state = (user != nil) ? .signedIn : .signedOut
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
                return
            }
            self.state = (result?.user != nil) ? .signedIn : .signedOut
            YouTubeAPI.shared.accessTokenProvider = { [weak self] in
                self?.accessToken()   // your existing method that returns tokenString
            }

        }
    }

    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        state = .signedOut
    }

    func disconnect() {
        // Revokes the granted scopes on Google side
        GIDSignIn.sharedInstance.disconnect { [weak self] _ in
            self?.state = .signedOut
        }
    }

    func accessToken() -> String? {
        GIDSignIn.sharedInstance.currentUser?.accessToken.tokenString
    }
}


