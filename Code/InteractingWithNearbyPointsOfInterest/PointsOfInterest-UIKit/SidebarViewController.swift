/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller of the app that displays the search interface and the places someone
 visits with the app.
*/

import CoreLocation
import MapKit
import SwiftData
import SwiftUI
import UIKit

class SidebarViewController: BaseMapItemViewController {
    
    /// The object that interacts with MapKit's search APIs.
    private var searchDataSource: SearchDataSource!
    
    /// Contains configuration parameters to customize the type of search.
    private var searchConfiguration: MapSearchConfiguration!
    
    /// A `UIViewController` that displays search completions and search results.
    private var searchResultsController: SearchResultsViewController!
    
    ///  The object that manages the UI elements for searching, including the search bar and the presentation of the search results controller.
    private var searchController: UISearchController!
    
    /// The detail view controller associated with this view controller to display search results.
    private var mapViewController: MapViewController!
    
    /// The data store for tracking the history of places someone visits.
    private var visitHistoryContainer: ModelContainer?
    
    /// A `Task` for monitoring an `AsyncStream` of selections someone makes on the map.
    private var mapSelectionTask: Task<Void, Never>?
    
    /// A button that displays the map when the containing split view controller collapses the presentation of the view controllers,
    /// such as on an iPhone.
    @IBOutlet private weak var showMapButton: UIBarButtonItem!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let mapNavigationController = splitViewController?.viewController(for: .secondary) as? UINavigationController
        mapViewController = mapNavigationController?.topViewController as? MapViewController
        
        // Ensure the data storage and listening stream of selected map items are available so this object receives information about
        // visits coming from the map view controller, even if this object isn't visible.
        visitHistoryContainer = try? ModelContainer(for: VisitedPlace.self)
        if let visitHistoryContainer {
            Task {
                await VisitedPlace.seedHistoryWithInitialData(in: visitHistoryContainer.mainContext)
                displayUpdatedVisitHistory()
            }
        }
        monitorMapSelections()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchConfiguration = mapViewController.searchConfiguration

        collectionView.delegate = self
        configureSearchController()
        
        displayUpdatedVisitHistory()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showMapButton.isHidden = !(splitViewController?.isCollapsed ?? true)
        updateUIFromSearchConfiguration()
    }
    
    func displayUpdatedVisitHistory() {
        if let visitedPlaces = try? visitHistoryContainer?.mainContext.fetch(VisitedPlace.reverseOrderFetchDescriptor) {
            Task {
                var mapItems: [MKMapItem] = []
                for place in visitedPlaces {
                    if let mapItem = await place.convertToMapItem() {
                        mapItems.append(mapItem)
                    }
                }
                
                let rows = mapItems.compactMap { Row(mapItem: $0) }
                
                let header = NSLocalizedString("VISITED_PLACES", comment: "History list title")
                let headerRow = Row(header: header)
                
                updateCollectionViewSnapshot(header: headerRow, dataRows: rows)
            }
        }
    }
    
    func addNewVisit(mapItem: MKMapItem) {
        if let visitHistoryContainer {
            VisitedPlace.addNewVisit(mapItem: mapItem, to: visitHistoryContainer.mainContext)
            displayUpdatedVisitHistory()
        }
    }
    
    private func monitorMapSelections() {
        // Receive selections from the `MKMapView` in a different view controller through an `AsyncStream`.
        mapSelectionTask = mapSelectionTask ?? Task { @MainActor in
            for await selectedMapItem in mapViewController.selectedMapItems {
                addNewVisit(mapItem: selectedMapItem)
            }
        }
    }
    
    private func configureSearchController() {
        searchDataSource = SearchDataSource(configuration: searchConfiguration)
        searchResultsController = SearchResultsViewController(searchDataSource: searchDataSource)
        searchResultsController.delegate = self
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchResultsController.searchController = searchController
        
        // Place the search bar in the navigation bar.
        navigationItem.searchController = searchController
        
        // Keep the search bar visible at all times.
        navigationItem.hidesSearchBarWhenScrolling = false
        
        /*
         Search is presenting a view controller, and needs a controller in the presented view controller hierarchy
         to define the presentation context.
         */
        definesPresentationContext = true
    }
    
    private func updateUIFromSearchConfiguration() {
        self.mapViewController.updateMapConfiguration()
        let string = searchPlaceholder
        searchController.searchBar.placeholder = string
    }
    
    @IBAction private func showMap(_ sender: Any) {
        splitViewController?.show(.secondary)
    }
    
    @IBSegueAction func showSettings(_ coder: NSCoder) -> UIViewController? {
        let settingsView = SettingsView(locationService: LocationService.shared,
                                        searchConfiguration: searchConfiguration) {
            self.updateUIFromSearchConfiguration()
        }
        
        return UIHostingController(coder: coder, rootView: settingsView)
    }
    
    override func configureResultCell(_ cell: UICollectionViewCell, indexPath: IndexPath, item: BaseMapItemViewController.Row) {
        guard let mapItem = item.mapItem else { return }
        cell.contentConfiguration = UIHostingConfiguration {
            MapItemRowView(mapItem: mapItem)
        }
    }
    
    private var searchPlaceholder: String {
        switch searchConfiguration.resultType {
        case .addresses:
            NSLocalizedString("ADDRESSES_PLACEHOLDER", comment: "Address search placeholder")
        case .pointsOfInterest:
            NSLocalizedString("POINTS_OF_INTEREST_PLACEHOLDER", comment: "Points of interest search placeholder")
        }
    }
}

// MARK: - UICollectionViewDelegate

extension SidebarViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        
        guard let row = dataSource.itemIdentifier(for: indexPath),
            let cell = collectionView.cellForItem(at: indexPath),
            let mapItem = row.mapItem else { return }
        
        presentMapItemDetail(mapItem, sourceView: cell, detailViewControllerDelegate: self)
    }
}

extension SidebarViewController: MKMapItemDetailViewControllerDelegate {
    func mapItemDetailViewControllerDidFinish(_ detailViewController: MKMapItemDetailViewController) {
        if let mapItem = detailViewController.mapItem {
            // After dismissing detail view controller, update the visit history.
            addNewVisit(mapItem: mapItem)
        }
    }
}

extension SidebarViewController: SearchResultsViewControllerDelegate {
    func searchResultsViewController(_ viewController: SearchResultsViewController, didSelect mapItem: MKMapItem) {
        addNewVisit(mapItem: mapItem)
    }
    
    func searchResultsViewController(_ viewController: SearchResultsViewController, didUpdate searchResults: [MKMapItem]) {
        mapViewController.displayMapItemsWithAnnotations(searchResults)
    }
}
