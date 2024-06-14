/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The UI extension that performs authentication of the user if the non-UI extension reports that authentication is required.
*/

import UIKit
import SwiftUI
import PassKit

/**
 The UI extension's principal class.
 */
class WUIExtHandler: UIViewController, PKIssuerProvisioningExtensionAuthorizationProviding {

    var completionHandler: ((PKIssuerProvisioningExtensionAuthorizationResult) -> Void)?
    
    /**
     Call this method after the view controller loads its view hierarchy into memory.
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create an instance of the SwiftUI view.
        // Pass the completion handler to the SwiftUI view.
        let swiftUIView = WUIExtView(completionHandler: completionHandler)
        
        // Create a `UIHostingController` with the extension's SwiftUI view as
        // its root view.
        let controller = UIHostingController(rootView: swiftUIView)
        
        // Add the `UIHostingController` view to the destination
        // view controller.
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        
        // Set and activate the constraints for the extension's SwiftUI view.
        NSLayoutConstraint.activate([
            controller.view.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 1),
            controller.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 1),
            controller.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            controller.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Notify the child view controller that the move is complete.
        controller.didMove(toParent: self)
    }
}
