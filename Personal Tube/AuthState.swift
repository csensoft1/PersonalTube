//
//  AuthState.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

enum AuthState: Equatable {
    case checking        // app launch, verifying stored session
    case signedOut
    case signedIn
    case error(String)
}
