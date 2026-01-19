import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    // Inputs
    let profileId: String
    let initialName: String
    let onSaved: (String) -> Void

    // Editor state
    @State private var name: String
    @State private var isKid: Bool = false

    // Source selections
    @State private var selectedChannelIds: Set<String> = []
    @State private var selectedPlaylistIds: Set<String> = []
    @State private var includeLikes: Bool = false

    // Library loading (mirrors AddProfileLoaderView)
    @State private var libVM = YTLibraryVM()
    @State private var isLoaded = false
    @State private var isSaving = false
    @State private var loadError: String?
    @State private var saveError: String?

    init(profileId: String, initialName: String, onSaved: @escaping (String) -> Void) {
        self.profileId = profileId
        self.initialName = initialName
        self.onSaved = onSaved
        _name = State(initialValue: initialName)
    }

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
                        }

                        Section("Subscriptions") {
                            if libVM.channels.isEmpty {
                                Text("No channels found").foregroundStyle(.secondary)
                            } else {
                                ForEach(libVM.channels, id: \.id) { ch in
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

                        Section("Playlists") {
                            if libVM.playlists.isEmpty {
                                Text("No playlists found").foregroundStyle(.secondary)
                            } else {
                                ForEach(libVM.playlists, id: \.id) { pl in
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

                        Section("Liked Videos") {
                            Toggle("Include liked videos", isOn: $includeLikes)
                            if includeLikes {
                                Text("Liked videos will be included in this profile's feed.")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                        }

                        if let saveError {
                            Section {
                                Text(saveError).foregroundStyle(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(!canSave || isSaving)
                }
            }
        }
    }

    private var canSave: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }

    @MainActor
    private func loadLibrary() async {
        loadError = nil
        do {
            await libVM.loadAll()
            try AppDB.shared.open()
            let sources = try AppDB.shared.loadProfileSources(profileId: profileId)
            self.name = self.initialName
            self.selectedChannelIds = Set(sources.channelIds)
            self.selectedPlaylistIds = Set(sources.playlistIds)
            self.includeLikes = sources.includeLikes
            
            let profiles = try AppDB.shared.fetchProfiles()
            if let me = profiles.first(where: { $0.id == profileId }) {
                self.isKid = me.isKid
                self.name = me.name // Use the persisted name instead of initialName
            }
            isLoaded = true
        } catch {
            loadError = error.localizedDescription
        }
    }

    @MainActor
    private func save() async {
        guard canSave else { return }
        isSaving = true
        saveError = nil
        do {
            try await persistUpdate()
            onSaved(name)
            dismiss()
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }

    private func persistUpdate() async throws {
        try AppDB.shared.open()
        try AppDB.shared.updateProfile(profileId: profileId, name: name, isKid: isKid)
        let videoIds = includeLikes ? libVM.liked.map(\.id) : []
        try AppDB.shared.replaceProfileSources(
            profileId: profileId,
            channelIds: Array(selectedChannelIds),
            videoIds: videoIds,
            playlistIds: Array(selectedPlaylistIds)
        )
    }
}

#Preview {
    EditProfileView(profileId: "demo", initialName: "Jane Doe", onSaved: { _ in })
}
