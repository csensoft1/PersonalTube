//
//  MainAppView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//
import SwiftUI

struct MainAppView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var profileSession: ProfileSession

    @StateObject private var vm = ProfileFeedVM()
    @State private var showProfilePicker = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Profile") { showProfilePicker = true }
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await refreshNow() }
                        } label: {
                            if vm.isRefreshing {
                                ProgressView()
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                        .disabled(vm.isRefreshing || profileSession.selectedProfileId.isEmpty)
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Sign out") {
                            profileSession.clear()
                            auth.signOut()
                        }
                    }
                }
                .sheet(isPresented: $showProfilePicker) {
                    SelectProfilesSheet { selected in
                        profileSession.selectedProfileId = selected.id
                        showProfilePicker = false

                        // Load cached feed instantly for this profile
                        vm.loadFromCache(profileId: selected.id)
                    }
                }
                .onAppear {
                    // Load cached feed for the currently selected profile (if any)
                    if !profileSession.selectedProfileId.isEmpty {
                        vm.loadFromCache(profileId: profileSession.selectedProfileId)
                    }
                }
                .onChange(of: profileSession.selectedProfileId) { newId in
                    vm.error = nil
                    vm.feed = []                 // optional: clear so you don’t show old profile briefly
                    if !newId.isEmpty {
                        vm.loadFromCache(profileId: newId)
                    }
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if profileSession.selectedProfileId.isEmpty {
            VStack(spacing: 12) {
                Text("No profile selected")
                    .font(.headline)
                Button("Select Profile") { showProfilePicker = true }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        } else if !vm.feed.isEmpty {
            // Convert cached/refreshed feed to your existing player/list model
            let videosForUI: [YTVideo] = vm.feed.map {
                YTVideo(
                    id: $0.id,
                    title: $0.title,
                    channelTitle: $0.channelTitle,
                    thumbnailURL: URL(string: $0.thumbnailURL ?? "")
                )
            }

            VideoPlayerWithListView(videos: videosForUI)
                .id(profileSession.selectedProfileId)
        } else {
            VStack(spacing: 12) {
                if let error = vm.error {
                    Text(error).foregroundStyle(.red).multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else {
                    Text("No cached feed yet.")
                        .foregroundStyle(.secondary)
                }

                Button("Refresh") {
                    Task { await refreshNow() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(vm.isRefreshing)
            }
            .padding()
        }
    }

    private func refreshNow() async {
        let pid = profileSession.selectedProfileId
        guard !pid.isEmpty else { return }
        await vm.refresh(profileId: pid)
    }
}


