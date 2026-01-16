//
//  AddProfileSheet.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct AddProfileSheet: View {
    @Environment(\.dismiss) private var dismiss

    let channels: [ChannelItem]
    let likedVideos: [LikedVideoItem]
    let playlists: [PlaylistItem]
    let onSaved: () -> Void

    @State private var name: String = ""
    @State private var isKid: Bool = false

    @State private var selectedChannelId: String = ""
    @State private var selectedVideoId: String = ""
    @State private var selectedPlaylistId: String = ""

    @State private var chosenChannelIds: [String] = []
    @State private var chosenVideoIds: [String] = []
    @State private var chosenPlaylistIds: [String] = []

    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                if let error {
                    Text(error).foregroundStyle(.red)
                }

                Section("Profile") {
                    TextField("Name", text: $name)
                    Toggle("Kid profile", isOn: $isKid)
                }

                Section("Add Channel") {
                    Picker("Channel", selection: $selectedChannelId) {
                        Text("Select…").tag("")
                        ForEach(channels) { c in
                            Text(c.title).tag(c.id)
                        }
                    }

                    Button("Add channel") {
                        guard !selectedChannelId.isEmpty else { return }
                        if !chosenChannelIds.contains(selectedChannelId) {
                            chosenChannelIds.append(selectedChannelId)
                        }
                    }
                    .disabled(selectedChannelId.isEmpty)

                    chosenListView(
                        title: "Selected channels",
                        ids: chosenChannelIds,
                        resolve: { id in channels.first(where: { $0.id == id })?.title ?? id },
                        onRemove: { id in chosenChannelIds.removeAll { $0 == id } }
                    )
                }

                Section("Add Liked Video") {
                    Picker("Liked video", selection: $selectedVideoId) {
                        Text("Select…").tag("")
                        ForEach(likedVideos) { v in
                            Text(v.title).tag(v.id)
                        }
                    }

                    Button("Add video") {
                        guard !selectedVideoId.isEmpty else { return }
                        if !chosenVideoIds.contains(selectedVideoId) {
                            chosenVideoIds.append(selectedVideoId)
                        }
                    }
                    .disabled(selectedVideoId.isEmpty)

                    chosenListView(
                        title: "Selected videos",
                        ids: chosenVideoIds,
                        resolve: { id in likedVideos.first(where: { $0.id == id })?.title ?? id },
                        onRemove: { id in chosenVideoIds.removeAll { $0 == id } }
                    )
                }

                Section("Add Playlist") {
                    Picker("Playlist", selection: $selectedPlaylistId) {
                        Text("Select…").tag("")
                        ForEach(playlists) { p in
                            Text(p.title).tag(p.id)
                        }
                    }

                    Button("Add playlist") {
                        guard !selectedPlaylistId.isEmpty else { return }
                        if !chosenPlaylistIds.contains(selectedPlaylistId) {
                            chosenPlaylistIds.append(selectedPlaylistId)
                        }
                    }
                    .disabled(selectedPlaylistId.isEmpty)

                    chosenListView(
                        title: "Selected playlists",
                        ids: chosenPlaylistIds,
                        resolve: { id in playlists.first(where: { $0.id == id })?.title ?? id },
                        onRemove: { id in chosenPlaylistIds.removeAll { $0 == id } }
                    )
                }
            }
            .navigationTitle("New Profile")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .onAppear {
            // Preselect first items for nicer UX
            if selectedChannelId.isEmpty { selectedChannelId = channels.first?.id ?? "" }
            if selectedVideoId.isEmpty { selectedVideoId = likedVideos.first?.id ?? "" }
            if selectedPlaylistId.isEmpty { selectedPlaylistId = playlists.first?.id ?? "" }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        do {
            try AppDB.shared.open()
            try AppDB.shared.createProfile(
                name: trimmed,
                isKid: isKid,
                channelIds: chosenChannelIds,
                videoIds: chosenVideoIds,
                playlistIds: chosenPlaylistIds
            )
            onSaved()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
    }

    @ViewBuilder
    private func chosenListView(
        title: String,
        ids: [String],
        resolve: @escaping (String) -> String,
        onRemove: @escaping (String) -> Void
    ) -> some View {
        if ids.isEmpty {
            Text("None").foregroundStyle(.secondary)
        } else {
            ForEach(ids, id: \.self) { id in
                HStack {
                    Text(resolve(id)).lineLimit(1)
                    Spacer()
                    Button {
                        onRemove(id)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
