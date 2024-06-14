/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The top-level view that creates all the demos for the app.
*/

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ViewTranslationView()
                    } label: {
                        RowView(title: "Translate Text",
                                subtitle: "Translate a single phrase.",
                                imageName: "arrow.left.arrow.right")
                    }

                    NavigationLink {
                        ReplaceTranslationView()
                    } label: {
                        RowView(title: "Replace Text",
                                subtitle: "Replace text with the translated result.",
                                imageName: "arrow.circlepath")
                    }
                } header: {
                    Text("System UI Translations")
                }

                Section {
                    NavigationLink {
                        SingleStringView()
                    } label: {
                        RowView(title: "Single String",
                                subtitle: "Translate a single string of text.",
                                imageName: "arrow.left.arrow.right")
                    }
                    
                    NavigationLink {
                        BatchOfStringsView()
                    } label: {
                        RowView(title: "Batch All at Once",
                                subtitle: "Translate a batch of strings.",
                                imageName: "line.3.horizontal")
                    }

                    NavigationLink {
                        BatchAsSequenceView()
                    } label: {
                        RowView(title: "Batch as a Sequence",
                                subtitle: "Translate strings as a sequence.",
                                imageName: "line.3.horizontal.decrease")
                    }
                } header: {
                    Text("Custom UI Translations")
                }
                
                Section {
                    NavigationLink {
                        LanguageAvailabilityView()
                    } label: {
                        RowView(title: "Language Availability",
                                subtitle: "Check whether a translation can occur.",
                                imageName: "lightswitch.on")
                    }

                    NavigationLink {
                        PrepareTranslationView()
                    } label: {
                        RowView(title: "Prepare for Translation",
                                subtitle: "Initiate a language download.",
                                imageName: "arrow.down.circle")
                    }
                } header: {
                    Text("Availability")
                }
            }
            .navigationTitle("Translation Demos")
        }
    }
}

#Preview {
    ContentView()
}
