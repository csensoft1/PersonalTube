//
//  ProfileSession.swift
//  Personal Tube
//
//  Created by Senthil Kumar Chandrasekaran on 1/16/26.
//

import Foundation
import Combine

@MainActor
final class ProfileSession: ObservableObject {
    @Published var selectedProfileId: String {
        didSet { UserDefaults.standard.set(selectedProfileId, forKey: Keys.selectedProfileId) }
    }

    private enum Keys {
        static let selectedProfileId = "selectedProfileId"
    }

    init() {
        self.selectedProfileId = UserDefaults.standard.string(forKey: Keys.selectedProfileId) ?? ""
    }

    func clear() {
        selectedProfileId = ""
    }
}
