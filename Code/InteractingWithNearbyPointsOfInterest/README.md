# Interacting with nearby points of interest

Provide automatic search completions for a partial search query, search the map for relevant locations nearby, and retrieve details for selected points of interest.

## Overview

This sample code project demonstrates how to programmatically search for map-based addresses and points of interest using a natural language string, and get more information for points of interest that a person selects on the map. The search results center around the locations visible in the map view.

## Request search completions
[`MKLocalSearchCompleter`][3] retrieves autocomplete suggestions for a partial search query within a map region. A person can type *cof*, and a search completion suggests *coffee* as the query string. 

``` swift
/// Ask for completion suggestions based on the query text.
func provideCompletionSuggestions(for query: String) {
    /**
     Configure the search to return completion results based only on the options in the app. For example,
     someone can configure the app to exclude specific point-of-interest categories, or to only return results for addresses.
     */
    searchCompleter?.resultTypes = mapConfiguration.resultType.completionResultType
    searchCompleter?.regionPriority = mapConfiguration.regionPriority.localSearchRegionPriority
    if mapConfiguration.resultType == .pointsOfInterest {
        searchCompleter?.pointOfInterestFilter = mapConfiguration.pointOfInterestOptions.filter
    } else if mapConfiguration.resultType == .addresses {
        searchCompleter?.addressFilter = mapConfiguration.addressOptions.filter
    }
    
    searchCompleter?.region = mapConfiguration.region
    searchCompleter?.queryFragment = query
}
```
[View in Source](x-source-tag://ProvideCompletions)

As someone types a query into a search bar, the sample app updates the [`queryFragment`][2] through the [`UISearchResultsUpdating`][4] protocol.

``` swift
func updateSearchResults(for searchController: UISearchController) {
     // Clear the search results when someone changes the query string. The updated query string may not match the existing search
     // results or the new suggested completions.
    displaySearchResults([])
    
    // Ask for new completion suggestions based on the change in the text that someone enters in `UISearchBar`.
    searchDataSource.provideCompletionSuggestions(for: searchController.searchBar.text ?? "")
}
```
[View in Source](x-source-tag://UpdateQuery)

[2]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompleter/1452555-queryfragment
[3]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompleter
[4]:https://developer.apple.com/documentation/uikit/uisearchresultsupdating

## Receive completion results
Completion results represent fully formed query strings based on the query fragment someone types. The sample app uses completion results to populate UI elements to quickly fill in a search query. The app receives the latest completion results as an array of [`MKLocalSearchCompletion`][5] objects by adopting the [`MKLocalSearchCompleterDelegate`][6] protocol.

``` swift
nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
    Task {
        /**
         As a person types, new completion suggestions continuously return to this method. Update the property storing the current
         results, so that the app UI can observe the change and display the updated suggestions.
         */
        let suggestedCompletions = completer.results
        await resultStreamContinuation?.yield(suggestedCompletions)
    }
}
```
[View in Source](x-source-tag://CompletionResults)

[5]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompletion
[6]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompleterdelegate

An [`AsyncStream`][6a] delivers the array of completion results to the code responsible for converting the contents of the array to [`UISearchSuggestionItem`][6b] elements for display.

``` swift
// Receive the search completions through an `AsyncStream` continuation that the search data source manages.
let searchCompletionStream = AsyncStream<[MKLocalSearchCompletion]>.makeStream()
searchDataSource.startProvidingSearchCompletions(with: searchCompletionStream.continuation)
searchCompletionsTask = searchCompletionsTask ?? Task { @MainActor in
    for await searchCompletions in searchCompletionStream.stream {
        
        // Use UIKit's search suggestions features to display the search completions.
        let completions = searchCompletions.map { completion in
            let suggestion = UISearchSuggestionItem(localizedAttributedSuggestion: completion.highlightedTitleStringForDisplay)
            suggestion.representedObject = completion
            return suggestion
        }
        searchController?.searchSuggestions = completions
    }
}
```
[View in Source](x-source-tag://CompletionDisplay)

[6a]:https://developer.apple.com/documentation/swift/asyncstream
[6b]:https://developer.apple.com/documentation/uikit/uisearchsuggestionitem

## Highlight the relationship of a query fragment to the suggestion

Within the UI elements that represent each query result, the sample code uses the [`titleHighlightRanges`][7] on an `MKLocalSearchCompletion` to show how the query someone enters relates to the suggested result. For example, the following code applies a highlight with [`NSAttributedString`][9]:

``` swift
private func createHighlightedString(text: String, rangeValues: [NSValue]) -> NSAttributedString {
    let attributes = [NSAttributedString.Key.backgroundColor: UIColor(named: "suggestionHighlight")!]
    let highlightedString = NSMutableAttributedString(string: text)

    // Each `NSValue` wraps an `NSRange` that functions as a style attribute's range with `NSAttributedString`.
    let ranges = rangeValues.map { $0.rangeValue }
    for range in ranges {
        highlightedString.addAttributes(attributes, range: range)
    }

    return highlightedString
}

var highlightedTitleStringForDisplay: NSAttributedString {
    return createHighlightedString(text: title, rangeValues: titleHighlightRanges)
}
```
[View in Source](x-source-tag://HighlightFragment)

[7]:https://developer.apple.com/documentation/mapkit/mklocalsearchcompletion/1451935-titlehighlightranges
[9]:https://developer.apple.com/documentation/foundation/nsattributedstring

## Search for map items

An [`MKLocalSearch.Request`][10] takes either an [`MKLocalSearchCompletion`][5] or a natural language query string, and returns an array of [`MKMapItem`][11] objects. Each `MKMapItem` represents a geographic location, like a specific address, that matches the search query. The sample code asynchronously retrieves the array of `MKMapItem` objects by calling [`start(completionHandler:)`][12] on [`MKLocalSearch`][13].

``` swift
let search = MKLocalSearch(request: request)
currentSearch = search
defer {
    // After the search completes, the reference is no longer needed.
    currentSearch = nil
}

var results: [MKMapItem]

do {
    let response = try await search.start()
    results = response.mapItems
} catch let error {
    searchLogging.error("Search error: \(error.localizedDescription)")
    results = []
}
```
[View in Source](x-source-tag://StartSearch)

[10]:https://developer.apple.com/documentation/mapkit/mklocalsearch/request
[11]:https://developer.apple.com/documentation/mapkit/mkmapitem
[12]:https://developer.apple.com/documentation/mapkit/mklocalsearch/1452652-start
[13]:https://developer.apple.com/documentation/mapkit/mklocalsearch


## Allow someone to select points of interest on the map
If a person is exploring the map, they can get information for a point of interest by tapping it.
To provide these interactions, the sample code enables selectable map features as follows:

``` swift
mapView?.selectableMapFeatures = [.pointsOfInterest]

// Filter out some point-of-interest categories based on selected settings within the app.
let mapConfiguration = MKStandardMapConfiguration()
mapConfiguration.pointOfInterestFilter = searchConfiguration.pointOfInterestOptions.filter
mapView?.preferredConfiguration = mapConfiguration
```
[View in Source](x-source-tag://SelectableFeature)

When someone taps a point of interest, the system calls [`mapView(_:, selectionAccessoryFor:)`][14] on the [`MKMapViewDelegate`][15] with an [`MKMapFeatureAnnotation`][16] that represents the tapped item.
The delegate returns an [`MKSelectionAccessory`][17] that displays the details of the map item. 
MapKit presents the map item's details using an [`MKMapItemDetailViewController`][20], which includes information like a phone number, business hours, and buttons to start navigation to the location using Apple Maps.

``` swift
/// This delegate method allows the selection of a point of interest on the map to show details about the selected item.
func mapView(_ mapView: MKMapView, selectionAccessoryFor annotation: any MKAnnotation) -> MKSelectionAccessory? {
    // Adapt the presentation to make the best use of space to see the most information possible. The `.automatic` presentation
    // style adapts to either a sheet presentation style or a callout presentation style.
    // The annotation that passes to this delegate method may be either `MKMapItemAnnotation` or `MKMapFeatureAnnotation`, depending
    // on whether the selected annotation is an annotation that the app adds to the map, or a feature that MapKit provides.
    .mapItemDetail(.automatic(presentationViewController: self))
}
```
[View in Source](x-source-tag://MapItemDetail)

[14]:https://developer.apple.com/documentation/mapkit/mkmapviewdelegate/4408671-mapview
[15]:https://developer.apple.com/documentation/mapkit/mkmapviewdelegate
[16]:https://developer.apple.com/documentation/mapkit/mkmapfeatureannotation
[17]:https://developer.apple.com/documentation/mapkit/mkselectionaccessory
[18]:https://developer.apple.com/documentation/mapkit/mkmapitemdetailviewcontroller


## Persist and retrieve map items

If someone is exploring the map, they may want the app to store places they looked at so that they can come back to them later, including across app launches.
`MKMapItem` has an [`identifier`][19] property, which the app stores in its `VisitedPlace` model using [SwiftData][21].

``` swift
guard let identifier = mapItem.identifier else { return }
let visit = VisitedPlace(id: identifier.rawValue)
```
[View in Source](x-source-tag://MapItemIdentifier)

When the app launches, it retrieves the history of visited locations from SwiftData.
To get the `MKMapItem` from the previously stored identifier, the app creates an [`MKMapItemRequest`][20] with the stored identifier and calls [`getMapItem(completionHandler:)`][22].

``` swift
@MainActor
func convertToMapItem() async -> MKMapItem? {
    guard let identifier = MKMapItem.Identifier(rawValue: id) else { return nil }
    let request = MKMapItemRequest(mapItemIdentifier: identifier)
    var mapItem: MKMapItem? = nil
    do {
        mapItem = try await request.mapItem
    } catch let error {
        let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Map Item Requests")
        logger.error("Getting map item from identifier failed. Error: \(error.localizedDescription)")
    }
    return mapItem
}
```
[View in Source](x-source-tag://MapItemRequest) 

[19]:https://developer.apple.com/documentation/mapkit/mkmapitem/4354087-identifier
[20]:https://developer.apple.com/documentation/mapkit/mkmapitemrequest
[21]:https://developer.apple.com/documentation/swiftdata
[22]:https://developer.apple.com/documentation/mapkit/mkmapitemrequest/3975743-getmapitem
