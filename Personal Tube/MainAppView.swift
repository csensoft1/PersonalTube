//
//  MainAppView.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//
import SwiftUI
import LocalAuthentication

struct MainAppView: View {
    @EnvironmentObject var auth: AuthManager
    @EnvironmentObject var profileSession: ProfileSession
    
    @StateObject private var vm = ProfileFeedVM()
    @State private var showProfilePicker = false
    @State private var showAddProfile = false
    @State private var showEditProfile = false
    @StateObject private var profilesVM = ProfilesVM()
    @State private var isLocked = false
    
    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Home")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { if !isLocked { showProfilePicker = true } }) {
                            Text("Profile")
                        }
                        .disabled(isLocked)
                    }
                    
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: {
                            if isLocked {
                                Task { await attemptUnlockWithBiometrics() }
                            } else {
                                // Lock immediately without authentication
                                isLocked = true
                            }
                        }) {
                            Image(systemName: isLocked ? "lock.fill" : "lock.open")
                        }
                        .accessibilityLabel(isLocked ? "Unlock" : "Lock")
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            // Refresh action
                            Button {
                                Task { await refreshNow() }
                            } label: {
                                if vm.isRefreshing {
                                    Label("Refreshing…", systemImage: "arrow.clockwise")
                                } else {
                                    Label("Refresh", systemImage: "arrow.clockwise")
                                }
                            }
                            .disabled(isLocked || vm.isRefreshing || profileSession.selectedProfileId.isEmpty)
                            
                            // Add profile action
                            Button {
                                showAddProfile = true
                            } label: {
                                Label("Add Profile", systemImage: "person.badge.plus")
                            }
                            .disabled(isLocked)
                            
                            // Edit profile action
                            Button {
                                showEditProfile = true
                            } label: {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                            .disabled(isLocked || profileSession.selectedProfileId.isEmpty)
                            
                            // Sign out action
                            Button(role: .destructive) {
                                profileSession.clear()
                                auth.signOut()
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                            .disabled(isLocked)
                        } label: {
                            if vm.isRefreshing {
                                // Show spinner in the menu trigger to mirror iMessage behavior during activity
                                ProgressView()
                            } else {
                                HStack(spacing: 2) {
                                    Image(systemName: "line.3.horizontal.circle.fill")
                                }
                                .accessibilityLabel("More")
                            }
                        }
                        .disabled(isLocked)
                    }
                }
                .sheet(isPresented: $showProfilePicker) {
                    SelectProfilesSheet(onSelect: { selected in
                        profileSession.selectedProfileId = selected.id
                        showProfilePicker = false
                        
                        // Load cached feed instantly for this profile
                        vm.loadFromCache(profileId: selected.id)
                    })
                }
                .sheet(isPresented: $showAddProfile) {
                    AddProfileLoaderView(onSaved: {
                        profilesVM.load()
                        showAddProfile = false
                    })
                }
                .sheet(isPresented: $showEditProfile) {
                    // Pass the currently selected profile name if available; fallback to empty
                    let currentName = profilesVM.profiles.first(where: { $0.id == profileSession.selectedProfileId })?.name ?? ""
                    EditProfileView(profileId: profileSession.selectedProfileId, initialName: currentName) { newName in
                        // TODO: Persist the rename via ProfilesVM if supported
                        profilesVM.load()
                        showEditProfile = false
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
                Button("Select Profile") { if !isLocked { showProfilePicker = true } }
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
    
    @MainActor
    func attemptUnlockWithBiometrics() async {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        context.localizedFallbackTitle = "Use Passcode" // shown on Face ID prompt
        
        var error: NSError?
        
        // 1) Try Face ID / Touch ID first
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            do {
                let ok = try await context.evaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    localizedReason: "Unlock with Face ID"
                )
                if ok { isLocked = false }
                return
            } catch {
                // If user taps "Use Passcode" or biometrics unavailable mid-flight, we can fall back below
            }
        }
        
        // 2) Optional fallback to passcode (if you want)
        var error2: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error2) {
            do {
                let ok = try await context.evaluatePolicy(
                    .deviceOwnerAuthentication,
                    localizedReason: "Unlock to continue"
                )
                if ok { isLocked = false }
            } catch {
                // keep locked
            }
        }
    }
}

