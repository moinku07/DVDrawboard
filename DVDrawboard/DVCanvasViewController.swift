//
//  DVCanvasViewController.swift
//  DVDrawboard
//
//  Created by Moin Uddin on 13/9/21.
//

import UIKit
import PencilKit

class DVCanvasViewController: UIViewController {

    @IBOutlet weak var canvasView: PKCanvasView!
    
    let toolPicker: PKToolPicker = PKToolPicker()
    
    // Define the canvas width as the current device screen width
    let canvasWidth: CGFloat = UIScreen.main.bounds.size.width
    
    // store the current drawing state
    var drawing: PKDrawing = PKDrawing()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the canvas view
        canvasView.delegate = self
        canvasView.drawing = drawing
        
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        // Define soints on strokePath
        let strokeSize = CGSize(width: 10, height: 10)
        let strokePoint1 = createStrokePoint(for: CGPoint(x: 50, y: 50), withSize: strokeSize)
        let strokePoint2 = createStrokePoint(for: CGPoint(x: 250, y: 50), withSize: strokeSize)
        let strokePoint3 = createStrokePoint(for: CGPoint(x: 250, y: 250), withSize: strokeSize)
        let strokePoint4 = createStrokePoint(for: CGPoint(x: 50, y: 250), withSize: strokeSize)
        
        // Define strokePath
        let strokePath = PKStrokePath(controlPoints: [strokePoint1, strokePoint2, strokePoint3, strokePoint4], creationDate: Date())
        
        // Define stroke
        let stroke = PKStroke(ink: PKInk(.pen, color: .red), path: strokePath)
        
        canvasView.drawing.strokes.append(stroke)
    }


    func createStrokePoint(for location: CGPoint, withSize size: CGSize) -> PKStrokePoint{
        return PKStrokePoint(location: location, timeOffset: TimeInterval.init(), size: size, opacity: 2, force: 1, azimuth: 1, altitude: 1)
    }
    
}

extension DVCanvasViewController: PKCanvasViewDelegate{
    
}

