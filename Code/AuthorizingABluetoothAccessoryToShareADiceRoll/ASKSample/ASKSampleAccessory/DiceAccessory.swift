/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Defines the class for advertising a Bluetooth accessory and posting messages.
*/

import Foundation
import CoreBluetooth
import SwiftUI

@Observable
class DiceAccessory: NSObject {
    var diceColor = DiceColor.pink
    var isAdvertising = false
    var mostRecentRoll = DiceValue.one
    var peripheralManager: CBPeripheralManager!
    var rollResultCharacteristic: CBMutableCharacteristic?
    var bluetoothManagerState = CBManagerState.poweredOff

    private static let diceRollCharacteristicUUID = "0xFF3F"

    override init() {
        super.init()
        self.peripheralManager = CBPeripheralManager(
            delegate: self,
            queue: nil,
            options: [CBPeripheralManagerOptionShowPowerAlertKey: true]
        )
    }

    // MARK: - DiceAccessory actions

    func roll() {
        var diceValue = DiceValue.allCases.randomElement()!
        while diceValue == mostRecentRoll {
            diceValue = DiceValue.allCases.randomElement()!
        }

        mostRecentRoll = diceValue
        sendRollValue(value: diceValue.rawValue)
    }

    func startAdvertising() {
        guard bluetoothManagerState == .poweredOn else {
            print("Cannot start advertising until Bluetooth Manager is powered on.")
            return
        }

        var advertisementData = [String: Any]()

        advertisementData[CBAdvertisementDataLocalNameKey] = diceColor.diceName
        advertisementData[CBAdvertisementDataServiceUUIDsKey] = [diceColor.serviceUUID]

        let diceService = CBMutableService(type: diceColor.serviceUUID, primary: true)

        let rollResultCharacteristic = CBMutableCharacteristic(
            type: CBUUID(string: Self.diceRollCharacteristicUUID),
            properties: [.read, .notify],
            value: nil,
            permissions: .readable
        )

        diceService.characteristics = [rollResultCharacteristic]
        self.rollResultCharacteristic = rollResultCharacteristic

        peripheralManager.add(diceService)

        peripheralManager.startAdvertising(advertisementData)
        isAdvertising = true
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func stopAdvertising() {
        guard bluetoothManagerState == .poweredOn  else { return }

        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()

        print("Stopped advertising")
        isAdvertising = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func sendRollValue(value: String) {
        guard
            bluetoothManagerState == .poweredOn,
            let data = value.data(using: .utf8)
        else {
            return
        }

        self.updateRollResultCharacteristicValue(value: data)
    }

    private func updateRollResultCharacteristicValue(value: Data) {
        guard let rollResultCharacteristic else { return }
        peripheralManager.updateValue(value, for: rollResultCharacteristic, onSubscribedCentrals: nil)
    }
}

// MARK: - CBPeripheralManagerDelegate

extension DiceAccessory: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        bluetoothManagerState = peripheral.state
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        print("Started advertising")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard
            request.characteristic.uuid == CBUUID(string: Self.diceRollCharacteristicUUID),
            let data = mostRecentRoll.rawValue.data(using: .utf8)
        else {
            return
        }

        request.value = data
        peripheralManager.respond(to: request, withResult: .success)
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard
            !mostRecentRoll.rawValue.isEmpty,
            let data = mostRecentRoll.rawValue.data(using: .utf8)
        else {
            return
        }

        self.updateRollResultCharacteristicValue(value: data)
    }
}
