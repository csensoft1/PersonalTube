//
//  YTLibraryVM.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import Combine
import Foundation

@MainActor
final class YTLibraryVM: ObservableObject {
    @Published var channels: [ChannelItem] = []
    @Published var liked: [LikedVideoItem] = []
    @Published var playlists: [PlaylistItem] = []
    @Published var error: String?

    func loadAll() async {
        do {
            async let c = YouTubeAPI.shared.fetchAllSubscriptions()
            async let l = YouTubeAPI.shared.fetchAllLikedVideos()
            async let p = YouTubeAPI.shared.fetchAllPlaylists()
            (channels, liked, playlists) = try await (c, l, p)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
