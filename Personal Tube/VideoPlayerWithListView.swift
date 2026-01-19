//
//  VideoPlayerWithListView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct VideoPlayerWithListView: View {
    let videos: [YTVideo]

    @State private var selectedVideoId: String
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(videos: [YTVideo], initialVideoId: String? = nil) {
        self.videos = videos
        _selectedVideoId = State(initialValue: initialVideoId ?? videos.first?.id ?? "")
    }

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // Portrait on iPhone (usually) — keep vertical layout
                VStack(spacing: 0) {
                    playerView
                    Divider()
                    listView
                }
            } else {
                // Landscape / wider size — split view with player on left and list on right
                GeometryReader { geo in
                    HStack(spacing: 0) {
                        playerView
                            .frame(width: geo.size.width * 0.55)
                        Divider()
                        listView
                    }
                }
            }
        }
        .navigationTitle("Videos")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var playerView: some View {
        Group {
            if !selectedVideoId.isEmpty {
                YouTubePlayerView(videoId: selectedVideoId)
                    .frame(height: 240)
                    .background(Color.black)
            } else {
                Rectangle().fill(.black).frame(height: 240)
            }
        }
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(videos) { v in
                    VideoRow(video: v, isSelected: v.id == selectedVideoId)
                        .padding(.horizontal, 12)
                        .onTapGesture {
                            selectedVideoId = v.id
                        }
                    Divider().opacity(0.4)
                }
            }
        }
    }
}
