# Adopting SwiftData for a Core Data app

Persist data in your app intuitively with the Swift native persistence framework.

## Overview
This sample project is designed to help you understand how to adopt SwiftData in an existing Core Data app. The SampleTrips app fetches and displays all upcoming trips from the store, and allows people to create or remove trips, and to add, update, or remove information from the itinerary for each trip. There are three versions of this app:

- A Core Data version that demonstrates Core Data best practices.
- A SwiftData version that shows the complete app conversion from Core Data to SwiftData.
- A coexistence version, where the sample app uses Core Data, and adds a widget extension that uses SwiftData. This version covers a scenario where you might want to adopt SwiftData incrementally, or for certain portions of your app.

## Configure the sample code project

Open the sample code project in Xcode. Before building it, do the following:

1. Set the developer team for all targets to your team so Xcode automatically manages the provisioning profile. For more information, see [Assign a project to a team](https://help.apple.com/xcode/mac/current/#/dev23aab79b4).

2. Replace the App Group container identifier — `group.com.example.apple-samplecode.SampleTrips` — with one specific to your team for the entire project. The identifier points to an App Group container that the app and widget use to share data. You can search for `group.com.example.apple-samplecode.SampleTrips` using the Find navigator in Xcode, and then change all of the occurrences (except those in this `README` file). For more information, see [Configuring App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups).

## Adopt SwiftData

The SwiftData sample sets up the schema with Swift types that conform to the [`PersistentModel`](https://developer.apple.com/documentation/swiftdata/persistentmodel) protocol, which captures information about the app’s types, including properties and relationships. Each model file corresponds to an individual entity, with identical entity names, properties, and relationships as its Core Data counterpart.

Each model file in this sample uses the [`Model()`](https://developer.apple.com/documentation/swiftdata/model()) macro to add necessary conformances for the `PersistentModel` and [`Observable`](https://developer.apple.com/documentation/observation/observable) protocols:

``` swift
@Model class Trip {
    #Index<Trip>([\.name], [\.startDate], [\.endDate], [\.name, \.startDate, \.endDate])
    #Unique<Trip>([\.name, \.startDate, \.endDate])
    
    @Attribute(.preserveValueOnDeletion)
    var name: String
    var destination: String
    
    @Attribute(.preserveValueOnDeletion)
    var startDate: Date
    
    @Attribute(.preserveValueOnDeletion)
    var endDate: Date

    @Relationship(deleteRule: .cascade, inverse: \BucketListItem.trip)
    var bucketList: [BucketListItem] = [BucketListItem]()
    
    @Relationship(deleteRule: .cascade, inverse: \LivingAccommodation.trip)
    var livingAccommodation: LivingAccommodation?
```

Additionally, the app sets up the container using [`ModelContainer`](https://developer.apple.com/documentation/swiftdata/modelcontainer) to ensure that all views access the same `ModelContainer`.
``` swift
.modelContainer(modelContainer)
```

Setting up the `ModelContainer` also creates and set a default [`ModelContext`](https://developer.apple.com/documentation/swiftdata/modelcontext) in the environment. The app can access the `ModelContext` from any scene or view using an environment property.
``` swift
@Environment(\.modelContext) private var modelContext
```

## Create a persisted data object

This app creates a new instance of a trip and inserts it into the [`ModelContext`](https://developer.apple.com/documentation/swiftdata/modelcontext) for persistence:
``` swift
let newTrip = Trip(name: name, destination: destination, startDate: startDate, endDate: endDate)
modelContext.insert(newTrip)
```

## Persist data

The app uses the SwiftData implicit save feature to persist data. This implicit save occurs on UI life cycle events and on a timer after the context changes. For more information about enabling autosave, see the [`autosaveEnabled`](https://developer.apple.com/documentation/swiftdata/modelcontext/autosaveenabled) property.

The app calls [`delete(_:)`](https://developer.apple.com/documentation/swiftdata/modelcontext/delete(_:)) on the [`ModelContext`](https://developer.apple.com/documentation/swiftdata/modelcontext) with the instance to delete.

``` swift
modelContext.delete(trip)
```

## Fetch persisted data

This sample app fetches the complete list of upcoming trips by wrapping an array of trips in [`Query`](https://developer.apple.com/documentation/swiftdata/query), which fetches `Trip` objects from the container.

``` swift
@Query(sort: \Trip.startDate, order: .forward)
var trips: [Trip]
```

This sample also fetches data by calling [`fetch(_:)`](https://developer.apple.com/documentation/swiftdata/modelcontext/fetch(_:)) on the [`ModelContext`](https://developer.apple.com/documentation/swiftdata/modelcontext) and passing in a [`FetchDescriptor`](https://developer.apple.com/documentation/swiftdata/fetchdescriptor) that specifies both the entity to retrieve data from as well as a corresponding [`Predicate`](https://developer.apple.com/documentation/foundation/predicate) specifying the conditions for the object to fetch.

``` swift
var descriptor = FetchDescriptor<BucketListItem>()
let tripName = trip.name
descriptor.predicate = #Predicate { item in
    item.title.contains(searchText) && tripName == item.trip?.name
}
let filteredList = try? modelContext.fetch(descriptor)
```

## Coexistence between Core Data and SwiftData

The coexistence version of the app has two persistence stacks: a Core Data persistence stack for the host app, and a SwiftData persistence stack for the widget extension. Both stacks write to the same store file.

## Namespace models

The namespaces in the coexistence sample use the pre-existing [`NSManagedObject`](https://developer.apple.com/documentation/coredata/nsmanagedobject)-based entity subclasses such that they don’t collide with the SwiftData classes. Note that this consideration refers to the class name, not the entity name.

``` swift
class CDTrip: NSManagedObject {
```

The sample then refers to the entity as `CDTrip` when accessing it in the Core Data host app. For instance, when adding a new `Trip`:

``` swift
let newTrip = CDTrip(context: viewContext)
```

## Share the same store file

This sample ensures that both the Core Data and SwiftData persistent stacks write to the same store file by setting the persistent store URL for the container description:

``` swift
if let description = container.persistentStoreDescriptions.first {
    description.url = url
```

Additionally, the coexistence sample must set the [`NSPersistentHistoryTrackingKey`](https://developer.apple.com/documentation/coredata/nspersistenthistorytrackingkey). Although SwiftData enables persistent history tracking automatically, Core Data does not, so the app enables persistent history manually.

``` swift
description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
```

By default, SwiftData behaves in the following way when determining where it persists data:

* It persists data store to the app’s Application Support directory.
* This sample app uses App Groups to access shared containers and share data between the SwiftData widget extension and the Core Data host app. For an app that has the [App Groups Entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com_apple_security_application-groups), it persists the data store to the root directory of the app group container. For apps that evolve from a version that doesn’t have any app group container to a version that has one, SwiftData copies the existing store to the app group container.

In this sample, the main app and widget share the same store via an app group container, and the store is located in the default location in the app group container. To ensure SwiftData accesses the same store, the main app and widget both share the [`ModelContainer`](https://developer.apple.com/documentation/swiftdata/modelcontainer).

The widget in this sample doesn’t write to the SwiftData store, but in general, an app and its extensions can safely read and write to the same SwiftData store simultaneously.
