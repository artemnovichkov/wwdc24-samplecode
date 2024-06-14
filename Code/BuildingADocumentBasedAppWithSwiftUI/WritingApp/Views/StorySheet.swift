/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The sheet view that appears when reading.
*/

import SwiftUI

struct StorySheet: View {
    var story: String
    @Binding var isShowingSheet: Bool

    var body: some View {
        NavigationStack {
            VStack {
                #if os(macOS)
                HStack {
                    Spacer()
                    DismissButton(isShowingSheet: $isShowingSheet)
                        .buttonStyle(.borderless)
                        .padding()
                }
                #endif
                ScrollView {
                    VStack {
                        Text(story)
                            .font(.system(.body, design: .serif, weight: .regular))
                            .foregroundStyle(Color.brandDarkBlue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 50)
                }
            }
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DismissButton(isShowingSheet: $isShowingSheet)
                }
            }
            .toolbarBackgroundVisibility(.hidden)
            .navigationBarBackButtonHidden()
            #endif
            .background(Color.brandLightBlue)
        }
    }
}

struct DismissButton: View {
    @Binding var isShowingSheet: Bool

    var body: some View {
        Button {
            isShowingSheet.toggle()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .frame(width: 20, height: 20)
                .foregroundColor(Color.brandLightBlue)
                .background(Color.brandDarkBlue)
                .cornerRadius(26)
        }
    }
}

#Preview {
    StorySheet(story: "", isShowingSheet: .constant(true))
}
