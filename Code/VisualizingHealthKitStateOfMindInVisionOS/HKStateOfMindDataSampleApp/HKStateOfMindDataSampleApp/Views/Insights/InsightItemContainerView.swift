/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A container view for an individual insight.
*/

import SwiftUI

struct InsightItemContainerView<ContentView: View>: View {
    
    let backgroundColor: Color
    @ViewBuilder let content: ContentView
    
    var body: some View {
        ZStack {
            // The background color.
            backgroundColor
            // The content.
            content
                .padding()
        }
        .cornerRadius(12)
    }
    
}

