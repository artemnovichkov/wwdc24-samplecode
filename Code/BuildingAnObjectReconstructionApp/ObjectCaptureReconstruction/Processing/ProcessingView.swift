/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Show the model creation progress and display the first created model.
*/

import RealityKit
import SwiftUI

import os

private let logger = Logger(subsystem: ObjectCaptureReconstructionApp.subsystem,
                            category: "ProcessingView")

struct ProcessingView: View {
    @State private var processedRequestsDetailLevel: [String] = []
    @State private var firstModelFileURL: URL?

    var body: some View {
        VStack {
            TopBarView(processedRequestsDetailLevel: processedRequestsDetailLevel)
            
            Spacer()
            
            ModelView(url: firstModelFileURL)
            
            Spacer()
            
            BottomBarView(firstModelFileURL: $firstModelFileURL, processedRequestsDetailLevel: $processedRequestsDetailLevel)
        }
    }
}
