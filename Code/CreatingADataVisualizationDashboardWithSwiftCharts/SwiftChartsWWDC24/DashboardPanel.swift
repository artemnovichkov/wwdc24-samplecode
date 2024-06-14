/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The panel that contains the dashboard content.
*/

import SwiftUI

private struct DashboardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content
        }
    }
}

private func panelMaterial(darker: Bool) -> some ShapeStyle {
    if darker {
        return AnyShapeStyle(.black.opacity(0.8))
    }
    #if os(macOS)
    return AnyShapeStyle(.regularMaterial.blendMode(.hardLight))
    #elseif os(visionOS)
    return AnyShapeStyle(.thickMaterial.blendMode(.hardLight))
    #else
    return AnyShapeStyle(.regularMaterial)
    #endif
}

extension View {
    func dashboardPanel(
        darker: Bool = false, @ViewBuilder label: () -> some View = { EmptyView() }
    ) -> some View {
        GroupBox(label: label()) {
            self
                .padding(16)
                .background(panelMaterial(darker: darker), in: .rect(cornerRadius: 16))
        }
        .groupBoxStyle(DashboardGroupBoxStyle())
    }

    func dashboardPanel(_ label: LocalizedStringKey, darker: Bool = false) -> some View {
        dashboardPanel(darker: darker) {
            Text(label)
                .font(.headline)
        }
    }
}

#Preview {
    Text("Content")
        .dashboardPanel("Title")
}
