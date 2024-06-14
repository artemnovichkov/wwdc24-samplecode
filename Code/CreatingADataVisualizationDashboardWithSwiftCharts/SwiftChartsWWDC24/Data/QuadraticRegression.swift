/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Quadratic regression function for the scatterplot panel.
*/

import Foundation

struct QuadraticRegression: Sendable {
    /// Coefficients `a`, `b` and `c` as in `f(x) = ax^2 + bx + c`.
    let a, b, c: Double

    var coefficientCount: Int { 3 }

    init(a: Double, b: Double, c: Double) {
        self.a = a
        self.b = b
        self.c = c
    }

    init<Data: RandomAccessCollection>(
        _ data: Data,
        x xPath: KeyPath<Data.Element, Double>,
        y yPath: KeyPath<Data.Element, Double>
    ) {
        var sx: Double = 0, sx2: Double = 0, sx3: Double = 0, sx4: Double = 0
        var sy: Double = 0, sxy: Double = 0, sx2y: Double = 0
        let n = Double(data.count)

        for d in data {
            let (x, y) = (d[keyPath: xPath], d[keyPath: yPath])
            let x2 = x * x
            sx += x
            sx2 += x2
            sx3 += x * x2
            sx4 += x2 * x2
            sy += y
            sxy += x * y
            sx2y += x2 * y
        }

        let sXX = sx2 - sx * sx / n
        let sXY = sxy - sx * sy / n
        let sXX2 = sx3 - sx2 * sx / n
        let sX2Y = sx2y - sx2 * sy / n
        let sX2X2 = sx4 - sx2 * sx2 / n

        let a = (sX2Y * sXX - sXY * sXX2) / (sXX * sX2X2 - sXX2 * sXX2)
        let b = (sXY * sX2X2 - sX2Y * sXX2) / (sXX * sX2X2 - sXX2 * sXX2)
        let c = (sy - b * sx - a * sx2) / n

        self.init(a: a, b: b, c: c)
    }

    func callAsFunction(_ x: Double) -> Double {
        a * x * x + b * x + c
    }
}

struct ConfidenceInterval {
    var regression: QuadraticRegression
    var dataCount: Int
    var degreeOfFreedom: Int
    var meanX: Double
    var sumOfSquareDifferences: Double
    var squareOfStandardError: Double
    var criticalValue: Double

    init<Data: RandomAccessCollection>(
        data: Data,
        x xPath: KeyPath<Data.Element, Double>,
        y yPath: KeyPath<Data.Element, Double>,
        regression: QuadraticRegression
    ) {
        self.regression = regression
        self.dataCount = data.count
        self.degreeOfFreedom = dataCount - regression.coefficientCount

        self.meanX = data.reduce(0) { sum, d in sum + d[keyPath: xPath] } / Double(data.count)

        self.sumOfSquareDifferences = data.reduce(0) { [meanX] partialResult, d in
            let actual = d[keyPath: xPath]
            let error = actual - meanX
            return partialResult + error * error
        }

        let sumOfSquareErrors = data.reduce(0) { sumOfSquareErrors, d in
            let actual = d[keyPath: yPath]
            let predicted = regression(d[keyPath: xPath])
            let error = actual - predicted
            return sumOfSquareErrors + error * error
        }
        self.squareOfStandardError = sumOfSquareErrors / Double(degreeOfFreedom)

        // Approximation for a 99% confidence level for up to ~100 data points, after which the curve is flatter.
        self.criticalValue = Double(3.53 + 0.2125 * log(Double(min(degreeOfFreedom, 100))))
    }

    func callAsFunction(_ x: Double) -> (yStart: Double, yEnd: Double) {
        let predicted = regression(x)
        if degreeOfFreedom <= 0 {
            return (-.infinity, .infinity)
        }
        let difference = x - meanX
        let variance = squareOfStandardError * (Double(1 / dataCount) +
            (difference * difference) / sumOfSquareDifferences)
        let offset = criticalValue * sqrt(variance)
        return (predicted + offset, predicted - offset)
    }
}
