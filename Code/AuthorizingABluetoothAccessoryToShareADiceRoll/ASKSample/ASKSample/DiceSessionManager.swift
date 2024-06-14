/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
Manages the ASAccessorySession and connections to dice accessories.
*/

import Foundation
import AccessorySetupKit
import CoreBluetooth
import SwiftUI

@Observable
class DiceSessionManager: NSObject {
    var diceColor: DiceColor?
    var diceValue = DiceValue.one
    var peripheralConnected = false
    var pickerDismissed = true

    private var currentDice: ASAccessory?
    private var session = ASAccessorySession()
    private var manager: CBCentralManager?
    private var peripheral: CBPeripheral?
    private var rollResultCharacteristic: CBCharacteristic?

    private static let diceRollCharacteristicUUID = "0xFF3F"

    private static let pinkDice: ASPickerDisplayItem = {
        let descriptor = ASDiscoveryDescriptor()
        descriptor.bluetoothServiceUUID = DiceColor.pink.serviceUUID

        return ASPickerDisplayItem(
            name: DiceColor.pink.displayName,
            productImage: UIImage(named: DiceColor.pink.diceName)!,
            descriptor: descriptor
        )
    }()

    private static let blueDice: ASPickerDisplayItem = {
        let descriptor = ASDiscoveryDescriptor()
        descriptor.bluetoothServiceUUID = DiceColor.blue.serviceUUID

        return ASPickerDisplayItem(
            name: DiceColor.blue.displayName,
            productImage: UIImage(named: DiceColor.blue.diceName)!,
            descriptor: descriptor
        )
    }()

    override init() {
        super.init()
        self.session.activate(on: DispatchQueue.main, eventHandler: handleSessionEvent(event:))
    }

    // MARK: - DiceSessionManager actions

    func presentPicker() {
        session.showPicker(for: [Self.pinkDice, Self.blueDice]) { error in
            if let error {
                print("Failed to show picker due to: \(error.localizedDescription)")
            }
        }
    }

    func removeDice() {
        guard let currentDice else { return }

        if peripheralConnected {
            disconnect()
        }

        session.removeAccessory(currentDice) { _ in
            self.diceColor = nil
            self.currentDice = nil
            self.manager = nil
        }
    }

    func connect() {
        guard
            let manager, manager.state == .poweredOn,
            let peripheral
        else {
            return
        }

        manager.connect(peripheral)
    }

    func disconnect() {
        guard let peripheral, let manager else { return }
        manager.cancelPeripheralConnection(peripheral)
    }

    // MARK: - ASAccessorySession functions

    private func saveDice(dice: ASAccessory) {
        currentDice = dice

        if manager == nil {
            manager = CBCentralManager(delegate: self, queue: nil)
        }

        if dice.displayName == DiceColor.pink.displayName {
            diceColor = .pink
        } else if dice.displayName == DiceColor.blue.displayName {
            diceColor = .blue
        }
    }

    private func handleSessionEvent(event: ASAccessoryEvent) {
        switch event.eventType {
        case .accessoryAdded, .accessoryChanged:
            guard let dice = event.accessory else { return }
            saveDice(dice: dice)
        case .activated:
            guard let dice = session.accessories.first else { return }
            saveDice(dice: dice)
        case .accessoryRemoved:
            self.diceColor = nil
            self.currentDice = nil
            self.manager = nil
        case .pickerDidPresent:
            pickerDismissed = false
        case .pickerDidDismiss:
            pickerDismissed = true
        default:
            print("Received event type \(event.eventType)")
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension DiceSessionManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central manager state: \(central.state)")
        switch central.state {
        case .poweredOn:
            if let peripheralUUID = currentDice?.bluetoothIdentifier {
                peripheral = central.retrievePeripherals(withIdentifiers: [peripheralUUID]).first
                peripheral?.delegate = self
            }
        default:
            peripheral = nil
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral: \(peripheral)")
        guard let diceColor else { return }
        peripheral.delegate = self
        peripheral.discoverServices([diceColor.serviceUUID])

        peripheralConnected = true
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: (any Error)?) {
        print("Disconnected from peripheral: \(peripheral)")
        peripheralConnected = false
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: (any Error)?) {
        print("Failed to connect to peripheral: \(peripheral), error: \(error.debugDescription)")
    }
}

// MARK: - CBPeripheralDelegate

extension DiceSessionManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: (any Error)?) {
        guard
            error == nil,
            let services = peripheral.services
        else {
            return
        }

        for service in services {
            peripheral.discoverCharacteristics([CBUUID(string: Self.diceRollCharacteristicUUID)], for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: (any Error)?) {
        guard
            error == nil,
            let characteristics = service.characteristics
        else {
            return
        }

        for characteristic in characteristics where characteristic.uuid == CBUUID(string: Self.diceRollCharacteristicUUID) {
            rollResultCharacteristic = characteristic
            peripheral.setNotifyValue(true, for: characteristic)
            peripheral.readValue(for: characteristic)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: (any Error)?) {
        guard
            error == nil,
            characteristic.uuid == CBUUID(string: Self.diceRollCharacteristicUUID),
            let data = characteristic.value,
            let diceValue = String(data: data, encoding: .utf8)
        else {
            return
        }

        print("New dice value received: \(diceValue)")

        DispatchQueue.main.async {
            withAnimation {
                self.diceValue = DiceValue(rawValue: diceValue)!
            }
        }
    }
}
