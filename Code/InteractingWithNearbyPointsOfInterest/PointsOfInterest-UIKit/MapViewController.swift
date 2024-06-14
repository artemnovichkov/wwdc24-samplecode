/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that demonstrates how to interact with the points of interest on the map.
*/

import Foundation
@preconcurrency import MapKit
import OSLog
import UIKit

class MapViewController: UIViewController {
    
    @IBOutlet private weak var mapView: MKMapView!
    
    /// A stream of the selected map items in the map view.
    var selectedMapItems: AsyncStream<MKMapItem> {
        AsyncStream { continuation in
            self.selectedMapItemsContinuation = continuation
        }
    }
    private var selectedMapItemsContinuation: AsyncStream<MKMapItem>.Continuation?
    
    /// A stream of changes to the visible map region.
    var visibleMapRegion: AsyncStream<MKCoordinateRegion> {
        AsyncStream { continuation in
            self.visibleMapRegionContinuation = continuation
        }
    }
    private var visibleMapRegionContinuation: AsyncStream<MKCoordinateRegion>.Continuation?
    
    let searchConfiguration = MapSearchConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateMapCoordinates(LocationService.shared.currentLocation.coordinate)
        updateMapConfiguration()
    }
    
    private func updateMapCoordinates(_ coordinate: CLLocationCoordinate2D) {
        let mapRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 1500, longitudinalMeters: 1500)
        mapView.setRegion(mapRegion, animated: true)
        searchConfiguration.region = mapRegion
    }
    
    /// Adds annotations to the map view for a collection of map items.
    func displayMapItemsWithAnnotations(_ mapItems: [MKMapItem]) {
        mapView.removeAnnotations(mapView.annotations)
        
        let mapItemAnnotations = mapItems.compactMap { MKMapItemAnnotation(mapItem: $0) }
        mapView.addAnnotations(mapItemAnnotations)
        
        // Adjust the map's visible area to show all of the annotations.
        mapView.showAnnotations(mapItemAnnotations, animated: true)
    }
    
    /// - Tag: SelectableFeature
    func updateMapConfiguration() {
        /*
         Limit the selection of features on the map to points of interest, such as hotels, parks, and restaurants.
         This disables the selection of territory labels, such as cities and neighborhoods, and physical features,
         such as mountain ranges.
         */
        mapView?.selectableMapFeatures = [.pointsOfInterest]
        
        // Filter out some point-of-interest categories based on selected settings within the app.
        let mapConfiguration = MKStandardMapConfiguration()
        mapConfiguration.pointOfInterestFilter = searchConfiguration.pointOfInterestOptions.filter
        mapView?.preferredConfiguration = mapConfiguration
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        searchConfiguration.region = mapView.region
        visibleMapRegionContinuation?.yield(mapView.region)
    }
    
    func mapView(_ mapView: MKMapView, didSelect annotation: any MKAnnotation) {
        if let annotation = annotation as? MKMapItemAnnotation {
            // The selected annotation is the `MKMapItemAnnotation` type when someone's selection is
            // an annotation that this class adds to the map from an array of search results.
            selectedMapItemsContinuation?.yield(annotation.mapItem)
            
        } else if let annotation = annotation as? MKMapFeatureAnnotation {
            // The selected annotation is the `MKMapFeatureAnnotation` type when someone's selection is a
            // selected point of interest from the map. MapKit adds these features to the map and controls their visibility
            // through the `pointOfInterestFilter` property of the map's `preferredConfiguration`.
            Task {
                // Let subscribers know when the map's selection changes.
                let request = MKMapItemRequest(mapFeatureAnnotation: annotation)
                var mapItem: MKMapItem? = nil
                do {
                    mapItem = try await request.mapItem
                } catch let error {
                    let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Map Item Requests")
                    logger.error("Getting map item from map feature annotation failed. Error: \(error.localizedDescription)")
                }
                if let mapItem {
                    selectedMapItemsContinuation?.yield(mapItem)
                }
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        updateMapCoordinates(userLocation.coordinate)
    }
    
    /// - Tag: MapItemDetail
    /// This delegate method allows the selection of a point of interest on the map to show details about the selected item.
    func mapView(_ mapView: MKMapView, selectionAccessoryFor annotation: any MKAnnotation) -> MKSelectionAccessory? {
        // Adapt the presentation to make the best use of space to see the most information possible. The `.automatic` presentation
        // style adapts to either a sheet presentation style or a callout presentation style.
        // The annotation that passes to this delegate method may be either `MKMapItemAnnotation` or `MKMapFeatureAnnotation`, depending
        // on whether the selected annotation is an annotation that the app adds to the map, or a feature that MapKit provides.
        .mapItemDetail(.automatic(presentationViewController: self))
    }
}
