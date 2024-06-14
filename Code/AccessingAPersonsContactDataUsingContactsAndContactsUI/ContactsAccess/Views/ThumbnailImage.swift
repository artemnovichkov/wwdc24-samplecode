/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The contact's profile thumbnail picture.
*/
import SwiftUI

struct ThumbnailImage: View {
    let image: UIImage
    
    var body: some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: 40, height: 40)
            .clipShape(Circle())
    }
}
