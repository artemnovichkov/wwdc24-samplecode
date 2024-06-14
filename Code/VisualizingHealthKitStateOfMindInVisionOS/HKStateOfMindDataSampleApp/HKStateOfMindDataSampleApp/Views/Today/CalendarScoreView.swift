/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Visualizes a score (out of 100) with speedometer styling, indicating how *good* (close to 100) the score is.
*/

import SwiftUI

/// Visualizes a score from 0 to 100, with values closer to 100 being the better scores.
struct CalendarScoreView: View {
    
    let score: Int
    
    var strokeBackgroundColor = Defaults.backgroundColor
    
    private let startFraction = 0.5
    private let desiredWidth = 100.0
    private let strokeWidth = 20.0
    
    var body: some View {
        ZStack {
            gaugeView
            scoreView
                .padding(.top, desiredWidth / 3)
        }
    }
    
    @ViewBuilder
    private var gaugeView: some View {
        ZStack {
            Circle()
                .trim(from: startFraction, to: 1.0)
                .stroke(strokeBackgroundColor,
                        style: StrokeStyle(lineWidth: strokeWidth,
                                           lineCap: .round))
            Circle()
                .trim(from: startFraction, to: endFraction)
                .stroke(AngularGradient(gradient: Gradient(colors: colors),
                                        center: .center),
                        style: StrokeStyle(lineWidth: strokeWidth,
                                           lineCap: .round))
        }
        .padding(.bottom, -(desiredWidth / 3))
        .frame(width: desiredWidth)
    }
    
    @ViewBuilder
    private var scoreView: some View {
        Text("\(score)")
            .font(.largeTitle)
            .fontDesign(.rounded)
            .fontWeight(.bold)
    }
    
    private var colors: [Color] {
        if score < 35 {
            return Defaults.badColors
        } else if score < 65 {
            return Defaults.okayColors
        } else {
            return Defaults.goodColors
        }
    }
    
    private var endFraction: Double {
        let maxFill = 1 - startFraction
        let percentFill = Double(score) / 100.0
        let fillFromStart = maxFill * percentFill
        return startFraction + fillFromStart
    }
    
    enum Defaults {
        static let badColors = [Color.red, .orange]
        static let okayColors = [Color.orange, .yellow]
        static let goodColors = [Color.yellow, .green]
        static let backgroundColor = Color(UIColor.secondarySystemFill)
    }
}

// MARK: - Previews

#Preview("Calendar Score View 1") {
    ZStack {
        Color.blue
        CalendarScoreView(score: 55)
    }
    .frame(width: 400, height: 400, alignment: .center)
    .cornerRadius(32)
}

#Preview("Calendar Score View 2") {
    ZStack {
        Color.blue
        CalendarScoreView(score: 55,
                          strokeBackgroundColor: .white)
    }
    .frame(width: 400, height: 400, alignment: .center)
    .cornerRadius(32)
}
