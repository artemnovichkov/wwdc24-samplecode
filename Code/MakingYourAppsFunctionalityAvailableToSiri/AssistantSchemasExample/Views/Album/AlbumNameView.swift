/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the name of a media album.
*/

import SwiftUI

struct AlbumNameView: View {
    enum Focus {
        case field
    }
    
    // MARK: Properties
    
    let album: Album?
    
    @State private var name = ""
    
    @FocusState private var focus: Focus?
    
    @Environment(MediaLibrary.self) private var library
    @Environment(\.dismiss) private var dismiss
    
    // MARK: Lifecycle
    
    init(album: Album? = nil) {
        self.album = album
        _name = State(wrappedValue: album?.title ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Name", text: $name)
                    .focused($focus, equals: .field)
                    .onSubmit(saveAction)
            }
            .navigationTitle("Album Name")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: saveAction)
                        .disabled(name.isEmpty)
                }
            }
        }
        .onAppear {
            focus = .field
        }
    }
    
    // MARK: Methods
    
    private func saveAction() {
        Task {
            if let album {
                try await album.setTitle(name)
            } else {
                try await library.createAlbum(with: name)
            }
            
            // Close.
            dismiss()
        }
    }
}

#Preview {
    AlbumNameView(album: nil)
        .environment(MediaLibrary())
}
