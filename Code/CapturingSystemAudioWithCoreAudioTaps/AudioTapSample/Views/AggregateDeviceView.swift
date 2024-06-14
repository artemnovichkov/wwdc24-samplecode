/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The view that provides UI for interacting with the aggregate device model.
*/

import SwiftUI

struct AggregateDeviceView: View {
    @EnvironmentObject private var model: Model
    @ObservedObject var device: AggregateDevice
    
    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            Text("Aggregate Device Details:")
                .font(.headline)
            Text("Name: \(device.name)")
            Text("Object ID: \(device.id)")
            Text("UID: \(device.uid)")
            Toggle(isOn: Binding(
                get: { device.isPrivate },
                set: { value in
                    device.setPrivate(priv: value)
                })) {
                Text("Private")
            }
            Toggle(isOn: Binding(
                get: { device.autoStart },
                set: { value in
                    device.setAutoStart(autostart: value)
                })) {
                Text("Tap Auto-Start")
            }
            Toggle(isOn: $device.autoStop) {
                Text("Stop when tapped processes stop")
            }
            List {
                ForEach(model.realDeviceList) { dev in
                    Toggle(isOn: Binding(
                        get: {
                            (device.deviceList).contains(dev.uid)
                        },
                        set: { value in
                            if value {
                                device.addSubDevice(uid: dev.uid)
                            } else {
                                device.removeSubDevice(uid: dev.uid)
                            }
                        })) {
                        Text(dev.uid)
                    }
                }
                ForEach(model.audioTapList) { tap in
                    Toggle(isOn: Binding(
                        get: {
                            device.tapList.contains(tap.uid)
                        },
                        set: { value in
                            if value {
                                device.addSubTap(uid: tap.uid)
                            } else {
                                device.removeSubTap(uid: tap.uid)
                            }
                        })) {
                        Text(tap.config.name)
                    }
                }
            }
            AudioIOView()
        }
        .frame(width: 350)
    }
}

#Preview {
    AggregateDeviceView(device: AggregateDevice(id: 1))
        .environmentObject(Model())
}
