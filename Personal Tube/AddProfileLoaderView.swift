import SwiftUI

struct AddProfileLoaderView: View {
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

#Preview {
    AddProfileLoaderView(onSaved: {})
}

