/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data model and logic for processing the data for the app.
*/

import Foundation

@Observable
class Model {
    var data: [DataPoint]
    var hoveredTime: Date? = nil
    var breakdownField: BreakdownCategory {
        didSet {
            if oldValue != breakdownField {
                sortDataByBreakdown()
            }
        }
    }

    var hoveredYear: Int? { hoveredTime.map { Calendar.current.component(.year, from: $0) } }

    init(
        data: [DataPoint] = [],
        hoveredYear: String? = nil,
        breakdownField: BreakdownCategory = .axisType
    ) {
        self.data = data
        self.breakdownField = breakdownField

        sortDataByBreakdown()
    }

    private func sortDataByBreakdown() {
        // `.foregroundStyle` is often based on breakdown; sorting minimizes style changes.
        let keyPath = breakdownField.keyPath
        self.data = data.sorted { $0[keyPath: keyPath] < $1[keyPath: keyPath] }
    }

    func loadSampleData() throws {
        data = try DataPoint.csvData()
    }

    var filteredData: [DataPoint] {
        if let year = hoveredYear {
            data.filter { $0.startYear == year }
        } else {
            data
        }
    }
}

let startYear = 2005
let endYear = 2021

let timeDomain: ClosedRange<Date> = {
    let domainStart = dateFromYear(startYear) // round year, and shows zero installations
    let domainEnd = dateFromYear(endYear + 1).addingTimeInterval(-1) // end of 2021
    return domainStart...domainEnd
}()
