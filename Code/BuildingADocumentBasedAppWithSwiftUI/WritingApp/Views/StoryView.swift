/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary entry point for the app's user interface.
*/

import SwiftUI

struct StoryView: View {
    @Binding var document: WritingAppDocument
    @State private var isShowingSheet = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack {
            TextEditor(text: $document.story)
                .font(.title)
                .textEditorStyle(.plain)
                .scrollIndicators(.never)
                .onAppear {
                    self.isFocused = true
                }
                .focused($isFocused)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 20)
        .background(.background)
        .scrollClipDisabled()
        .clipShape(RoundedRectangle(cornerRadius: 13))
        .shadow(color: .black.opacity(0.2), radius: 5)
        #if os(macOS)
        .padding(.horizontal, 30)
        #else
        .frame(maxWidth: 700)
        #endif
        .frame(maxWidth: .infinity)
        .padding()
        .background {
            Image(.pinkJungle)
                .resizable()
                .ignoresSafeArea()
                .frame(maxWidth: .infinity)
        }
        .toolbar {
            ToolbarItem() {
                Button("Show Story", systemImage: "book") {
                    isShowingSheet.toggle()
                }
                .sheet(isPresented: $isShowingSheet) {
                    StorySheet(story: document.story, isShowingSheet: $isShowingSheet)
                        .presentationSizing(.page)
                }
            }
        }
    }
}

#Preview {
    StoryView(document: .constant(WritingAppDocument()))
}
