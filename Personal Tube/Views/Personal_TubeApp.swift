//
//  Personal_TubeApp.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

@main
struct Personal_TubeApp: App {
    @StateObject private var auth = AuthManager()

    var body: some Scene {
        WindowGroup {
            RootGateView()
                .onAppear {
                    print(Bundle.main.object(forInfoDictionaryKey: "GIDClientID") ?? "missing")
                }
                .environmentObject(auth)
        }
    }
}
