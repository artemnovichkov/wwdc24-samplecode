/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The structure that provides preconfigured App Shortcuts.
*/

import AppIntents

struct ExampleAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateAssetsIntent(),
            phrases: [
                "Create \(.applicationName)"
            ],
            shortTitle: "Create",
            systemImageName: "photo.badge.plus"
        )
        AppShortcut(
            intent: OpenAssetIntent(),
            phrases: [
                "Open \(.applicationName)"
            ],
            shortTitle: "Open",
            systemImageName: "photo"
        )
        AppShortcut(
            intent: SearchAssetsIntent(),
            phrases: [
                "Search \(.applicationName)"
            ],
            shortTitle: "Search",
            systemImageName: "magnifyingglass"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .lightBlue
}
