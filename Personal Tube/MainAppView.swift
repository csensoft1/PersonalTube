//
//  MainAppView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var auth: AuthManager

    var body: some View {
        NavigationStack {
            Text("App Home")
                .navigationTitle("Your App")
                .toolbar {
                    Button("Sign out") { auth.signOut() }
                }
        }
    }
}
