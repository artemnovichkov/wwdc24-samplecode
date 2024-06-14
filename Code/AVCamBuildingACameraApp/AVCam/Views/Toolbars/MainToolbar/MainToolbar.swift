/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays controls to capture, switch cameras, and view the last captured media item.
*/

import SwiftUI
import PhotosUI

/// A view that displays controls to capture, switch cameras, and view the last captured media item.
struct MainToolbar<CameraModel: Camera>: PlatformView {

    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    @State var camera: CameraModel
    
    var body: some View {
        HStack {
			ThumbnailButton(camera: camera)
            Spacer()
            CaptureButton(camera: camera)
            Spacer()
            SwitchCameraButton(camera: camera)
        }
        .foregroundColor(.white)
        .font(.system(size: 24))
        .frame(width: width, height: height)
        .padding([.leading, .trailing])
    }
    
    var width: CGFloat? { isRegularSize ? 250 : nil }
    var height: CGFloat? { 80 }
}

#Preview {
    Group {
        MainToolbar(camera: PreviewCameraModel())
    }
}
