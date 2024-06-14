/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows multiple sections.
*/

import SwiftUI

struct SectionsView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Section("My Movies") {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 40) {
                        ShelfContent()
                    }
                }
            }

            Divider()

            Section {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 40) {
                        ShelfContent()
                    }
                }
            } header: {
                Label("My Movies", systemImage: "movieclapper.fill")
            }

            Divider()

            Section {
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 40) {
                        ShelfContent()
                    }
                }
            } header: {
                Label("My Movies", systemImage: "movieclapper.fill")
            } footer: {
                Text("Some extra information")
                    .font(.caption)
            }
        }
        .scrollClipDisabled()
    }
}

struct ShelfContent: View {
    var body: some View {
        ForEach(0..<10) { _ in
            Button {} label: {
                CodeSampleArtwork(size: .init(width: 300, height: 160))
                    .hoverEffect(.highlight)
                Text(titles.randomElement()!)
            }
            .containerRelativeFrame(.horizontal, count: 5, spacing: 40)
        }
        .buttonStyle(.borderless)
    }
}

#Preview {
    SectionsView()
}
