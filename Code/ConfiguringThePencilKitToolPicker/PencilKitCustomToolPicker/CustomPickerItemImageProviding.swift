/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A protocol that defines the variables and methods to provide images for a custom tool item.
*/

import PencilKit
import UIKit

@MainActor protocol CustomPickerItemImageProviding {
    var imageName: String { get }
    var bandVerticalOffset: CGFloat { get }
    var opacityLabelVerticalOffset: CGFloat { get }
    func adjustedBandHeight(for height: CGFloat, strokeWidth: CGFloat) -> CGFloat
}

extension CustomPickerItemImageProviding {
    // Base image
    var baseImageName: String { "\(imageName)/Base" }
    var baseImage: UIImage? { UIImage(named: baseImageName) }

    // Tip mask
    var tipMaskName: String { "\(imageName)/TipMask" }
    var tipMaskImage: UIImage? { UIImage(named: tipMaskName) }

    // Tip contour
    var tipContourName: String { "\(imageName)/TipContour" }
    var tipContourImage: UIImage? { UIImage(named: tipContourName) }

    // Band mask
    var bandMaskName: String { "\(imageName)/BandMask" }
    var bandMaskImage: UIImage? { UIImage(named: bandMaskName) }

    // Band contour
    var bandContourName: String { "\(imageName)/BandContour" }
    var bandContourImage: UIImage? { UIImage(named: bandContourName) }

    /// Returns the adjusted height for the band.
    func adjustedBandHeight(for height: CGFloat, strokeWidth: CGFloat) -> CGFloat { height }

    /// Draws an image for a tool with the given parameters.
    func drawImage(color: UIColor? = nil, width: CGFloat = 0.0, attributeImage: UIImage? = nil) -> UIImage {
        guard let baseImage else {
            return UIImage()
        }

        let renderer = UIGraphicsImageRenderer(size: baseImage.size)
        return renderer.image { _ in
            let baseImageFrame = CGRect(origin: .zero, size: baseImage.size)
            baseImage.draw(in: baseImageFrame)

            let toolColor = color
            let opaqueColor = toolColor?.withAlphaComponent(1.0)

            if let tipMaskImage, let tipContourImage {
                var tintedTipMaskImage = tipMaskImage
                if let opaqueColor {
                    tintedTipMaskImage = tipMaskImage.withTintColor(opaqueColor)
                }
                tintedTipMaskImage.draw(in: baseImageFrame)

                tipContourImage.draw(in: baseImageFrame)
            }

            if let bandMaskImage, let bandContourImage {
                var tintedBandMaskImage = bandMaskImage
                if let opaqueColor {
                    tintedBandMaskImage = bandMaskImage.withTintColor(opaqueColor)
                }
                let bandHeight = adjustedBandHeight(for: tintedBandMaskImage.size.height, strokeWidth: width)

                let bandMaskFrame = CGRect(origin: CGPoint(x: 0,
                                                           y: bandVerticalOffset),
                                                        size: CGSize(width: tintedBandMaskImage.size.width,
                                                      height: bandHeight))
                tintedBandMaskImage.draw(in: bandMaskFrame)

                bandContourImage.draw(in: bandMaskFrame)
            }

            let opacityLabel = UILabel()
            opacityLabel.clipsToBounds = false
            opacityLabel.font = UIFont.boldSystemFont(ofSize: 8.0)
            opacityLabel.textColor = UIColor.secondaryLabel

            if let toolColor {
                var inkColorAlpha: CGFloat = 0
                toolColor.getWhite(nil, alpha: &inkColorAlpha)

                let opacity = UInt8(round(inkColorAlpha * 100))
                if (opacity >= 0) && (opacity <= 99) {
                    let opacityText = String.localizedStringWithFormat("%ld", opacity)
                    opacityLabel.text = opacityText
                } else {
                    opacityLabel.text = ""
                }

                opacityLabel.sizeToFit()

                var opacityLabelDrawingFrame = opacityLabel.frame
                opacityLabelDrawingFrame.origin.x = ((baseImage.size.width - opacityLabel.frame.size.width) / 2.0)
                opacityLabelDrawingFrame.origin.y = opacityLabelVerticalOffset
                opacityLabel.drawText(in: opacityLabelDrawingFrame)
            }

            if let attributeImage {
                let symbolWidth = 15.0
                let imageOrigin = CGPoint(x: ((baseImage.size.width - symbolWidth) / 2.0), y: 27.0)
                let imageBounds = CGRect(origin: imageOrigin, size: CGSize(width: symbolWidth, height: symbolWidth))
                var symbolImage = attributeImage
                if let opaqueColor {
                    symbolImage = attributeImage.withTintColor(opaqueColor, renderingMode: .alwaysOriginal)
                }
                symbolImage.draw(in: imageBounds)
            }
        }
    }
}
