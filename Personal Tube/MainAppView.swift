//
//  MainAppView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//
import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var profileSession: ProfileSession
    @State private var showProfilePicker = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("Selected profileId:")
                Text(profileSession.selectedProfileId.isEmpty ? "None" : profileSession.selectedProfileId)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle({
                let selectedId = profileSession.selectedProfileId
                if !selectedId.isEmpty {
                    return selectedId
                } else {
                    return "Home"
                }
            }())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Profile") { showProfilePicker = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Sign out") {
                        profileSession.clear()
                        auth.signOut()
                    }
                }
            }
        }
        .sheet(isPresented: $showProfilePicker) {
            SelectProfilesSheet { selected in
                profileSession.selectedProfileId = selected.id
                showProfilePicker = false
            }
        }
    }
}

