/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to convert an interstitial event created from a JSON menu to an AVPlayer interstitial event object.
*/
import AVFoundation
import Foundation
import os

extension InterstitialEvent {

    func asAVFInterstitialEvent(
        with playerItem: AVPlayerItem,
        sequenceRepeatCount: Int = 1,
        primaryAssetIdentifier: UUID,
        queue: DispatchQueue
    ) -> AVPlayerInterstitialEvent? {

		func urlAssert(for url: URL) -> AVURLAsset {
            let asset = AVURLAsset(url: url, options: [ AVURLAssetPrimarySessionIdentifierKey: primaryAssetIdentifier ])
            return asset
        }

        // Check that there's a valid start time or cue.
        guard startTime != nil || cue != nil else {
            Logger.general.error("Could not schedule interstitial event with urls \(urls). Must provide a start time or cue.")
            return nil
        }

        // Get the asset URLs and create the player asset and item.
        let totalSequenceURLs = Array(repeating: urls, count: sequenceRepeatCount).flatMap { $0 }
        
        let interstitialPlayerItems = totalSequenceURLs.map { interstitialURL in
			let interstitialAsset = urlAssert(for: interstitialURL)

            return AVPlayerItem(asset: interstitialAsset)
        }

        // Create the interstitial event.
        let event = AVPlayerInterstitialEvent(
            primaryItem: playerItem,
            identifier: UUID().uuidString,
            time: startTime?.asCMTime() ?? .zero,
            templateItems: interstitialPlayerItems,
            restrictions: [],
            resumptionOffset: resumptionOffset?.asCMTime() ?? .zero,
            playoutLimit: playoutLimit?.asCMTime(bounded: 0.0...TimeInterval.infinity) ?? .invalid
        )
        
        // Set the interstitial event properties.
        event.cue = cue ?? .noCue
		event.willPlayOnce = willPlayOnce ?? false
        
        event.timelineOccupancy = timelineOccupancy ?? .singlePoint
        event.supplementsPrimaryContent = supplementsPrimary ?? false
        event.contentMayVary = contentMayVary ?? true
		event.plannedDuration = plannedDuration?.asCMTime() ?? .invalid

        return event
    }
}
