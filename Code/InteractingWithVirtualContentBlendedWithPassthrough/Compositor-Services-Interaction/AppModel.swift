/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Shared app state and renderers.
*/

import SwiftUI

/// Maintains app-wide state.
@Observable
public class AppModel {
    // App state
    public var isFirstLaunch = true
    public var showImmersiveSpace = false
    public var immersiveSpaceIsShown = false
    public var immersionStyle: ImmersionStyle = .mixed
    
    // Limb visibility
    public var upperLimbVisibility: Visibility = .visible

    // Content rendering
    public var tintOpacity: Float = 0
    var tintRenderer: TintRenderer?
    var pathCollection: PathCollection?
}
