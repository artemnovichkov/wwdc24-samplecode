/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A set of charts that demonstrate function graphing using `AreaPlot` and `LinePlot`.
*/

import SwiftUI
import Charts

struct FunctionExamples: View {
    var body: some View {
        #if !os(visionOS)
        CapacityDensityDistribution()
            .squareFunctionExample()
            .dashboardPanel("Distribution of solar panel capacity density")
        #endif

        ParametricFunction()
            .squareFunctionExample()
            .dashboardPanel("Heart")

        DecisionBoundaryPlot()
            .squareFunctionExample()
            .dashboardPanel("Decision boundary plot")

        LimitFunctionSamplingDomain()
            .squareFunctionExample()
            .dashboardPanel("Limit sampling domain")

        NaNRepresentsNoValue()
            .squareFunctionExample()
            .dashboardPanel("Use Double.nan if no value")

        MultipleFunctionPlotsInSameChart()
            .squareFunctionExample()
            .dashboardPanel("Multiple function plots")

        ForEach(examples) { example in
            Chart {
                switch example {
                case let .linePlot(y, function, _, _):
                    LinePlot(x: "x", y: y, function: function)
                case let .areaPlot(y, function, _, _):
                    AreaPlot(x: "x", y: y, function: function)
                case let .areaPlotBetween(yStart, yEnd, function, _, _):
                    AreaPlot(x: "x", yStart: yStart, yEnd: yEnd, function: function)
                case let .parametricLinePlot(_, x, y, tDomain, function, _, _):
                    LinePlot(x: x, y: y, t: "t", domain: tDomain, function: function)
                }
            }
            .chartXScale(domain: example.xDomain)
            .chartYScale(domain: example.yDomain)
            .chartPlotStyle { content in
                content
                    .aspectRatio(
                        CGSize(
                            width: CGFloat(
                                example.xDomain.upperBound - example.xDomain.lowerBound),
                            height: CGFloat(
                                example.yDomain.upperBound - example.yDomain.lowerBound)),
                        contentMode: .fit)
                    .clipped()
            }
            .id(example.id)
            .squareFunctionExample()
            .dashboardPanel {
                Text(example.id)
                    .font(.headline)
            }
        }
    }

