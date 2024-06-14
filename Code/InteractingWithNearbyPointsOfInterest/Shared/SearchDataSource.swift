/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
An object that manages all of the interactions with MapKit's search capabilities.
*/

import Foundation
@preconcurrency import MapKit
import OSLog
import SwiftUI

@MainActor
class SearchDataSource: NSObject {
    private let searchLogging = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Search Completions")
    
    let mapConfiguration: MapSearchConfiguration
    
    init(configuration: MapSearchConfiguration) {
        self.mapConfiguration = configuration
        super.init()
    }
    
    // MARK: - MKLocalSearch
    
    private var currentSearch: MKLocalSearch?
    
    /**
     Runs an `MKLocalSearch.Request` based on the passed `MKLocalSearchCompletion` parameter.
     - Returns: An array of search results based on a query string, representing the full information available for the map item,
     including a name of the search result, its location information, and a category for the map item.
     */
    func search(for completion: MKLocalSearchCompletion) async -> [MKMapItem] {
        let request = MKLocalSearch.Request(completion: completion)
        return await performSearch(request)
    }
    
    /**
     Runs an `MKLocalSearch.Request` with a natural language search for the `queryString` parameter.
     - Returns: An array of search results based on a query string, representing the full information available for the map item,
     including a name of the search result, its location information, and a category for the map item.
     */
    func search(for queryString: String) async -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = queryString
        return await performSearch(request)
    }
    
    /// - Tag: StartSearch
    /// Fills in common details for the `MKLocalSearch.Request` and performs the search.
    private func performSearch(_ request: MKLocalSearch.Request) async -> [MKMapItem] {
        // If there's another search already in progress, cancel it.
        currentSearch?.cancel()
        
        request.region = mapConfiguration.region
        
        /**
         Configure the search to return completion results based only on the options in the app. For example,
         someone can configure the app to exclude any points of interest related to travel.
         */
        request.resultTypes = mapConfiguration.resultType.localSearchResultType
        request.regionPriority = mapConfiguration.regionPriority.localSearchRegionPriority
        if mapConfiguration.resultType == .pointsOfInterest {
            request.pointOfInterestFilter = mapConfiguration.pointOfInterestOptions.filter
        } else if mapConfiguration.resultType == .addresses {
            request.addressFilter = mapConfiguration.addressOptions.filter
        }
        
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
        
        return results
    }
    
    // MARK: - MKLocalSearchCompleter
    
    private var searchCompleter: MKLocalSearchCompleter?
    
    /// A stream continuation of search completion results. Each array of search completions from this stream belongs to a single search query.
    private var resultStreamContinuation: AsyncStream<[MKLocalSearchCompletion]>.Continuation?
    
    /// Sets up the necessary state for this object to provide search completions on the stream that the caller provides.
    func startProvidingSearchCompletions(with continuation: AsyncStream<[MKLocalSearchCompletion]>.Continuation) {
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter?.delegate = self
        resultStreamContinuation = continuation
    }
    
    /// Stop delivering search completion results.
    func stopProvidingSearchCompletions() {
        searchCompleter = nil
        resultStreamContinuation?.finish()
        resultStreamContinuation = nil
    }
    
    /// - Tag: ProvideCompletions
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
}

extension SearchDataSource: MKLocalSearchCompleterDelegate {

    /// - Tag: CompletionResults
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

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task {
            // Handle any errors that `MKLocalSearchCompleter` returns.
            searchLogging.error("Search completion failed for query \"\(completer.queryFragment)\". Reason: \(error.localizedDescription)")
            
            /**
             Send an empty array on the stream for the error scenario. This is common, such as when the query is an empty string,
             so the completer can't return any reasonable results, but the UI displaying the completions might need to clear the displayed
             completions.
             */
            await resultStreamContinuation?.yield([])
        }
    }
}
