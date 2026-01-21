//
//  FeedVideo.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/17/26.
//
import Foundation

struct FeedVideo: Identifiable, Codable, Equatable {
    let id: String               // videoId
    let title: String
    let channelTitle: String
    let publishedAt: Date
    let thumbnailURL: String?
}

