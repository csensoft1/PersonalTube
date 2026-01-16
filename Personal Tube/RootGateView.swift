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
            let videos = [
                YTVideo(
                    id: "dQw4w9WgXcQ",
                    title: "Rick Astley - Never Gonna Give You Up (Official Music Video)",
                    channelTitle: "Rick Astley",
                    thumbnailURL: URL(string: "https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg")
                ),
                YTVideo(
                    id: "9bZkp7q19f0",
                    title: "PSY - GANGNAM STYLE(강남스타일) M/V",
                    channelTitle: "officialpsy",
                    thumbnailURL: URL(string: "https://i.ytimg.com/vi/9bZkp7q19f0/hqdefault.jpg")
                ),
                YTVideo(
                    id: "3JZ_D3ELwOQ",
                    title: "Mark Ronson - Uptown Funk (Official Video) ft. Bruno Mars",
                    channelTitle: "Mark Ronson",
                    thumbnailURL: URL(string: "https://i.ytimg.com/vi/3JZ_D3ELwOQ/hqdefault.jpg")
                ),
                YTVideo(
                    id: "fLexgOxsZu0",
                    title: "Taylor Swift - Shake It Off",
                    channelTitle: "Taylor Swift",
                    thumbnailURL: URL(string: "https://i.ytimg.com/vi/fLexgOxsZu0/hqdefault.jpg")
                ),
                YTVideo(
                    id: "VbfpW0pbvaU",
                    title: "Ed Sheeran - Shape of You (Official Music Video)",
                    channelTitle: "Ed Sheeran",
                    thumbnailURL: URL(string: "https://i.ytimg.com/vi/VbfpW0pbvaU/hqdefault.jpg")
                )
            ]
            MainAppView(videos: videos)

        case .error(let msg):
            VStack(spacing: 12) {
                Text("Login error")
                Text(msg).font(.footnote).foregroundStyle(.secondary)
                Button("Try again") { Task { await auth.bootstrap() } }
            }.padding()
        }
    }
}

