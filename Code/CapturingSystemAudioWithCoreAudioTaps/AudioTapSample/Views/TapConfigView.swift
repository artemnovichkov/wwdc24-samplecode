/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that provides UI for interacting with a tap configuration structure.
*/

import SwiftUI

struct TapConfigView: View {
    @EnvironmentObject private var model: Model
    @Binding var config: TapConfig
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Mute Behavior:", selection: $config.mute) {
                ForEach(TapMute.allCases, id: \.self) { state in
                    switch state {
                    case .unmuted:
                        Text("Unmuted")
                    case .muted:
                        Text("Muted")
                    case .mutedWhenTapped:
                        Text("Muted When Tapped")
                    }
                }
            }
            .frame(width: 260)
            Picker("Mixdown Style:", selection: $config.mixdown) {
                ForEach(TapMixdown.allCases, id: \.self) { state in
                    switch state {
                    case .mono:
                        Text("Mono")
                    case .stereo:
                        Text("Stereo")
                    case .deviceFormat:
                        Text("Device Format")
                    }
                }
            }
            .frame(width: 220)
            if config.mixdown == .deviceFormat {
                Picker("Device:", selection: $config.device) {
                    Text("").tag(nil as String?)
                    ForEach(model.realDeviceList) { device in
                        Text(device.uid).tag(device.uid as String?)
                    }
                }
                .frame(width: 250)
                LabeledContent {
                    TextField("Stream Index:", value: $config.streamIndex, formatter: NumberFormatter())
                    .disableAutocorrection(true)
                    .frame(width: 100)
                } label: { Text("Stream Index:")
                }
            }
            Toggle(isOn: $config.isPrivate) {
                Text("Private")
            }
            Toggle(isOn: $config.exclusive) {
                Text("Exclusive")
            }
            Text("Processes:")
            List($model.audioProcessList) { $process in
                Toggle(isOn: Binding(
                    get: {
                        config.processes.contains(process.id)
                    },
                    set: { value in
                        if value {
                            config.processes.insert(process.id)
                        } else {
                            config.processes.remove(process.id)
                        }
                    })) {
                    Text(String(process.pid) + ": " + process.name)
                }
            }
            .frame(width: 350)
        }
    }
}

#Preview {
    TapConfigView(config: .constant(TapConfig()))
        .environmentObject(Model())
}
