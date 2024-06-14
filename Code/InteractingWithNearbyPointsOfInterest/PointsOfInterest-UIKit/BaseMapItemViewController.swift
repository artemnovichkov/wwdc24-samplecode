/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A base view controller that provides the collection view infrastructure for all of the collection view controllers.
*/

import Foundation
@preconcurrency import MapKit
import UIKit

class BaseMapItemViewController: UIViewController {
    enum Section {
        case main
    }
    
    struct Row: Hashable {
        var header: String?
        var mapItem: MKMapItem?
        
        init(header: String) {
            self.header = header
        }
        
        init(mapItem: MKMapItem) {
            self.mapItem = mapItem
        }
    }
    
    var dataSource: UICollectionViewDiffableDataSource<Section, Row>! = nil
    var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureViewHierarchy()
        configureDataSource()
    }
    
    private func configureViewHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { section, layoutEnvironment in
            var config = UICollectionLayoutListConfiguration(appearance: .grouped)
            config.headerMode = .firstItemInSection
            return NSCollectionLayoutSection.list(using: config, layoutEnvironment: layoutEnvironment)
        }
    }

    private func configureDataSource() {
        let headerRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Row>(handler: configureHeaderCell)
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, Row>(handler: configureResultCell)

        dataSource = UICollectionViewDiffableDataSource<Section, Row>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, item: Row) -> UICollectionViewCell? in
            if indexPath.item == 0 {
                return collectionView.dequeueConfiguredReusableCell(using: headerRegistration, for: indexPath, item: item)
            } else {
                return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: item)
            }
        }
    }
    
    /// Call this method when the data changes to display the updated data.
    func updateCollectionViewSnapshot(header: Row, dataRows: [Row]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Row>()
        snapshot.appendSections([Section.main])
        dataSource?.apply(snapshot, animatingDifferences: true)
        var sectionSnapshot = NSDiffableDataSourceSectionSnapshot<Row>()

        sectionSnapshot.append([header])
        sectionSnapshot.append(dataRows)

        dataSource?.apply(sectionSnapshot, to: Section.main, animatingDifferences: true)
    }
    
    func configureHeaderCell(_ cell: UICollectionViewCell, indexPath: IndexPath, item: Row) {
        var content = UIListContentConfiguration.header()
        content.text = item.header
        cell.contentConfiguration = content
    }
    
    /// Override this method in a subclass to customize the cells.
    func configureResultCell(_ cell: UICollectionViewCell, indexPath: IndexPath, item: Row) {
        
    }
    
    /// Display an `MKMapItemDetailViewController` for the `mapItem` parameter.
    func presentMapItemDetail(_ mapItem: MKMapItem, sourceView: UICollectionViewCell,
                              detailViewControllerDelegate: (any MKMapItemDetailViewControllerDelegate)?) {
        // When the interface idiom is `pad`, the system presents the detail view controller over a map view, so there's no need for the detail
        // view controller to display the map. When the idiom is `phone`, the map isn't visible, so include a map in the detail view controller
        // to give context for the location.
        let includeMapWithDetail = traitCollection.userInterfaceIdiom == .phone
        let detailViewController = MKMapItemDetailViewController(mapItem: mapItem, displaysMap: includeMapWithDetail)
        detailViewController.delegate = detailViewControllerDelegate
        detailViewController.modalPresentationStyle = .popover
        
        if let popoverController = detailViewController.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
        }
        
        present(detailViewController, animated: true, completion: nil)
    }
}
