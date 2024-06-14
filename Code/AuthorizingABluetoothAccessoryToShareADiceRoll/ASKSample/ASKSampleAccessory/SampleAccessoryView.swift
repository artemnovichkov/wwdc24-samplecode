/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Main view for ASKSampleAccessory.
*/

import SwiftUI

struct SampleAccessoryView: View {
    @State var diceAccessory = DiceAccessory()

    var body: some View {
        NavigationStack {
            VStack(spacing: 10) {
                Text(diceAccessory.mostRecentRoll.rawValue)
                    .font(.system(size: 350).monospaced().bold())
                    .foregroundStyle(diceAccessory.diceColor.color)
                    .contentTransition(.numericText())
                    .frame(maxHeight: .infinity)

                Menu {
                    Button {
                        diceAccessory.diceColor = .blue
                    } label: {
                        Text(DiceColor.blue.rawValue.capitalized)
                    }

                    Button {
                        diceAccessory.diceColor = .pink
                    } label: {
                        Text(DiceColor.pink.rawValue.capitalized)
                    }
                } label: {
                    Text("Color: \(diceAccessory.diceColor.rawValue.capitalized)")
                        .font(Font.headline.weight(.semibold))
                        .padding(.vertical, 4)
                        .padding(.horizontal, 50)
                }
                .tint(diceAccessory.diceColor.color)
                .disabled(diceAccessory.isAdvertising)

                Button {
                    withAnimation {
                        diceAccessory.roll()
                    }
                } label: {
                    Text("Roll")
                        .frame(maxWidth: .infinity)
                        .font(Font.headline.weight(.semibold))
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(diceAccessory.diceColor.color)
                .foregroundStyle(.white)

                Button {
                    diceAccessory.isAdvertising ? diceAccessory.stopAdvertising() : diceAccessory.startAdvertising()
                } label: {
                    Text(diceAccessory.isAdvertising ? "Power Off" : "Power On")
                        .frame(maxWidth: .infinity)
                        .font(Font.headline.weight(.semibold))
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(diceAccessory.diceColor.color)
                .foregroundStyle(.white)

            }
            .padding(.bottom, 40)
            .padding(.horizontal, 64)
            .navigationTitle("Roll")
        }
    }
}
