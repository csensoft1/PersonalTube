//
//  ProfileFeedVM.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/17/26.
//

import Foundation
import Combine
@MainActor
final class ProfileFeedVM: ObservableObject {
    @Published var feed: [FeedVideo] = []
    @Published var error: String?
    @Published var isRefreshing = false

    func loadFromCache(profileId: String) {
        do {
            try AppDB.shared.open()
            if let cached = try AppDB.shared.loadFeedCache(profileId: profileId) {
                self.feed = cached
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func refresh(profileId: String) async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try AppDB.shared.open()

            let sources = try AppDB.shared.loadProfileSources(profileId: profileId)

            let built = try await FeedService.shared.buildRecentFeed(
                channelIds: sources.channelIds,
                includeLikes: sources.includeLikes,
                playlistIds: sources.playlistIds
            )

            self.feed = built
            try AppDB.shared.saveFeedCache(profileId: profileId, feed: built)

        } catch {
            self.error = error.localizedDescription
        }
    }
}
