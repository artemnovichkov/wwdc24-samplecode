/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A chart that shows an elliptical decision boundary.
*/

import SwiftUI
import Charts

struct DecisionBoundaryPlot: View {
    private let aspectRatio = 1.0
    private let minY = -2.0
    private let maxY = 6.0
    private var minX: Double { -aspectRatio * (maxY - minY) / 4 }
    private var maxX: Double { 3 * aspectRatio * (maxY - minY) / 4 }

    private let xc = 2.1
    private let yc = 2.5
    private let r0 = 3.6
    private let r1 = 1.8
    private let alpha = 0.12 * .pi

    private let sampleCount = 200
    private let baseProbability = 0.3 // increase it to make misclassification less likely
    private let tightness = 0.8 // increase it to make misclassifications occur at the perimeter only

    enum Category: String, CaseIterable, Equatable, Plottable {
        case c1 = "Category 1"
        case c2 = "Category 2"
    }

    struct Element {
        var x, y: Double
        var category: Category

        var opacity: CGFloat { category == .c1 ? 0.6 : 0.8 }
    }

    var data: [Element] {
        (0..<sampleCount).map { _ in
            let x: Double = .random(in: minX...maxX) - xc
            let y: Double = .random(in: minY...maxY) - yc
            let a = x * cos(-alpha) - y * sin(-alpha)
            let b = x * sin(-alpha) + y * cos(-alpha)
            let unitA = a / r0
            let unitB = b / r1
            let distance = unitA * unitA + unitB * unitB
            let isInEllipsis = distance <= 1.0
            let noise = Double.random(in: 0...1) < (baseProbability + abs(tightness * (distance - 1.0)))
            let category = Category.allCases[isInEllipsis != noise ? 0 : 1] // != is xor
            return .init(x: x + xc, y: y + yc, category: category)
        }
    }

    var body: some View {
        Chart {
            RuleMark(x: .value("Y axis", 0))
                .foregroundStyle(Color.secondary)
            RuleMark(y: .value("X axis", 0))
                .foregroundStyle(Color.secondary)

            PointPlot(
                data,
                x: .value("X", \.x),
                y: .value("Y", \.y)
            )
            .symbol(by: .value("Category", \.category))
            .foregroundStyle(by: .value("Category", \.category))
            .opacity(\.opacity)

            LinePlot(
                x: "X", y: "Y",
                t: "Boundary curve independent variable", domain: 0 ... 2.0 * .pi
            ) { t in
                let a = r0 * cos(t)
                let b = r1 * sin(t)
                let x = xc + a * cos(alpha) - b * sin(alpha)
                let y = yc + a * sin(alpha) + b * cos(alpha)
                return (x, y)
            }
            .lineStyle(.init(lineWidth: 1, lineCap: .round, dash: [7, 7]))
            .foregroundStyle(.white)
        }
        .chartXScale(domain: minX...maxX)
        .chartYScale(domain: minY...maxY)
        .chartSymbolScale(domain: Category.allCases.reversed())
        .chartForegroundStyleScale(domain: Category.allCases)
        .chartPlotStyle { content in
            content
                .aspectRatio(aspectRatio, contentMode: .fit)
        }
    }
}

#Preview {
    DecisionBoundaryPlot()
        .padding()
}
