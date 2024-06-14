/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A wrapper class for the animal stamp tool item.
*/

import UIKit
import PencilKit

/// A wrapper class for the animal stamp tool item.
///
/// This class defines additional attributes for the animal stamp tool because
/// `PKToolPickerCustomItem` disallows subclassing.
@MainActor class AnimalStampWrapper {
    let toolItem: PKToolPickerCustomItem
    let attributeViewController: AttributeViewController

    init() {
        let attributeVC = AttributeViewController(attributeModel: Model())
        self.attributeViewController = attributeVC
        
        let identifier = "com.example.apple-samplecode.animal-stamp"
        let name = NSLocalizedString("Animal Stamp", comment: "Name of the animal stamp tool")
        var config = PKToolPickerCustomItem.Configuration(identifier: identifier, name: name)
        
        // The color blue from the tool picker.
        config.defaultColor = UIColor(red: 21 / 255, green: 126 / 255, blue: 251 / 255, alpha: 1)
        config.allowsColorSelection = true
        
        config.widthVariants = [10: Self.makeWidthVariantImage(for: 0),
                                20: Self.makeWidthVariantImage(for: 1),
                                30: Self.makeWidthVariantImage(for: 2),
                                50: Self.makeWidthVariantImage(for: 3),
                                80: Self.makeWidthVariantImage(for: 4)]
        config.defaultWidth = config.widthVariants.first?.key ?? 0.0
        
        config.imageProvider = { item in
            return ImageProvider.shared.drawImage(color: item.color,
                                                  width: item.width,
                                                  attributeImage: attributeVC.attributeModel.selectedAttribute.image)
        }
        config.viewControllerProvider = { item in
            attributeVC.attributeModel.color = item.color
            attributeVC.reload()
            return attributeVC
        }
        
        toolItem = PKToolPickerCustomItem(configuration: config)
        
        attributeViewController.attributeModel.selectedAttributeDidChange = { [weak self] _ in
            self?.toolItem.reloadImage()
            self?.attributeViewController.reload()
        }
    }
    
    static private func makeWidthVariantImage(for index: Int) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 32, height: 32))
        return renderer.image { context in
            let cgContext = context.cgContext
            
            let diameter: CGFloat = 5 + (4 * CGFloat(index))
            let origin: CGFloat = (32 - diameter) / 2.0
            
            cgContext.setStrokeColor(UIColor.black.cgColor)
            cgContext.setLineWidth(2)
            cgContext.strokeEllipse(in: CGRect(x: origin, y: origin, width: diameter, height: diameter))
        }
    }
    
    /// The stamp image for the selected custom tool item.
    func stampImageView(for location: CGPoint, angleInRadians: CGFloat) -> UIImageView? {
        guard let selectedImage = attributeViewController.attributeModel.selectedImage else { return nil }
        let tintedImage = selectedImage.withTintColor(toolItem.color, renderingMode: .alwaysOriginal)
        
        let width = toolItem.width
        let origin = CGPoint(x: location.x - width / 2, y: location.y - width / 2)
        
        let imageView = UIImageView(frame: CGRect(origin: origin, size: CGSize(width: width, height: width)))
        imageView.transform = CGAffineTransformMakeRotation(angleInRadians)
        imageView.contentMode = .scaleAspectFit
        imageView.image = tintedImage
        
        return imageView
    }
}

fileprivate extension AnimalStampWrapper {
    
    /// A model for the attribute view controller for the animal stamp.
    class Model: AttributeViewController.Model {
        init() {
            var symbolAttributes: [(name: String, image: UIImage)] {
                var attributes:[(name: String, image: UIImage)] = []
                let systemNames = ["pawprint.fill", "dog.fill", "cat.fill", "bird.fill", "fish.fill", "ant.fill"]
                for systemName in systemNames {
                    if let image = UIImage(systemName: systemName) {
                        attributes.append((name:systemName, image: image))
                    }
                }
                return attributes
            }
            super.init(attributes: symbolAttributes, selectedAttribute: symbolAttributes.first!, color: .black)
        }
    }

    /// A provider for the tool item.
    class ImageProvider: CustomPickerItemImageProviding {

        var imageName: String
        var bandVerticalOffset: CGFloat
        var opacityLabelVerticalOffset: CGFloat

        init() {
            self.imageName = "StampTool"
            self.bandVerticalOffset = 50
            self.opacityLabelVerticalOffset = 70
        }

        static let shared = ImageProvider()
        
        func adjustedBandHeight(for height: CGFloat, strokeWidth: CGFloat) -> CGFloat {
            let minimumStrokeWidth = 10.0
            let maximumStrokeWidth = 80.0
            let percentAlongWidthRange = (strokeWidth - minimumStrokeWidth) / (maximumStrokeWidth - minimumStrokeWidth)
            let clampedPercentAlongWidthRange = max(min(percentAlongWidthRange, 1.0), 0.0)
            
            let minimumBandThickness = 2.0
            let maximumBandThickness = 8.0
            return minimumBandThickness + (maximumBandThickness - minimumBandThickness) * clampedPercentAlongWidthRange
        }
    }
}
