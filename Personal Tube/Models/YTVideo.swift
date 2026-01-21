//
//  YTVideo.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import Foundation

struct YTVideo: Identifiable, Equatable {
    let id: String          // YouTube videoId
    let title: String
    let channelTitle: String
    let thumbnailURL: URL?
}
