//
//  VideoRow.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct VideoRow: View {
    let video: YTVideo
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: video.thumbnailURL) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Rectangle().opacity(0.2)
                }
            }
            .frame(width: 140, height: 78)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(video.title)
                    .font(.subheadline)
                    .lineLimit(2)

                Text(video.channelTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isSelected {
                Image(systemName: "play.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
