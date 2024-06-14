/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that shows a search interface.
*/

import SwiftUI

let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 40), count: 4)

/// The `SearchView` shows an example of a simple search function.
struct SearchView: View {
    /// When someone enters text into the search field, the system stores it
    /// here.
    @State var searchTerm: String = ""
    
    /// The view organizes a set of assets into a `Dictionary` to provide a
    /// lookup table that maps keywords to assets.
    var assets: [String: [Asset]] = Asset.lookupTable

    /// The assets to use in the `ForEach` come from here.
    ///
    /// If `searchTerm` is empty, this property flattens the lookup table into
    /// an array of assets and removes any duplicates.
    ///
    /// If there's a search term, the property performs the same operation, but
    /// first it filters out any items with keys that don't match the search
    /// term.
    var matchingAssets: [Asset] {
        if searchTerm.isEmpty {
            assets.values
                .flatMap { $0 }
                .reduce(into: []) {
                    if !$0.contains($1) {
                        $0.append($1)
                    }
                }
        } else {
            assets
                .filter { $0.key.contains(searchTerm) }
                .flatMap { $0.value }
                .reduce(into: []) {
                    if !$0.contains($1) {
                        $0.append($1)
                    }
                }
        }
    }

    /// For a stable list in the display, this takes any assets matching the
    /// current search term and sorts them by title.
    var sortedMatchingAssets: [Asset] {
        matchingAssets
            .sorted(using: SortDescriptor(\.title, comparator: .lexical))
    }

    /// This determines suggested search terms by examining all the keys
    /// (keywords) in the lookup table and filtering for matches against the
    /// current search term.
    var suggestedSearchTerms: [String] {
        guard !searchTerm.isEmpty else { return [] }
        return assets.keys.filter { $0.contains(searchTerm) }
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVGrid(columns: columns, spacing: 40) {
                ForEach(sortedMatchingAssets) { asset in
                    Button {} label: {
                        asset.landscapeImage
                            .resizable()
                            .aspectRatio(16 / 9, contentMode: .fit)
                        Text(asset.title)
                    }
                }
            }
            .buttonStyle(.borderless)
        }
        .scrollClipDisabled()
        .searchable(text: $searchTerm)
        .searchSuggestions {
            ForEach(suggestedSearchTerms, id: \.self) { suggestion in
                Text(suggestion)
            }
        }
    }
}

#Preview {
    SearchView()
}
