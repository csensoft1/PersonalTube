//
//  MainAppView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct MainAppView: View {
    let videos: [YTVideo]
    @EnvironmentObject var auth: AuthManager
    
    var body: some View {
        NavigationStack {
            Text("App Home")
            NavigationStack {
                List(videos) { v in
                    NavigationLink {
                        VideoPlayerWithListView(videos: videos, initialVideoId: v.id)
                    } label: {
                        Text(v.title)
                    }
                }
                .navigationTitle("Your App")
                .toolbar {
                    Button("Sign out") { auth.signOut() }
                }
            }
        }
    }
}
