import SwiftUI

struct AddProfileLoaderView: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    @State private var isSaving: Bool = false
    @State private var errorMessage: String?

    // Library loading
    @State private var libVM = YTLibraryVM()
    @State private var isLoaded = false
    @State private var loadError: String?

    // Editor-like state (mirrors EditProfileView)
    @State private var name: String = ""
    @State private var isKid: Bool = false

    @State private var selectedChannelIds: Set<String> = []
    @State private var selectedPlaylistIds: Set<String> = []
    @State private var includeLikes: Bool = false

    // Search fields and focus
    @State private var channelSearch: String = ""
    @State private var playlistSearch: String = ""
    @State private var likedSearch: String = ""
    @FocusState private var channelSearchFocused: Bool
    @FocusState private var playlistSearchFocused: Bool
    @FocusState private var likedSearchFocused: Bool

    // Expand/collapse
    @State private var showSubscriptions: Bool = true
    @State private var showPlaylists: Bool = true
    @State private var showLiked: Bool = true

    var body: some View {
        NavigationStack {
            Group {
                if let err = loadError {
                    VStack(spacing: 12) {
                        Text("Failed to load library").font(.headline)
                        Text(err).font(.footnote).foregroundStyle(.secondary)
                        Button("Retry") { Task { await loadLibrary() } }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !isLoaded {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .task { await loadLibrary() }
                } else {
                    Form {
                        Section(header: Text("Profile")) {
                            TextField("Profile name", text: $name)
                                .textInputAutocapitalization(.words)
                                .autocorrectionDisabled()
                            Toggle("Kid profile", isOn: $isKid)
                            if let errorMessage {
                                Text(errorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(.red)
                            }
                        }

                        Section {
                            if showSubscriptions {
                                HStack {
                                    Text("Search")
                                    TextField("Search channels", text: $channelSearch)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($channelSearchFocused)
                                        .onSubmit { channelSearchFocused = false }
                                }

                                if libVM.channels.isEmpty {
                                    Text("No channels found").foregroundStyle(.secondary)
                                } else {
                                    ForEach(libVM.channels.filter { channelSearch.isEmpty || $0.title.localizedCaseInsensitiveContains(channelSearch) }, id: \.id) { ch in
                                        Toggle(isOn: Binding(
                                            get: { selectedChannelIds.contains(ch.id) },
                                            set: { newValue in
                                                if newValue { selectedChannelIds.insert(ch.id) } else { selectedChannelIds.remove(ch.id) }
                                            }
                                        )) {
                                            Text(ch.title)
                                        }
                                    }
                                }
                            }
                        } header: {
                            Button {
                                withAnimation(.easeInOut) { showSubscriptions.toggle() }
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(showSubscriptions ? 90 : 0))
                                        .animation(.easeInOut(duration: 0.2), value: showSubscriptions)
                                    Text("Subscriptions").font(.headline)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        Section {
                            if showPlaylists {
                                HStack {
                                    Text("Search")
                                    TextField("Search playlists", text: $playlistSearch)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($playlistSearchFocused)
                                        .onSubmit { playlistSearchFocused = false }
                                }

                                if libVM.playlists.isEmpty {
                                    Text("No playlists found").foregroundStyle(.secondary)
                                } else {
                                    ForEach(libVM.playlists.filter { playlistSearch.isEmpty || $0.title.localizedCaseInsensitiveContains(playlistSearch) }, id: \.id) { pl in
                                        Toggle(isOn: Binding(
                                            get: { selectedPlaylistIds.contains(pl.id) },
                                            set: { newValue in
                                                if newValue { selectedPlaylistIds.insert(pl.id) } else { selectedPlaylistIds.remove(pl.id) }
                                            }
                                        )) {
                                            Text(pl.title)
                                        }
                                    }
                                }
                            }
                        } header: {
                            Button {
                                withAnimation(.easeInOut) { showPlaylists.toggle() }
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(showPlaylists ? 90 : 0))
                                        .animation(.easeInOut(duration: 0.2), value: showPlaylists)
                                    Text("Playlists").font(.headline)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }

                        Section {
                            if showLiked {
                                HStack {
                                    Text("Search")
                                    TextField("Search liked videos", text: $likedSearch)
                                        .textFieldStyle(.roundedBorder)
                                        .focused($likedSearchFocused)
                                        .onSubmit { likedSearchFocused = false }
                                }

                                Toggle("Include liked videos", isOn: $includeLikes)
                                if includeLikes {
                                    let filteredLiked = libVM.liked.filter { likedSearch.isEmpty || $0.title.localizedCaseInsensitiveContains(likedSearch) }
                                    if filteredLiked.isEmpty {
                                        Text("No liked videos match your search.")
                                            .foregroundStyle(.secondary)
                                    } else {
                                        ForEach(filteredLiked, id: \.id) { v in
                                            Text(v.title)
                                        }
                                    }
                                } else {
                                    Text("Liked videos will be included in this profile's feed.")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } header: {
                            Button {
                                withAnimation(.easeInOut) { showLiked.toggle() }
                            } label: {
                                HStack {
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(showLiked ? 90 : 0))
                                        .animation(.easeInOut(duration: 0.2), value: showLiked)
                                    Text("Liked Videos").font(.headline)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Add Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    @MainActor
    private func save() async {
        guard !isSaving else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSaving = true
        errorMessage = nil
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
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }

    private var chosenChannelIds: [String] {
        Array(selectedChannelIds)
    }

    private var chosenPlaylistIds: [String] {
        Array(selectedPlaylistIds)
    }

    private var chosenVideoIds: [String] {
        includeLikes ? libVM.liked.map { $0.id } : []
    }

    @MainActor
    private func loadLibrary() async {
        loadError = nil
        do {
            await libVM.loadAll()
            isLoaded = true
        } catch {
            loadError = error.localizedDescription
        }
    }
}

#Preview {
    AddProfileLoaderView(onSaved: {})
}