    let examples: [FunctionExample] = [
        .parametricLinePlot(
            description: "Butterfly",
            x: "3 * sin(t) * exp(cos(t) - 2 * cos(4t) - sin(t / 12) ^ 5)",
            y: "3 * cos(t) * exp(cos(t) - 2 * cos(4t) - sin(t / 12) ^ 5)",
            tDomain: 0 ... .pi * 12,
            function: { t in
                let r = 3 * (exp(cos(t)) - 2 * cos(4 * t) - pow(sin(t / 12), 5))
                let x = r * sin(t)
                let y = r * cos(t)
                return (x, y)
            }
        ),
        .linePlot(
            y: "x ^ 3 - x",
            function: { x in pow(x, 3) - x },
            xDomain: -3...3, yDomain: -3...3
        ),
        .areaPlot(
            y: "sin(x * 5) / x",
            function: { x in sin(x * 5) / x },
            xDomain: -4...4, yDomain: -2...6
        ),

        .parametricLinePlot(
            description: "Spiral",
            x: "t * cos(t)", y: "t * sin(t)",
            tDomain: 0...10,
            function: { t in (x: t * cos(t), y: t * sin(t)) }
        ),
        .parametricLinePlot(
            description: "Bishop chess piece",
            x: "cos(t) - cos(5 * t)",
            y: "sin(t) - cos(2 * t)",
            tDomain: 0 ... 2 * .pi,
            function: { t in
                (x: cos(t) - cos(5 * t), y: sin(t) - cos(2 * t))
            },
            xDomain: -5...5, yDomain: -5...5
        ),
        .parametricLinePlot(
            description: "Flower",
            x: "9 * cos(5 * t) * cos(t)",
            y: "9 * cos(5 * t) * sin(t)",
            tDomain: 0 ... .pi * 2,
            function: { t in
                (x: 9 * cos(6 * t) * cos(t), y: 9 * cos(6 * t) * sin(t))
            }
        ),
        .parametricLinePlot(
            description: "Fish",
            x: "cos(t) + 5 * cos(2 * t / 3)",
            y: "2 * sin(t)",
            tDomain: 0 ... .pi * 6,
            function: { t in
                (x: cos(t) + 5 * cos(2 * t / 3), y: 2 * sin(t))
            }
        ),
        .parametricLinePlot(
            description: "Donut",
            x: "6 * cos(15 * t) + 2 * cos(t)",
            y: "6 * sin(15 * t) + 2 * sin(t)",
            tDomain: 0 ... .pi * 2,
            function: { t in
                (x: 5 * cos(15 * t) + 3 * cos(t),
                 y: 5 * sin(15 * t) + 3 * sin(t))
            }
        ),
        .parametricLinePlot(
            description: "Star",
            x: "3 * sin(t) - 4.5 * sin(2 / 3 * t)",
            y: "3 * cos(t) + 4.5 * cos(2 / 3 * t)",
            tDomain: 0 ... .pi * 6,
            function: { t in
                let x = 3 * sin(t) - 4.5 * sin(2 / 3 * t)
                let y = 3 * cos(t) + 4.5 * cos(2 / 3 * t)
                return (x, y)
            }
        ),

        .areaPlotBetween(
            yStart: "sin(x)", yEnd: "cos(x)",
            function: { x in (yStart: sin(x), yEnd: cos(x)) }
        ),
        .areaPlotBetween(
            yStart: "x", yEnd:  "x * x - 1",
            function: { x in (yStart: x, yEnd: x * x - 1) },
            xDomain: -5...5, yDomain: -5...5
        ),

        .linePlot(y: "cos(x)", function: cos),
        .linePlot(y: "tan(x)", function: { tan($0) }),
        .linePlot(y: "4 * sqrt(sin(3 * x) + cos(x))", function: { x in 4 * sqrt(sin(3 * x) + cos(x)) }),
        .linePlot(y: "5 * exp(-x * x / 5) * cos(x * 5)", function: { x in 5 * exp(-x * x / 5) * cos(x * 5) }),
        .linePlot(y: "sin(x * 5) / x", function: { x in sin(x * 5) / x }),
        .linePlot(y: "x / sin(x * 2)", function: { x in x / sin(x * 2) }),
        .linePlot(y: "sin(x) > 0 ? 1 : -1", function: { x in sin(x) > 0 ? 1 : -1 }),
        .linePlot(y: "x.rounded()", function: { x in x.rounded() }),
        .linePlot(y: "x * sin(20 / x)", function: { x in x * sin(20 / x) }),

        .areaPlot(y: "x", function: { x in x }),
        .areaPlot(y: "sin(x)", function: { x in sin(x) }),
        .areaPlot(y: "tan(x)", function: { x in tan(x) }),
        .areaPlot(y: "sqrt(x)", function: { x in sqrt(x) }),
        .areaPlot(y: "4 * sqrt(sin(3 * x) + cos(x))", function: { x in 4 * sqrt(sin(3 * x) + cos(x)) }),
        .areaPlot(y: "5 * exp(-x * x / 5) * cos(x * 5)", function: { x in 5 * exp(-x * x / 5) * cos(x * 5) }),
        .areaPlot(y: "sin(x) > 0 ? 1 : -1", function: { x in sin(x) > 0 ? 1 : -1 }),
        .areaPlot(y: "x.rounded()", function: { x in x.rounded() }),
        .areaPlot(y: "x * sin(20 / x)", function: { x in x * sin(20 / x) })
    ]
}

extension View {
    func squareFunctionExample() -> some View {
        self.aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(traits: .sampleData) {
    ScrollView {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 200, maximum: 400), spacing: 8, alignment: .topLeading)
        ]) {
            FunctionExamples()
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding()
    }
    .scrollBounceBehavior(.basedOnSize)
}
