/*
See the LICENSE.txt file for this sample’s licensing information.

Abstract:
The primary view controller you use to display drawings.
*/

import UIKit
import PencilKit

class DrawingViewController: UIViewController, PKCanvasViewDelegate, PKToolPickerObserver, SignatureViewControllerDelegate {
    
    @IBOutlet weak var canvasView: PKCanvasView!
    @IBOutlet weak var stampView: UIScrollView!
    @IBOutlet var undoBarButtonItem: UIBarButtonItem!
    @IBOutlet var redoBarButtonItem: UIBarButtonItem!

    var signature = PKDrawing()
    
    var signDrawingItem: UIBarButtonItem!

    /// The standard amount of overscroll allowed in the canvas.
    static let canvasOverscrollHeight: CGFloat = 500
    
    /// The width for a drawing canvas.
    static let canvasWidth: CGFloat = 768

    @ViewLoading var toolPicker: PKToolPicker
    @ViewLoading var animalStampWrapper: AnimalStampWrapper
    
    @ViewLoading var stampGestureRecognizer: StampGestureRecognizer
    @ViewLoading var stampHoverGestureRecognizer: UIHoverGestureRecognizer

    private var hoverPreviewView: UIView?
    
    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadToolPickerAndTools()
        setUpGestureRecognizers()
    }
    
    private func loadToolPickerAndTools() {
        // Creates a second system pen that's initially the color red from the tool picker.
        let toolPickerRed = UIColor(red: 252 / 255, green: 49 / 255, blue: 66 / 255, alpha: 1)
        let penWidth = PKInkingTool.InkType.pen.defaultWidth
        let secondPen = PKToolPickerInkingItem(type: .pen,
                                               color: toolPickerRed,
                                               width: penWidth,
                                               identifier: "com.example.apple-samplecode.second-pen")
        
        self.animalStampWrapper = AnimalStampWrapper()
        
        // Uses all the standard system items plus the animal stamp and second pen.
        let toolItems = [self.animalStampWrapper.toolItem, secondPen] + PKToolPicker().toolItems
        
        self.toolPicker = PKToolPicker(toolItems: toolItems)
        toolPicker.accessoryItem = UIBarButtonItem(image: UIImage(systemName: "signature"), primaryAction: UIAction(handler: { [self] _ in
            self.signDrawing(sender: nil)
        }))
    }

    private func setUpGestureRecognizers() {
        stampGestureRecognizer = StampGestureRecognizer(target: self, action: #selector(Self.handleTap(_:)))
        view.addGestureRecognizer(stampGestureRecognizer)
        
        stampHoverGestureRecognizer = UIHoverGestureRecognizer(target: self, action: #selector(Self.handleHover(_:)))
        stampHoverGestureRecognizer.allowedTouchTypes = [ NSNumber(value: UITouch.TouchType.pencil.rawValue) ]
        view.addGestureRecognizer(stampHoverGestureRecognizer)
        
        updateGestureRecognizerEnablement()
    }

    /// Sets up the drawing initially.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Sets up the canvas view with the first drawing from the data model.
        canvasView.delegate = self
        canvasView.alwaysBounceVertical = true
        canvasView.backgroundColor = .clear
        
        stampView.delegate = self
        stampView.isUserInteractionEnabled = false

        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        toolPicker.addObserver(self)
        updateLayoutForToolPicker()
        canvasView.becomeFirstResponder()
        
        // Adds a button to sign the drawing in the bottom right-hand corner of the page.
        signDrawingItem = UIBarButtonItem(title: "Sign Drawing", style: .plain, target: self, action: #selector(signDrawing(sender:)))
        navigationItem.rightBarButtonItems?.append(signDrawingItem)
    }
    
    /// Adjusts the canvas scale to the default canvas width when the view resizes.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let canvasScale = canvasView.bounds.width / Self.canvasWidth
        canvasView.minimumZoomScale = canvasScale
        canvasView.maximumZoomScale = canvasScale
        canvasView.zoomScale = canvasScale
        
        // Scrolls to the top.
        updateContentSizeForDrawing()
        canvasView.contentOffset = CGPoint(x: 0, y: -canvasView.adjustedContentInset.top)
    }
    
    // MARK: Actions

    /// Sets a new drawing, and includes an undo action to return to the old drawing.
    func setNewDrawingUndoable(_ newDrawing: PKDrawing) {
        let oldDrawing = canvasView.drawing
        undoManager?.registerUndo(withTarget: self) {
            $0.setNewDrawingUndoable(oldDrawing)
        }
        canvasView.drawing = newDrawing
    }
    
    /// Adds a signature to the current drawing.
    @IBAction func signDrawing(sender: UIBarButtonItem?) {

        // Gets the signature drawing at the canvas scale.
        var transformedSignature = self.signature
        let signatureBounds = transformedSignature.bounds
        let loc = CGPoint(x: canvasView.bounds.maxX, y: canvasView.bounds.maxY)
        let scaledLoc = CGPoint(x: loc.x / canvasView.zoomScale, y: loc.y / canvasView.zoomScale)
        transformedSignature.transform(using: CGAffineTransform(translationX: scaledLoc.x - signatureBounds.maxX,
                                                                           y: scaledLoc.y - signatureBounds.maxY))

        // Adds the signature drawing to the current canvas drawing.
        setNewDrawingUndoable(canvasView.drawing.appending(transformedSignature))
    }
    
    // MARK: Navigation
    
    /// Sets up the signature view controller.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        (segue.destination as? SignatureViewController)?.delegate = self
    }
    
    // MARK: Scroll View Delegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // When the canvas view scrolls, the stamp view is scrolled below.
        guard scrollView == canvasView else { return }
        
        stampView.contentOffset = canvasView.contentOffset
    }
    
    // MARK: Canvas View Delegate
    
    /// Indicates that the drawing changed.
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        updateContentSizeForDrawing()
    }
    
    /// Sets a suitable content size for the canvas view.
    func updateContentSizeForDrawing() {
        // Updates the content size to match the drawing.
        let drawing = canvasView.drawing
        let contentHeight: CGFloat
        
        // Adjusts the content size so it's always bigger than the drawing height.
        if !drawing.bounds.isNull {
            contentHeight = max(canvasView.bounds.height, (drawing.bounds.maxY + DrawingViewController.canvasOverscrollHeight) * canvasView.zoomScale)
        } else {
            contentHeight = canvasView.bounds.height
        }
        canvasView.contentSize = CGSize(width: Self.canvasWidth * canvasView.zoomScale, height: contentHeight)
    }
    
    // MARK: Tool Picker Observer
    
    /// Notifies the observer when the tool picker changes which tool is selected, or the selected tool's properties.
    nonisolated func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) {
        MainActor.assumeIsolated {
            updateGestureRecognizerEnablement()
        }
    }
    
    /// Adjusts the gesture recognizers based on the selected tool.
    /// Don't adjust `PKCanvasView.drawingGestureRecognizer` because that's handled by PencilKit.
    private func updateGestureRecognizerEnablement() {
        let shouldEnableStampGestureRecognizers = toolPicker.selectedToolItemIdentifier == animalStampWrapper.toolItem.identifier
        stampGestureRecognizer.isEnabled = shouldEnableStampGestureRecognizers
        stampHoverGestureRecognizer.isEnabled = shouldEnableStampGestureRecognizers
    }
    
    /// Notifies the observer when the tool picker changes which part of the canvas view it obscures.
    nonisolated func toolPickerFramesObscuredDidChange(_ toolPicker: PKToolPicker) {
        MainActor.assumeIsolated {
            updateLayoutForToolPicker()
        }
    }
    
    /// Notifies the observer when the tool picker shows or hides.
    nonisolated func toolPickerVisibilityDidChange(_ toolPicker: PKToolPicker) {
        MainActor.assumeIsolated {
            updateLayoutForToolPicker()
        }
    }
    
    /// Adjusts the canvas view size when the tool picker changes which part
    /// of the canvas view it obscures.
    ///
    /// Note that the tool picker floats over the canvas in regular size classes, but docks to
    /// the canvas in compact size classes, occupying a part of the screen that the canvas
    /// could otherwise use.
    private func updateLayoutForToolPicker() {
        let obscuredFrame = toolPicker.frameObscured(in: view)
        
        // If the tool picker is floating over the canvas, it also contains
        // undo and redo buttons.
        if obscuredFrame.isNull {
            canvasView.contentInset = .zero
            navigationItem.leftBarButtonItems = []
        }

        // If the tool picker isn't floating over the canvas, inset the bottom
        // of the canvas to the top of the tool picker. In this position,
        // the tool picker no longer displays its own undo and redo buttons.
        else {
            canvasView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: view.bounds.maxY - obscuredFrame.minY, right: 0)
            navigationItem.leftBarButtonItems = [undoBarButtonItem, redoBarButtonItem]
        }
        canvasView.scrollIndicatorInsets = canvasView.contentInset
    }
    
    // MARK: Gesture Handling
    
    @objc
    func handleTap(_ sender: StampGestureRecognizer) {
        if let imageView = animalStampWrapper.stampImageView(for: sender.location(in: stampView), angleInRadians: sender.angleInRadians) {
            insertImageViewUndoable(imageView)
        }
    }
    
    private func insertImageViewUndoable(_ imageView: UIImageView) {
        undoManager?.registerUndo(withTarget: self) {
            $0.removeImageViewUndoable(imageView)
        }
        stampView.addSubview(imageView)
    }
    
    private func removeImageViewUndoable(_ imageView: UIImageView) {
        undoManager?.registerUndo(withTarget: self) {
            $0.insertImageViewUndoable(imageView)
        }
        imageView.removeFromSuperview()
    }
    
    @objc
    func handleHover(_ sender: UIHoverGestureRecognizer) {
#if os(iOS)
        guard UIPencilInteraction.prefersHoverToolPreview else { return }
#endif
        
        let point = sender.location(in: stampView)
        // Subtract the `rollAngle` instead of adding it, because it's defined to go in the opposite
        // direction from `azimuthAngle`.
        let angleInRadians = sender.azimuthAngle(in: sender.view) - sender.rollAngle
        
        switch sender.state {
        case .changed:
            hoverPreviewView?.removeFromSuperview()
            hoverPreviewView = nil
            if let imageView = animalStampWrapper.stampImageView(for: point, angleInRadians: angleInRadians) {
                imageView.alpha = 0.5
                stampView.addSubview(imageView)
                hoverPreviewView = imageView
            } else {
                hoverPreviewView = nil
            }
        default:
            hoverPreviewView?.removeFromSuperview()
            hoverPreviewView = nil
        }
    }
}
