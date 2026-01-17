//
//  FeedService.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/17/26.
//

import Foundation

@MainActor
final class FeedService {
    static let shared = FeedService()
    private init() {}

    // Tune these
    let recentPerChannel = 25
    let recentLikedLimit = 50
    let recentPerPlaylist = 50

    func buildRecentFeed(
        channelIds: [String],
        includeLikes: Bool,
        playlistIds: [String]
    ) async throws -> [FeedVideo] {

        async let channelIdsTask: [String] = fetchIdsFromChannels(channelIds)
        async let likedIdsTask: [String] = includeLikes ? YouTubeAPI.shared.fetchRecentLikedVideoIds(limit: recentLikedLimit) : []
        async let playlistIdsTask: [String] = fetchIdsFromPlaylists(playlistIds)

        let (fromChannels, fromLikes, fromPlaylists) = try await (channelIdsTask, likedIdsTask, playlistIdsTask)

        // Combine + unique
        var unique = Set<String>()
        unique.formUnion(fromChannels)
        unique.formUnion(fromLikes)
        unique.formUnion(fromPlaylists)

        // Hydrate + sort by upload time desc
        var hydrated = try await YouTubeAPI.shared.hydrateVideos(ids: Array(unique))
        hydrated.sort { $0.publishedAt > $1.publishedAt }
        return hydrated
    }

    private func fetchIdsFromChannels(_ channelIds: [String]) async throws -> [String] {
        guard !channelIds.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: [String].self) { group in
            for cid in channelIds {
                group.addTask {
                    try await YouTubeAPI.shared.fetchRecentVideoIdsForChannel(channelId: cid, maxResults: self.recentPerChannel)
                }
            }
            var all: [String] = []
            for try await part in group { all += part }
            return all
        }
    }

    private func fetchIdsFromPlaylists(_ playlistIds: [String]) async throws -> [String] {
        guard !playlistIds.isEmpty else { return [] }

        return try await withThrowingTaskGroup(of: [String].self) { group in
            for pid in playlistIds {
                group.addTask {
                    try await YouTubeAPI.shared.fetchRecentPlaylistVideoIds(playlistId: pid, maxResults: self.recentPerPlaylist)
                }
            }
            var all: [String] = []
            for try await part in group { all += part }
            return all
        }
    }
}
