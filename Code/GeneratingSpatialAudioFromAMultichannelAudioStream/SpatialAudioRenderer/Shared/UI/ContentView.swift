/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The main content view of the app.
*/
import SwiftUI

struct ContentView: View {
    
    var body: some View {
        
        VStack(alignment: .center) {
            Text("Spatial Audio Renderer")
                .fontWeight(.bold)
            Spacer()
                .frame(height: 20)
            ChainView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(20)
        
    }
    
}
