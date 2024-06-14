/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data model for function examples.
*/

import SwiftUI

enum FunctionExample: Identifiable {
    case linePlot(
        y: String,
        function: @Sendable (Double) -> Double,
        xDomain: ClosedRange<Double> = -10...10,
        yDomain: ClosedRange<Double> = -10...10
    )
    case areaPlot(
        y: String,
        function: @Sendable (Double) -> (Double),
        xDomain: ClosedRange<Double> = -10...10,
        yDomain: ClosedRange<Double> = -10...10
    )
    case areaPlotBetween(
        yStart: String, yEnd: String,
        function: @Sendable (Double) -> (Double, Double),
        xDomain: ClosedRange<Double> = -10...10,
        yDomain: ClosedRange<Double> = -10...10
    )
    case parametricLinePlot(
        description: String,
        x: String, y: String, tDomain: ClosedRange<Double>,
        function: @Sendable (Double) -> (Double, Double),
        xDomain: ClosedRange<Double> = -10...10,
        yDomain: ClosedRange<Double> = -10...10
    )

    var id: String {
        switch self {
        case .linePlot(let y, _, _, _):
            "y = \(y)"
        case .areaPlot(let y, _, _, _):
            "yEnd = \(y)"
        case .areaPlotBetween(let yStart, let yEnd, _, _, _):
            "yStart = \(yStart), yEnd = \(yEnd)"
        case .parametricLinePlot(let description, _, _, _, _, _, _):
            description
        }
    }

    var xDomain: ClosedRange<Double> {
        switch self {
        case .linePlot(_, _, let xDomain, _):
            xDomain
        case .areaPlot(_, _, let xDomain, _):
            xDomain
        case .areaPlotBetween(_, _, _, let xDomain, _):
            xDomain
        case .parametricLinePlot(_, _, _, _, _, let xDomain, _):
            xDomain
        }
    }

    var yDomain: ClosedRange<Double> {
        switch self {
        case .linePlot(_, _, _, let yDomain):
            yDomain
        case .areaPlot(_, _, _, let yDomain):
            yDomain
        case .areaPlotBetween(_, _, _, _, let yDomain):
            yDomain
        case .parametricLinePlot(_, _, _, _, _, _, let yDomain):
            yDomain
        }
    }
}
