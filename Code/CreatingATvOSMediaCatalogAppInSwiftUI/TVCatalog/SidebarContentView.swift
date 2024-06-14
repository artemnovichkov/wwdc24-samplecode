/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view for the app, with a sidebar and extra items.
*/

import SwiftUI

enum Tabs: String, Hashable, CaseIterable, Identifiable {
    case stack
    case sections
    case description
    case buttons
    case background
    case carousel
    case search

    var id: Self { self }
}

enum MyMoviesTab: Equatable, Hashable, Identifiable {
    case upNext
    case movieStore
    case tvStore
    case search
    case browse
    case library(MyLibraryTab?)

    var description: String {
        switch self {
        case .upNext: "Up Next"
        case .movieStore: "Movie Store"
        case .tvStore: "TV Store"
        case .search: "Search"
        case .browse: "Browse"
        case .library(let child): "Library | \(child?.rawValue ?? "")"
        }
    }

    var icon: String {
        switch self {
        case .upNext: return "movieclapper"
        case .movieStore: return "bag"
        case .tvStore: return "tv"
        case .search: return "magnifyingglass"
        case .browse: return "rectangle.stack"
        case .library(let child): return child?.icon ?? "x.circle"
        }
    }

    var color: Color {
        switch self {
        case .upNext: return .red
        case .movieStore: return .orange
        case .tvStore: return .yellow
        case .search: return .green
        case .browse: return .pink
        case .library: return .blue
        }
    }

    func detail() -> some View {
        Label(description, systemImage: icon)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.opacity(0.4))
    }

    var id: String { description }
}

enum MyLibraryTab: String, Equatable, Hashable, CaseIterable, Identifiable {
    case all = "All"
    case wantToWatch = "Want to Watch"
    case movies = "Movies"
    case tvShows = "TV Shows"
    case samples = "My Samples"

    var icon: String {
        switch self {
        case .all: "rectangle.stack"
        case .wantToWatch: "arrow.forward.circle"
        case .movies: "movieclapper"
        case .tvShows: "tv"
        case .samples: "popcorn"
        }
    }

    var color: Color {
        switch self {
        case .all: return .red
        case .wantToWatch: return .orange
        case .movies: return .green
        case .tvShows: return .blue
        case .samples: return .pink
        }
    }

    func detail() -> some View {
        Label("Library | \(rawValue)", systemImage: icon)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(color.opacity(0.4))
    }

    var id: String { rawValue }

    var applyModifiers: Bool { self == .movies }
    var isPrincipalTab: Bool { self == .all }
}

struct SidebarContentView: View {
    @State var selection: MyMoviesTab = .upNext
    var body: some View {
        TabView(selection: $selection) {
            Tab("Search", systemImage: "magnifyingglass", value: .search) {
                SearchView()
            }

            Tab("Up Next", systemImage: "movieclapper", value: .upNext) {
                StackView()
            }

            Tab("Movie Store", systemImage: "bag", value: .movieStore) {
                MyMoviesTab.movieStore.detail()
            }

            Tab("TV Store", systemImage: "tv", value: .tvStore) {
                MyMoviesTab.tvStore.detail()
            }

            Tab("Browse", systemImage: "rectangle.stack", value: .browse) {
                MyMoviesTab.browse.detail()
            }

            TabSection("Library") {
                ForEach(MyLibraryTab.allCases) { libraryTab in
                    Tab(libraryTab.rawValue,
                        systemImage: libraryTab.icon,
                        value: MyMoviesTab.library(libraryTab)
                    ) {
                        libraryTab.detail()
                    }
                }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    SidebarContentView()
}
