/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that displays search completions and search results.
*/

import MapKit
import UIKit
import SwiftUI

class SearchResultsViewController: BaseMapItemViewController {
    
    /// The object responsible for managing the search queries.
    private let searchDataSource: SearchDataSource
    
    // This is a weak reference because the search controller owns this view controller.
    weak var searchController: UISearchController?
    
    /// A delegate to let the main view controller know about updated search results.
    weak var delegate: SearchResultsViewControllerDelegate?
    
    /// A `Task` for monitoring an `AsyncStream` of search completions.
    private var searchCompletionsTask: Task<Void, Never>?
    
    init(searchDataSource: SearchDataSource) {
        self.searchDataSource = searchDataSource
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchController?.searchResultsUpdater = self
        searchController?.searchBar.delegate = self
        collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startGeneratingSearchCompletions()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopGeneratingSearchCompletions()
    }
    
    /// Request that the search data source generates search completions based on what someone types into the search field so that they don't
    /// need to type their entire search query.
    /// - Tag: CompletionDisplay
    private func startGeneratingSearchCompletions() {
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
    }
    
    /// This object stops listening for search completions and no longer displays them in the UI.
    private func stopGeneratingSearchCompletions() {
        searchDataSource.stopProvidingSearchCompletions()
        searchCompletionsTask?.cancel()
        searchCompletionsTask = nil
    }
    
    /// Update the collection view to display the map items that return in the search results.
    private func displaySearchResults(_ results: [MKMapItem]) {
        let headerRow = Row(header: NSLocalizedString("SEARCH_RESULTS", comment: "Standard result text"))
        
        let rows = results.map { Row(mapItem: $0) }
        updateCollectionViewSnapshot(header: headerRow, dataRows: rows)
        delegate?.searchResultsViewController(self, didUpdate: results)
    }
    
    // MARK: Collection View Data Source

    override func configureResultCell(_ cell: UICollectionViewCell, indexPath: IndexPath, item: Row) {
        guard let mapItem = item.mapItem  else { return }
        
        cell.contentConfiguration = UIHostingConfiguration {
            MapItemRowView(mapItem: mapItem)
        }
    }
}

// MARK: - UICollectionViewDelegate

extension SearchResultsViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let row = dataSource.itemIdentifier(for: indexPath),
            let cell = collectionView.cellForItem(at: indexPath),
            let mapItem = row.mapItem else { return }
        
        presentMapItemDetail(mapItem, sourceView: cell, detailViewControllerDelegate: nil)
        delegate?.searchResultsViewController(self, didSelect: mapItem)
    }
}

extension SearchResultsViewController: UISearchResultsUpdating {

    /// - Tag: UpdateQuery
    func updateSearchResults(for searchController: UISearchController) {
         // Clear the search results when someone changes the query string. The updated query string may not match the existing search
         // results or the new suggested completions.
        displaySearchResults([])
        
        // Ask for new completion suggestions based on the change in the text that someone enters in `UISearchBar`.
        searchDataSource.provideCompletionSuggestions(for: searchController.searchBar.text ?? "")
    }
    
    func updateSearchResults(for searchController: UISearchController, selecting searchSuggestion: any UISearchSuggestion) {
        // Someone selects a search completion. Perform a search with the suggested completion.
        guard let completion = searchSuggestion.representedObject as? MKLocalSearchCompletion else { return }
        
        /*
         To keep the UI reflecting the correct state, change the text of the search field to reflect the selected completion.
         However, you don't want this change of the search text to generate new completions, so pause getting updated completions until
         the results of the search display.
         */
        stopGeneratingSearchCompletions()
        searchController.searchBar.text = completion.title
        
        Task {
            // Someone selects a search completion. Perform a search with the suggested completion.
            let searchResults = await searchDataSource.search(for: completion)
            searchController.searchSuggestions = nil
            displaySearchResults(searchResults)
            
            // After updating the search results, any modifications of the search text generate new completions.
            startGeneratingSearchCompletions()
        }
    }
}

// MARK: - UISearchBarDelegate

extension SearchResultsViewController: UISearchBarDelegate {
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
        startGeneratingSearchCompletions()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
        stopGeneratingSearchCompletions()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
         // The system calls this method when someone taps Search on the keyboard.
         // Because the person doesn't select a row with a suggested completion, run the search with the query text in the search field.
        Task {
            let searchResults = await searchDataSource.search(for: searchBar.text ?? "")
            displaySearchResults(searchResults)
        }
    }
}

@MainActor
protocol SearchResultsViewControllerDelegate: NSObjectProtocol {
    /// The search results that `SearchResultsViewController` displays.
    func searchResultsViewController(_ viewController: SearchResultsViewController, didUpdate searchResults: [MKMapItem])
    
    /// The search results view controller calls this when the user selects a search result.
    func searchResultsViewController(_ viewController: SearchResultsViewController, didSelect mapItem: MKMapItem)
}
