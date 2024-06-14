/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Additional methods that help format the strings that return as part of a search completion.
*/

import Foundation
import MapKit

/// - Tag: HighlightFragment
extension MKLocalSearchCompletion {
    
    /**
     Each `MKLocalSearchCompletion` contains a title and a subtitle, as well as ranges describing what part of the title or
     subtitle match the current query string. Use the ranges to apply helpful highlighting of the text in the completion suggestion
     that matches the current query fragment.
     */
    private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
        let attributes = [NSAttributedString.Key.backgroundColor: UIColor(named: "suggestionHighlight")!]
        let highlightedString = NSMutableAttributedString(string: text)

        // Each `NSValue` wraps an `NSRange` that functions as a style attribute's range with `NSAttributedString`.
        let ranges = rangeValues.map { $0.rangeValue }
        for range in ranges {
            highlightedString.addAttributes(attributes, range: range)
        }

        return highlightedString
    }
    
    var highlightedTitleStringForDisplay: NSAttributedString {
        return createHighlightedString(text: title, rangeValues: titleHighlightRanges)
    }
    
    var highlightedSubtitleStringForDisplay: NSAttributedString {
        return createHighlightedString(text: subtitle, rangeValues: subtitleHighlightRanges)
    }
}
