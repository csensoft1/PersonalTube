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

    init(videos: [YTVideo], initialVideoId: String? = nil) {
        self.videos = videos
        _selectedVideoId = State(initialValue: initialVideoId ?? videos.first?.id ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Player
            if !selectedVideoId.isEmpty {
                YouTubePlayerView(videoId: selectedVideoId)
                    .frame(height: 240) // adjust for your taste
                    .background(Color.black)
            } else {
                Rectangle().fill(.black).frame(height: 240)
            }

            Divider()

            // List
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
        .navigationTitle("Videos")
        .navigationBarTitleDisplayMode(.inline)
    }
}
