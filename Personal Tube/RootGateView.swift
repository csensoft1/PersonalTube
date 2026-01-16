//
//  RootGateView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct RootGateView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        switch auth.state {
        case .checking:
            ProgressView("Signing in…")
                .task { await auth.bootstrap() }

        case .signedOut:
            LoginView()

        case .signedIn:
            MainAppView()

        case .error(let msg):
            VStack(spacing: 12) {
                Text("Login error")
                Text(msg).font(.footnote).foregroundStyle(.secondary)
                Button("Try again") { Task { await auth.bootstrap() } }
            }.padding()
        }
    }
}

