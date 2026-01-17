//
//  YouTubeAPI.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import Foundation

enum YTAPIError: Error {
    case noAccessToken
    case badStatus(Int, String)
    case decodeFailed
}

final class YouTubeAPI {
    static let shared = YouTubeAPI()
    private init() {}

    // Inject from AuthManager (GoogleSignIn current user access token)
    var accessTokenProvider: (() -> String?)?

    private func makeRequest(url: URL) throws -> URLRequest {
        guard let token = accessTokenProvider?(), !token.isEmpty else {
            throw YTAPIError.noAccessToken
        }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return req
    }

    private func fetch<T: Decodable>(_ url: URL, as type: T.Type) async throws -> T {
        let req = try makeRequest(url: url)
        let (data, resp) = try await URLSession.shared.data(for: req)

        guard let http = resp as? HTTPURLResponse else {
            throw YTAPIError.badStatus(-1, "No HTTP response")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw YTAPIError.badStatus(http.statusCode, body)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw YTAPIError.decodeFailed
        }
    }
}

extension YouTubeAPI {

    struct SubscriptionsResponse: Decodable {
        let nextPageToken: String?
        let items: [Item]

        struct Item: Decodable {
            let snippet: Snippet
            struct Snippet: Decodable {
                let title: String
                let resourceId: ResourceId
                struct ResourceId: Decodable {
                    let channelId: String
                }
            }
        }
    }

    func fetchAllSubscriptions(maxPerPage: Int = 50) async throws -> [ChannelItem] {
        var out: [ChannelItem] = []
        var pageToken: String? = nil

        repeat {
            var comps = URLComponents(string: "https://www.googleapis.com/youtube/v3/subscriptions")!
            comps.queryItems = [
                .init(name: "part", value: "snippet"),
                .init(name: "mine", value: "true"),
                .init(name: "maxResults", value: "\(min(maxPerPage, 50))")
            ]
            if let pageToken { comps.queryItems?.append(.init(name: "pageToken", value: pageToken)) }

            let res: SubscriptionsResponse = try await fetch(comps.url!, as: SubscriptionsResponse.self)
            out += res.items.map { ChannelItem(id: $0.snippet.resourceId.channelId, title: $0.snippet.title) }
            pageToken = res.nextPageToken
        } while pageToken != nil

        return out
    }
}

extension YouTubeAPI {

    struct LikedVideosResponse: Decodable {
        let nextPageToken: String?
        let items: [Item]

        struct Item: Decodable {
            let id: String
            let snippet: Snippet
            struct Snippet: Decodable {
                let title: String
            }
        }
    }

    func fetchAllLikedVideos(maxPerPage: Int = 50) async throws -> [LikedVideoItem] {
        var out: [LikedVideoItem] = []
        var pageToken: String? = nil

        repeat {
            var comps = URLComponents(string: "https://www.googleapis.com/youtube/v3/videos")!
            comps.queryItems = [
                .init(name: "part", value: "snippet"),
                .init(name: "myRating", value: "like"),
                .init(name: "maxResults", value: "\(min(maxPerPage, 50))")
            ]
            if let pageToken { comps.queryItems?.append(.init(name: "pageToken", value: pageToken)) }

            let res: LikedVideosResponse = try await fetch(comps.url!, as: LikedVideosResponse.self)
            out += res.items.map { LikedVideoItem(id: $0.id, title: $0.snippet.title) }
            pageToken = res.nextPageToken
        } while pageToken != nil

        return out
    }
}

extension YouTubeAPI {

    struct PlaylistsResponse: Decodable {
        let nextPageToken: String?
        let items: [Item]

        struct Item: Decodable {
            let id: String
            let snippet: Snippet
            struct Snippet: Decodable {
                let title: String
            }
        }
    }

    func fetchAllPlaylists(maxPerPage: Int = 50) async throws -> [PlaylistItem] {
        var out: [PlaylistItem] = []
        var pageToken: String? = nil

        repeat {
            var comps = URLComponents(string: "https://www.googleapis.com/youtube/v3/playlists")!
            comps.queryItems = [
                .init(name: "part", value: "snippet"),
                .init(name: "mine", value: "true"),
                .init(name: "maxResults", value: "\(min(maxPerPage, 50))")
            ]
            if let pageToken { comps.queryItems?.append(.init(name: "pageToken", value: pageToken)) }

            let res: PlaylistsResponse = try await fetch(comps.url!, as: PlaylistsResponse.self)
            out += res.items.map { PlaylistItem(id: $0.id, title: $0.snippet.title) }
            pageToken = res.nextPageToken
        } while pageToken != nil

        return out
    }
}

extension YouTubeAPI {
    struct SearchResponse: Decodable {
        let nextPageToken: String?
        let items: [Item]

