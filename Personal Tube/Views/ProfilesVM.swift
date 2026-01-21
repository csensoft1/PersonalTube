//
//  ProfilesVM.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import Foundation
import Combine

@MainActor
final class ProfilesVM: ObservableObject {
    @Published var profiles: [Profile] = []
    @Published var loadError: String?

    func load() {
        do {
            try AppDB.shared.open()
            profiles = try AppDB.shared.fetchProfiles()
        } catch {
            loadError = error.localizedDescription
        }
    }
}
