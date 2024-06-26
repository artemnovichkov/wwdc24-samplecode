/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A data object that tracks the number of drinks that the user has drunk.
*/

import ClockKit
public import Combine
import SwiftUI
import os

private let floatFormatter = FloatingPointFormatStyle<Double>().precision(.significantDigits(1...3))

private actor CoffeeDataStore {
    let logger = Logger(
        subsystem:
            "com.example.apple-samplecode.Coffee-Tracker.watchkitapp.watchkitextension.CoffeeDataStore",
        category: "ModelIO")

    // Use this value to determine whether you have changes that can be saved to disk.
    private var savedValue: [Drink] = []

    // Begin saving the drink data to disk.
    func save(_ currentDrinks: [Drink]) {

        // Don't save the data if there haven't been any changes.
        if currentDrinks == savedValue {
            logger.debug("The drink list hasn't changed. No need to save.")
            return
        }

        // Save as a binary plist file.
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary

        let data: Data

        do {
            // Encode the current drinks array.
            data = try encoder.encode(currentDrinks)
        } catch {
            logger.error("An error occurred while encoding the data: \(error.localizedDescription)")
            return
        }

        do {
            // Write the data to disk.
            try data.write(to: self.dataURL, options: [.atomic])

            // Update the saved value.
            self.savedValue = currentDrinks

            self.logger.debug("Saved!")
        } catch {
            self.logger.error(
                "An error occurred while saving the data: \(error.localizedDescription)")
        }
    }

    // Begin loading the data from disk.
    func load() -> [Drink] {
        logger.debug("Loading the model.")

        let drinks: [Drink]

        do {
            // Load the drink data from a binary plist file.
            let data = try Data(contentsOf: self.dataURL)

            // Decode the data.
            let decoder = PropertyListDecoder()
            drinks = try decoder.decode([Drink].self, from: data)
            logger.debug("Data loaded from disk")
        } catch CocoaError.fileReadNoSuchFile {
            logger.debug("No file found--creating an empty drink list.")
            drinks = []
        } catch {
            fatalError(
                "*** An unexpected error occurred while loading the drink list: \(error.localizedDescription) ***"
            )
        }

        // Update the saved value.
        savedValue = drinks
        return drinks
    }

    // Returns the URL for the plist file that stores the drink data.
    private var dataURL: URL {
        get throws {
            try FileManager
                .default
                .url(
                    for: .documentDirectory,
                    in: .userDomainMask,
                    appropriateFor: nil,
                    create: false
                )
                // Append the file name to the directory.
                .appendingPathComponent("CoffeeTracker.plist")
        }
    }
}

// The data model for the Coffee Tracker app.
@MainActor
public class CoffeeData: ObservableObject {

    let logger = Logger(
        subsystem:
            "com.example.apple-samplecode.Coffee-Tracker.watchkitapp.watchkitextension.CoffeeData",
        category: "Model")

    // The data model needs to be accessed both from the app extension
    // and from the complication controller.
    public static let shared = CoffeeData()
    public lazy var healthKitController = HealthKitController(withModel: self)

    public lazy var locationProvider = CoffeeLocationDelegate()

    // An actor used to save and load the model data away from the main thread.
    private let store = CoffeeDataStore()

    // The list of drinks consumed.
    // Because this is a @Published property,
    // Combine notifies any observers when a change occurs.
    @Published public private(set) var currentDrinks: [Drink] = []

    private func drinksUpdated() async {
        logger.debug("A value has been assigned to the current drinks property.")

        // Update any complications on active watch faces.
        let server = CLKComplicationServer.sharedInstance()
        for complication in server.activeComplications ?? [] {
            server.reloadTimeline(for: complication)
        }

        // Begin saving the data.
        await store.save(currentDrinks)
    }

    // The current level of caffeine in milligrams.
    // This property is calculated based on the current drinks array.
    public var currentMGCaffeine: Double {
        mgCaffeine(atDate: Date())
    }

    // A user-readable string representing the current amount of
    // caffeine in the user's body.
    public var currentMGCaffeineString: String {
        currentMGCaffeine.formatted(floatFormatter)
    }

    // Calculate the amount of caffeine in the user's system at the specified date.
    // The amount of caffeine is calculated from the current drinks array.
    public func mgCaffeine(atDate date: Date) -> Double {
        currentDrinks.reduce(0.0) {
            total, drink in total + drink.caffeineRemaining(at: date)
        }
    }

    // Return a user-readable string that describes the amount of caffeine in the user's
    // system at the specified date.
    public func mgCaffeineString(atDate date: Date) -> String {
        mgCaffeine(atDate: date).formatted(floatFormatter)
    }

