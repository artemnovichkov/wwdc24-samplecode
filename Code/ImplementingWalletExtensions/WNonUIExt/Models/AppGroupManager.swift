/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The objects you use to connect to an app group shared container.
*/

import Foundation

// Set the extension's app group ID.
let appGroupID: String = "group.com.example.IssuerApp"

// Optional: Create an object that can interact with the file system
// within the app group container, to access persistable data within files.
let appGroupSharedContainerDirectory: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!

// Create an object that can connect to the user's defaults
// database within the app group container.
let appGroupSharedDefaults: UserDefaults = UserDefaults(suiteName: appGroupID)!
