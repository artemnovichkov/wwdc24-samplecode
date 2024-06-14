/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data model for the sample data for the app.
*/

import TabularData
import SwiftUI

struct SampleData: PreviewModifier {
    static func makeSharedContext() throws -> Model {
        let model = Model()
        try model.loadSampleData()
        return model
    }

    func body(content: Content, context: Model) -> some View {
        content.environment(context)
    }
}

extension DataPoint {
    /// Load and parse the CSV data.
    static func csvData() throws -> [DataPoint] {
        guard let filePath = Bundle.main
            .url(forResource: "uspvdb_v1_0_20231108", withExtension: "csv")
        else {
            throw CocoaError(.fileNoSuchFile)
        }

        return try DataFrame(csvData: try Data(contentsOf: filePath)).rows.enumerated().compactMap { index, row in
            let area = row["p_area"] as! Int
            let state = row["p_state"] as! String
            let capacityAC = row["p_cap_ac"] as! Double
            let capacityDC = row["p_cap_dc"] as! Double
            let startYear = row["p_year"] as! Int
            if startYear < 2005 || capacityAC + capacityDC < 1 || area < 1 || state == "HI" {
                return nil
            }
            return DataPoint(
                index: index,
                id: row["eia_id"] as! Int,
                name: row["p_name"] as! String,
                state: state,
                area: area,
                startYear: startYear,
                capacityAC: capacityAC,
                capacityDC: capacityDC,
                panelAxisType: row["p_axis"] as? String ?? "unknown",
                tech: row["p_tech_sec"] as? String ?? "unknown",
                xLongitude: Angle(degrees: row["xlong"] as! Double),
                yLatitude: Angle(degrees: row["ylat"] as! Double)
            )
        }
    }
}

extension PreviewTrait<Preview.ViewTraits> {
    static var sampleData: Self {
        modifier(SampleData())
    }
}
