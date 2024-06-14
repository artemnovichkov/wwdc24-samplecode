/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Data categories for the breakdown panel.
*/

enum BreakdownCategory: CaseIterable, Identifiable, CustomStringConvertible {
    case axisType
    case technology
    case state

    var id: Self { self }

    var keyPath: KeyPath<DataPoint, String> {
        switch self {
        case .axisType: \.panelAxisType
        case .technology: \.tech
        case .state: \.state
        }
    }

    var description: String {
        switch self {
        case .axisType:
            String(localized: "Axis Type")
        case .technology:
            String(localized: "Technology")
        case .state:
            String(localized: "State")
        }
    }

    var domain: [String] {
        switch self {
        case .axisType: [
            "single-axis", "fixed-tilt", "fixed-tilt,single-axis",
            "dual-axis", "fixed-tilt,single-axis,dual-axis", "unknown"
        ]
        case .technology: [
            "c-si", "thin-film", "cpv", "c-si,thin-film", "c-si,cpv", "c-si,thin-film,cpv", "unknown"
        ]
        case .state: [
            // The top 10 states get colors that are distinct among them.
            "NC", "CA", "MN", "MA", "NY", "NJ", "OR", "TX", "CO", "GA",
            "AL", "AR", "AZ", "CT", "DC", "DE", "FL", "IA", "ID", "IL", "IN", "KS", "KY",
            "LA", "MD", "ME", "MI", "MO", "MS", "MT", "ND", "NE", "NH", "NM", "NV", "OH",
            "OK", "PA", "RI", "SC", "SD", "TN", "UT", "VA", "VT", "WA", "WI", "WY", "WV"
        ]
        }
    }
}
