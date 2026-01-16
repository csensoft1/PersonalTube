//
//  DatabaseModel.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import Foundation

struct Profile: Identifiable, Equatable {
    let id: String
    var name: String
    var isKid: Bool
}

struct ChannelItem: Identifiable, Equatable {
    let id: String      // channelId
    let title: String
}

struct LikedVideoItem: Identifiable, Equatable {
    let id: String      // videoId
    let title: String
}

struct PlaylistItem: Identifiable, Equatable {
    let id: String      // playlistId
    let title: String
}
