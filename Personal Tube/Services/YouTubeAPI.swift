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
