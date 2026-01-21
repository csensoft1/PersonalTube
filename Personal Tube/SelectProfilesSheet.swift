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
}