        struct Item: Decodable {
            let id: VideoId
            struct VideoId: Decodable { let videoId: String? }
        }
    }

    func fetchRecentVideoIdsForChannel(channelId: String, maxResults: Int = 25) async throws -> [String] {
        var comps = URLComponents(string: "https://www.googleapis.com/youtube/v3/search")!
        comps.queryItems = [
            .init(name: "part", value: "id"),
            .init(name: "channelId", value: channelId),
            .init(name: "type", value: "video"),
            .init(name: "order", value: "date"),
            .init(name: "maxResults", value: "\(min(maxResults, 50))")
        ]
        let res: SearchResponse = try await fetch(comps.url!, as: SearchResponse.self)
        return res.items.compactMap { $0.id.videoId }
    }
}

extension YouTubeAPI {
    struct LikedVideosIdsResponse: Decodable {
        let nextPageToken: String?
        let items: [Item]
        struct Item: Decodable { let id: String }
    }

    func fetchRecentLikedVideoIds(limit: Int = 50) async throws -> [String] {
        // videos.list supports maxResults (50 max)
        var comps = URLComponents(string: "https://www.googleapis.com/youtube/v3/videos")!
        comps.queryItems = [
            .init(name: "part", value: "id"),
            .init(name: "myRating", value: "like"),
            .init(name: "maxResults", value: "\(min(limit, 50))")
        ]
        let res: LikedVideosIdsResponse = try await fetch(comps.url!, as: LikedVideosIdsResponse.self)
        return res.items.map { $0.id }
    }
}

extension YouTubeAPI {
    struct PlaylistItemsResponse: Decodable {
        let nextPageToken: String?
        let items: [Item]

        struct Item: Decodable {
            let snippet: Snippet
            struct Snippet: Decodable {
                let resourceId: ResourceId
                struct ResourceId: Decodable { let videoId: String? }
            }
        }
    }

    func fetchRecentPlaylistVideoIds(playlistId: String, maxResults: Int = 50) async throws -> [String] {
        var comps = URLComponents(string: "https://www.googleapis.com/youtube/v3/playlistItems")!
        comps.queryItems = [
            .init(name: "part", value: "snippet"),
            .init(name: "playlistId", value: playlistId),
            .init(name: "maxResults", value: "\(min(maxResults, 50))")
        ]
        let res: PlaylistItemsResponse = try await fetch(comps.url!, as: PlaylistItemsResponse.self)
        return res.items.compactMap { $0.snippet.resourceId.videoId }
    }
}

extension YouTubeAPI {
    struct VideosHydrateResponse: Decodable {
        let items: [Item]
        struct Item: Decodable {
            let id: String
            let snippet: Snippet
            struct Snippet: Decodable {
                let title: String
                let channelTitle: String
                let publishedAt: String
                let thumbnails: Thumbnails?
                struct Thumbnails: Decodable {
                    let medium: Thumb?
                    let high: Thumb?
                    struct Thumb: Decodable { let url: String }
                }
            }
        }
    }

    func hydrateVideos(ids: [String]) async throws -> [FeedVideo] {
        guard !ids.isEmpty else { return [] }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        func parseDate(_ s: String) -> Date? {
            if let d = iso.date(from: s) { return d }
            // fallback if no fractional seconds
            let iso2 = ISO8601DateFormatter()
            iso2.formatOptions = [.withInternetDateTime]
            return iso2.date(from: s)
        }

        // Chunk into 50 ids per request
        let chunks: [[String]] = stride(from: 0, to: ids.count, by: 50).map {
            Array(ids[$0..<min($0+50, ids.count)])
        }

        return try await withThrowingTaskGroup(of: [FeedVideo].self) { group in
            for chunk in chunks {
                group.addTask {
                    var comps = URLComponents(string: "https://www.googleapis.com/youtube/v3/videos")!
                    comps.queryItems = [
                        .init(name: "part", value: "snippet"),
                        .init(name: "id", value: chunk.joined(separator: ","))
                    ]
                    let res: VideosHydrateResponse = try await self.fetch(comps.url!, as: VideosHydrateResponse.self)

                    return res.items.compactMap { item in
                        guard let published = parseDate(item.snippet.publishedAt) else { return nil }
                        let thumb = item.snippet.thumbnails?.high?.url ?? item.snippet.thumbnails?.medium?.url
                        return FeedVideo(
                            id: item.id,
                            title: item.snippet.title,
                            channelTitle: item.snippet.channelTitle,
                            publishedAt: published,
                            thumbnailURL: thumb
                        )
                    }
                }
            }

            var all: [FeedVideo] = []
            for try await part in group { all += part }
            return all
        }
    }
}
