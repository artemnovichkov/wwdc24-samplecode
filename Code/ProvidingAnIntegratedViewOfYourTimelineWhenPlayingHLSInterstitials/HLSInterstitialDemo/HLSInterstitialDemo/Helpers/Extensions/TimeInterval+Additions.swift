/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to return a Core Media time from the time interval.
*/
import CoreMedia
import Foundation

extension TimeInterval {

    func asCMTime(bounded bounds: any RangeExpression<Self> = -.infinity...infinity, timescale: CMTimeScale = 1_000_000) -> CMTime {
        guard bounds.contains(self) else { return .invalid }
        return CMTime(seconds: self, preferredTimescale: timescale)
    }
}
