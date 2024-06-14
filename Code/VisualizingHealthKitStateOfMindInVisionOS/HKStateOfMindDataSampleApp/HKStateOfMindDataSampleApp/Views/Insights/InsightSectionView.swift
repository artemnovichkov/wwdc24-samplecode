/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A container view for a section of insights.
*/

import SwiftUI

struct InsightSectionView<ContentView: View>: View {
    
    let sectionTitle: String
    @ViewBuilder let content: ContentView
    
    var body: some View {
        Section {
            content
        } header: {
            HStack {
                Text(sectionTitle)
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.leading)
                    .padding(.vertical)
                Spacer()
            }
        }
    }
    
}