    // Return the total number of drinks consumed today.
    // The value is in the equivalent number of 8-ounce cups of coffee.
    public var totalCupsToday: Double {

        // Calculate midnight this morning.
        let calendar = Calendar.current
        let midnight = calendar.startOfDay(for: Date())

        // Filter the drinks.
        let drinks = currentDrinks.filter { midnight < $0.date }

        // Get the total caffeine dose.
        let totalMG = drinks.reduce(0.0) { $0 + $1.mgCaffeine }

        // Convert mg of caffeine to the equivalent cups.
        return totalMG / DrinkType.smallCoffee.mgCaffeinePerServing
    }

    // Return the total equivalent cups of coffee as a user-readable string.
    public var totalCupsTodayString: String {
        totalCupsToday.formatted(floatFormatter)
    }

    // Return green, yellow, or red depending on the caffeine dose.
    public func color(forCaffeineDose dose: Double) -> UIColor {
        if dose < 200.0 {
            .green
        } else if dose < 400.0 {
            .yellow
        } else {
            .red
        }
    }

    // Return green, yellow, or red depending on the total daily cups of coffee.
    public func color(forTotalCups cups: Double) -> UIColor {
        if cups < 3.0 {
            .green
        } else if cups < 5.0 {
            .yellow
        } else {
            .red
        }
    }

    // Add a drink to the list of drinks.
    public func addDrink(type: DrinkType, onDate date: Date) async {
        logger.debug("Adding a drink.")

        // Create a new drink to add to the array.
        let drink = Drink(type: type, onDate: date)
        locationProvider.requestLocation()

        // TODO: Wait for delegate to receive the updated location.

        // Create a local array to hold the changes.
        var drinks = currentDrinks

        // Get rid of any drinks that are 24 hours old.
        drinks.removeOutdatedDrinks()

        drinks.append(drink)
        currentDrinks = drinks

        // Save drink information to HealthKit.
        await self.healthKitController.save(drink: drink)
        await self.drinksUpdated()
    }

    // Update the model.
    public func updateModel(newDrinks: [Drink], deletedDrinks: Set<UUID>) async {

        guard !newDrinks.isEmpty && !deletedDrinks.isEmpty else {
            logger.debug("No drinks to add or delete from HealthKit.")
            return
        }

        // Remove the deleted drinks.
        var drinks = currentDrinks.filter { deletedDrinks.contains($0.uuid) }

        // Add the new drinks.
        drinks += newDrinks

        // Sort the array by date.
        drinks.sort { $0.date < $1.date }

        currentDrinks = drinks
        await drinksUpdated()
    }

    // MARK: - Private Methods

    // The model's initializer. Do not call this method.
    // Use the shared instance instead.
    private init() {

        // Begin loading the data from disk.
        Task { await load() }
    }

    // Begin loading the data from disk.
    func load() async {
        var drinks = await store.load()

        // Remove old drinks.
        drinks.removeOutdatedDrinks()

        // Assign loaded drinks to the model.
        currentDrinks = drinks
        await drinksUpdated()

        // Load new data from HealthKit.
        guard await healthKitController.requestAuthorization() else {
            logger.debug("Unable to authorize HealthKit.")
            return
        }

        await self.healthKitController.loadNewDataFromHealthKit()
    }
}

extension Array where Element == Drink {
    // Filter the array to only the drinks in the last 24 hours.
    fileprivate mutating func removeOutdatedDrinks() {
        let endDate = Date()

        // The date and time 24 hours ago.
        let startDate = endDate.addingTimeInterval(-24.0 * 60.0 * 60.0)

        // The date range of drinks to keep.
        let today = startDate...endDate

        // Return an array of drinks with a date parameter between
        // the start and end dates.
        self.removeAll { drink in
            !today.contains(drink.date)
        }
    }
}

@MainActor
public protocol CaffeineThresholdDelegate: AnyObject {
    func caffeineLevel(at level: Double)
}

@MainActor
public class CoffeeLocationDelegate: NSObject {
    let logger = Logger(
        subsystem:
            "com.example.apple-samplecode.Coffee-Tracker.watchkitapp.watchkitextension.CoffeeLocationDelegate",
        category: "Model")

    var manager: CLLocationManager!

    override init() {
        super.init()
        manager = CLLocationManager()
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        manager.delegate = self
    }

    public func authorizeLocation() {
        if manager.authorizationStatus == .notDetermined {
            logger.debug("Requesting location authorization")
            manager.requestWhenInUseAuthorization()
        } else {
            logger.debug(
                "Location authorization status: \(self.manager.authorizationStatus.rawValue)")
        }
    }

    func requestLocation() {
        logger.debug("Requesting location")
        authorizeLocation()
        // Request a one-shot location update.
        manager.requestLocation()
    }
}

extension CoffeeLocationDelegate: CLLocationManagerDelegate {
    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        logger.debug("Received locations \(locations)")
        MainActor.assumeIsolated {
            // TODO: Return back to the coffee data store to update the drink with a location.
        }
    }

    nonisolated public func locationManager(
        _ manager: CLLocationManager, didFailWithError error: any Error
    ) {
        logger.error("Error receiving location: \(error)")
    }
}
