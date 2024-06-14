/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Display a USDZ file.
*/

import RealityKit
import SwiftUI

import os

private let logger = Logger(subsystem: ObjectCaptureReconstructionApp.subsystem,
                            category: "ModelView")

struct ModelView: View {
    let url: URL?
    @Environment(AppDataModel.self) private var appDataModel: AppDataModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if let url {
            RealityView { content in
                if let entity = try? await ModelEntity(contentsOf: url) {
                    content.add(entity)
                    
                    content.cameraTarget = entity
                } else {
                    logger.warning("Couldn't load the model!")
                }
            }
            .realityViewCameraControls(.orbit)
            .background(colorScheme == .light ? .white : .black)
            
        } else {
            Image(systemName: "cube.transparent")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120)
                .foregroundStyle(.tertiary)
                .fontWeight(.ultraLight)
        }
    }
}
