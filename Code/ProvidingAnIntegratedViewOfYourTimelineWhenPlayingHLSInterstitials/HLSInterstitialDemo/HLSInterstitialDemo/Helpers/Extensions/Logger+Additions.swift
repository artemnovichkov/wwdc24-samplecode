/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An extension to log general output with a specified subsystem.
*/
import os

extension Logger {
    
    static let general = Logger(subsystem: "com.example.apple-samplecode.HLSInterstitialDemo", category: "General")
}
