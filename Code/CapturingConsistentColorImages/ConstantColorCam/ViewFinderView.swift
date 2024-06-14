/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that provides a live camera preview.
*/

import SwiftUI

struct ViewFinderView: View {
    @Binding var image: Image?
    
    var body: some View {
            if let image = image {
                image
                    .resizable()
                    .scaledToFit()
            }
    }
}
