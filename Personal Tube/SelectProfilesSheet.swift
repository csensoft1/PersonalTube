//
//  SelectProfilesSheet.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import SwiftUI

struct SelectProfilesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = ProfilesVM()

    let onSelect: (Profile) -> Void

    var body: some View {
        NavigationStack {
            List {
                if let err = vm.loadError {
                    Text("Error: \(err)").foregroundStyle(.red)
                }

                Section("Profiles") {
                    ForEach(vm.profiles) { p in
                        Button {
                            onSelect(p)
                            dismiss()
                        } label: {
                            HStack {
                                Text(p.name)
                                Spacer()
                                if p.isKid {
                                    Text("Kid").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Profile")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .onAppear { vm.load() }
        }
    }

    private struct AddProfileLoaderView: View {
        var onSaved: () -> Void

        @State private var libVM = YTLibraryVM()
        @State private var isLoaded = false

        var body: some View {
            Group {
                if isLoaded {
                    AddProfileSheet(
                        channels: libVM.channels,
                        likedVideos: libVM.liked,
                        playlists: libVM.playlists
                    ) {
                        onSaved()
                    }
                } else {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .task {
                await libVM.loadAll()
                isLoaded = true
            }
        }
    }
}

