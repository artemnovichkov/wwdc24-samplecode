/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that provides the UI for interacting with the main model.
*/

import SwiftUI
import CoreAudio

struct ContentView: View {
    
    enum ListType: CaseIterable {
        case processes
        case taps
        case aggregates
    }
    
    @EnvironmentObject private var model: Model
    @State private var selection: ListType? = .processes
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: ListType.processes) {
                    Label("Audio Processes", systemImage: "apple.terminal.on.rectangle")
                }
                NavigationLink(value: ListType.taps) {
                    Label("Audio Taps", systemImage: "waveform")
                }
                NavigationLink(value: ListType.aggregates) {
                    Label("Aggregate Devices", systemImage: "hifispeaker.2.fill")
                }
            }
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } content: {
            switch selection ?? .processes {
            case .processes:
                List($model.audioProcessList, selection: $model.processSelection) { $process in
                    NavigationLink {
                        AudioProcessView(process: process)
                    } label: {
                        HStack {
                            Text(String(process.pid))
                                .font(.headline)
                            Text(process.name)
                        }
                    }
                }
            case .taps:
                List($model.audioTapList, selection: $model.tapSelection) { $tap in
                    NavigationLink {
                        AudioTapView(tap: tap)
                    } label: {
                        HStack {
                            Text(String(tap.id))
                                .font(.headline)
                            Text(tap.config.name)
                        }
                    }
                }
                HStack {
                    NavigationLink {
                        VStack {
                            Spacer()
                            Button(action: model.createTap) {
                                Text("Create Tap")
                            }
                            TextField("Name", text: $model.tapConfiguration.name)
                                .disableAutocorrection(true)
                                .frame(width: 300)
                            TapConfigView(config: $model.tapConfiguration)
                        }
                    } label: {
                        Text("+")
                    }
                    Button(action: { model.destroyTap(id: model.tapSelection) }) {
                        Text("-")
                    }
                }
                Spacer()
            case .aggregates:
                List($model.aggregateDeviceList, selection: $model.aggregateDeviceSelection) { $device in
                    NavigationLink {
                        AggregateDeviceView(device: device)
                    } label: {
                        HStack {
                            Text(String(device.id))
                                .font(.headline)
                            Text(device.name)
                        }
                    }
                }
                HStack {
                    Button(action: model.createAggregateDevice) {
                        Text("+")
                    }
                    Button(action: { model.destroyAggregateDevice(id: model.aggregateDeviceSelection) }) {
                        Text("-")
                    }
                }
                Spacer()
            }
        } detail: {
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(Model())
}
