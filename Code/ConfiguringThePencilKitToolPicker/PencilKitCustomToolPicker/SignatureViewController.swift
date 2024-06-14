/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
A view controller that shows the signature pane.
*/

import UIKit
import PencilKit

@MainActor protocol SignatureViewControllerDelegate: NSObjectProtocol {
    var signature: PKDrawing { get set }
}

class SignatureViewController: UIViewController {
    
    @IBOutlet weak var canvasView: PKCanvasView!
    @IBOutlet weak var colorSegmentedControl: UISegmentedControl!
    
    weak var delegate: SignatureViewControllerDelegate!
    
    // MARK: View Life Cycle
    
    /// Sets up the drawing initially.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // A person can use both their finger or a pencil on this canvas.
        canvasView.drawingPolicy = .anyInput
        
        // Gets the signature drawing from the delegate.
        canvasView.drawing = delegate.signature
        colorChanged(self)
        
        // Note that no tool picker is associated with the signature canvas.
        // As soon as the canvas view becomes first responder, the system hides
        // the tool picker that the main drawing canvas shows.
        canvasView.becomeFirstResponder()
    }
    
    /// Saves the modified signature drawing when the view disappears.
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        delegate.signature = canvasView.drawing
    }
    
    // MARK: Actions
    
    /// Sets the ink to black or blue.
    @IBAction func colorChanged(_ sender: Any) {
        let colors: [UIColor] = [.black, .blue]
        let selectedColor = colors[colorSegmentedControl.selectedSegmentIndex]
        canvasView.tool = PKInkingTool(.pen, color: selectedColor, width: 20)
    }
    
    /// Clears the signature drawing.
    @IBAction func clearSignature(_ sender: Any) {
        canvasView.drawing = PKDrawing()
    }
}
