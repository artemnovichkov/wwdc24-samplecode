/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to help create an interstitial event object from JSON menu values.
*/
import AVFoundation
import Foundation

enum EventStart: CustomStringConvertible {
    case date(Date)
    case time(TimeInterval)

    var description: String {
        switch self {
        case .date(let date):
            date.description
        case .time(let time):
            time.description
        }
    }
}

extension AVPlayerInterstitialEvent {

    convenience init(
        identifier: String,
        primaryItem: AVPlayerItem,
        start: EventStart,
        interstitialItems: [AVPlayerItem],
        restrictions: Restrictions,
        resumptionOffset: CMTime,
        playoutLimit: CMTime
    ) {
        switch start {
        case .date(let date):
            self.init(
                primaryItem: primaryItem,
                identifier: identifier,
                date: date,
                templateItems: interstitialItems,
                restrictions: restrictions,
                resumptionOffset: resumptionOffset,
                playoutLimit: playoutLimit
            )
            
        case .time(let time):
            self.init(
                primaryItem: primaryItem,
                identifier: identifier,
                time: time.asCMTime(),
                templateItems: interstitialItems,
                restrictions: restrictions,
                resumptionOffset: resumptionOffset,
                playoutLimit: playoutLimit
            )
        }
    }
}
