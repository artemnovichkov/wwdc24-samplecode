/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view that displays the captured photos.
*/

import Photos
import SwiftUI

struct PhotosTabView: View {
    // The constant color UIImage.
    private var constantColorImage: UIImage?
    
    // The confidence map using the Core Video pixel buffer
    private var confidenceMap: UIImage?
    
    // The confidence level for the constant color photo.
    private var confidenceLevel: Float?
    
    // The fallback photo UIImage.
    private var fallbackPhoto: UIImage?
    
    // The normal photo UIImage.
    private var normalPhoto: UIImage?
    
    // The selection integer for the tab view.
    @State private var selection: Int = 0
    
    // The environment variable to dismiss the photos tab view.
    @Environment(\.dismiss) private var dismiss
    
    // The view initializer for the photos tab view.
    init(normalPhoto: UIImage? = nil, constantColorImage: UIImage? = nil, fallbackPhoto: UIImage? = nil, confidenceMap: UIImage? = nil, confidenceLevel: Float? = nil) {
        self.constantColorImage = constantColorImage
        self.fallbackPhoto = fallbackPhoto
        self.confidenceMap = confidenceMap
        self.confidenceLevel = confidenceLevel
        self.normalPhoto = normalPhoto
    }
    
    var body: some View {
        HStack {
            Spacer()
            // The Done button to dismiss the photos tab view.
            Button() {
                dismiss()
            } label: {
                Text("Done").foregroundStyle(.blue)
            }.padding(.trailing, 15)
        }
        NavigationStack {
            if let normalPhoto = normalPhoto {
                // The normal photo tab view.
                TabView(selection: $selection) {
                    ImageView(image: normalPhoto, textLabel: "Normal Photo")
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            } else if let constantColorImage = constantColorImage, let fallbackPhoto = fallbackPhoto, let confidenceMap = confidenceMap {
                // The constant color image, fallback photo, and confidence map tab view.
                TabView(selection: $selection) {
                    ImageView(image: constantColorImage, textLabel: "Constant Color Photo").tag(0)
                    ImageView(image: fallbackPhoto, textLabel: "Fallback Photo").tag(1)
                    ImageView(image: confidenceMap, textLabel: "Confidence Map \(String(format: "%.2f", confidenceLevel!))").tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            } else if let constantColorImage, let confidenceMap = confidenceMap {
                // The constant color image and confidence map tab view.
                TabView(selection: $selection) {
                    ImageView(image: constantColorImage, textLabel: "Constant Color Photo").tag(0)
                    ImageView(image: confidenceMap, textLabel: "Confidence Map \(String(format: "%.2f", confidenceLevel!))").tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            }
        }
    }
    
}

// The image view for the photos tab view.
struct ImageView: View {
    private var image: UIImage?
    private var text: String
        
    // The initializer for the image view.
    init(image: UIImage?, textLabel: String) {
        self.image = image
        self.text = textLabel
    }
    
    var body: some View {
        VStack {
            if let image {
                // The image and text views for the constant color photo, fallback photo, and normal photo.
                Text(text).padding(.bottom, 40).foregroundColor(.white)
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(15)
                    .padding(.bottom, 50)
            }
        }
        .background(.black)
    }
}

#Preview {
    PhotosTabView(normalPhoto: UIImage(systemName: "exclamationmark.circle.fill"))
}

