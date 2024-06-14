/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A structure that represents a row in a view.
*/

import SwiftUI

struct RowView: View {
    let title: String
    let subtitle: String
    let imageName: String
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
                .font(.title2)
                .foregroundColor(.accentColor)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    RowView(title: "SwiftUI",
            subtitle: "A SwiftUI control for translation",
            imageName: "swift")
}
