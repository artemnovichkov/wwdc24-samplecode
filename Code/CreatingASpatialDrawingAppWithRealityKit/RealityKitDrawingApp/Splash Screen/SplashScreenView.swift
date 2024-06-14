/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view to display a splash screen when launching the app. Expected to be placed in a window.
*/

import RealityKit
import SwiftUI

struct SplashScreenView: View {
    private static let startButtonWidth: CGFloat = 150
        
    @Environment(\.setMode) var setMode
    
    var body: some View {
        ZStack {
            SplashScreenBackgroundView()
            
            VStack {
                Spacer(minLength: 100)
                
                SplashScreenForegroundView()
                
                Spacer(minLength: 50)
                
                Button {
                    Task {
                        await setMode(.chooseWorkVolume)
                    }
                } label: {
                    Text("Start").frame(minWidth: Self.startButtonWidth)
                }
                .glassBackgroundEffect()
                .controlSize(.extraLarge)
                .frame(width: Self.startButtonWidth)
                
                Spacer(minLength: 100)
            }
            .frame(depth: 0, alignment: DepthAlignment.back)
        }
        .frame(depth: 100, alignment: DepthAlignment.back)
    }
}

