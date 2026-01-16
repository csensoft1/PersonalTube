//
//  RootGateView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct RootGateView: View {
    @EnvironmentObject var auth: AuthManager
    @StateObject private var profileSession = ProfileSession()
    @State private var showProfilePicker = false
    
    var body: some View {
        switch auth.state {
        case .checking:
            ProgressView("Signing in…")
                .task { await auth.bootstrap() }

        case .signedOut:
            LoginView()

        case .signedIn:
            MainAppView()
                   .environmentObject(profileSession)
                   .onAppear {
                       // Show profile picker only if nothing selected yet
                       if profileSession.selectedProfileId.isEmpty {
                           showProfilePicker = true
                       }
                   }
                   .sheet(isPresented: $showProfilePicker) {
                       SelectProfilesSheet { selected in
                           profileSession.selectedProfileId = selected.id
                           showProfilePicker = false
                       }
                       // Optional: prevent swipe-to-dismiss until profile chosen
                       .interactiveDismissDisabled(profileSession.selectedProfileId.isEmpty)
                   }

           case .error(let message):
               VStack(spacing: 12) {
                   Text("Something went wrong")
                   Text(message).font(.footnote).foregroundStyle(.secondary)
                   Button("Try again") { Task { await auth.bootstrap() } }
               }
               .padding()
        case .error(let msg):
            VStack(spacing: 12) {
                Text("Login error")
                Text(msg).font(.footnote).foregroundStyle(.secondary)
                Button("Try again") { Task { await auth.bootstrap() } }
            }.padding()
        }
    }
}

