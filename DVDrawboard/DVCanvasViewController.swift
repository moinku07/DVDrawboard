//
//  DVCanvasViewController.swift
//  DVDrawboard
//
//  Created by Moin Uddin on 13/9/21.
//

import UIKit
import PencilKit

class DVCanvasViewController: UIViewController {

    @IBOutlet weak var canvasView: DVCanvasView!
    
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
        
        let points = [CGPoint(x: 50, y: 50), CGPoint(x: 250, y: 50), CGPoint(x: 250, y: 250), CGPoint(x: 50, y: 250), CGPoint(x: 50, y: 50)]
        
        //canvasView.drawing.strokes += makeStroke(from: points, size: CGSize(width: 5, height: 5))
        
        drawShape(onCanvas: canvasView, pointArrays: points)
    }
    
    @IBAction func onAddButtonTap(_ sender: UIBarButtonItem) {
        if canvasView.isFirstResponder{
            canvasView.resignFirstResponder()
        }else{
            canvasView.becomeFirstResponder()
        }
    }
    
    @IBAction func onSaveTap(_ sender: UIBarButtonItem) {
        Task(priority: .userInitiated) {
            do{
                let success = try await canvasView.saveImage()
                if success{
                    let alert = UIAlertController(title: "Success", message: "Photo was saved", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }catch{
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
    }
    
    func makeStroke(from pointArrays: [CGPoint],
              ink: PKInk = PKInk(.pen, color: .black),
              size: CGSize = CGSize(width: 2, height: 2),
              opacity: CGFloat = 1,
              force: CGFloat = 1,
              azimuth: CGFloat = 0,
              altitude: CGFloat = 0) -> [PKStroke]{
        
        guard pointArrays.count > 0 else {
            return []
        }
        
        var strokes: [PKStroke] = []
        
        let strokePoints = pointArrays.enumerated().map { index, point in
            PKStrokePoint(location: point, timeOffset: 0.1 * TimeInterval(index), size: size, opacity: opacity, force: force, azimuth: azimuth, altitude: altitude)
        }
        
        var startStrokePoint = strokePoints.first!
        
        for strokePoint in strokePoints {
            let path = PKStrokePath(controlPoints: [startStrokePoint, strokePoint], creationDate: Date())
            strokes.append(PKStroke(ink: ink, path: path))
            startStrokePoint = strokePoint
        }
        
        return strokes
    }
    
    func drawShape(onCanvas canvas: DVCanvasView,
                   pointArrays: [CGPoint],
                   fillColor: CGColor = UIColor.black.cgColor,
                   strokeColor: CGColor = UIColor.black.cgColor,
                   lineWidth: CGFloat = 2){
        
        guard pointArrays.count > 0 else { return }
        
        var pointArrays = pointArrays
        
        let shapeLayerPath = CGMutablePath()
        shapeLayerPath.move(to: pointArrays.first!)
        
        pointArrays.remove(at: 0)
        
        for point in pointArrays where pointArrays.count > 0{
            shapeLayerPath.addLine(to: point)
        }
        
        shapeLayerPath.closeSubpath()
        
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = shapeLayerPath
        shapeLayer.fillColor = UIColor.red.cgColor
        shapeLayer.strokeColor = UIColor.black.cgColor
        shapeLayer.lineWidth = 4
        
//        let layerCount = canvasView.layer.sublayers?.count ?? 0
//        let insertAt = layerCount - 2 > 0 ? layerCount - 2 : 0
//
//        canvasView.layer.insertSublayer(shapeLayer, at: UInt32(2))
        canvasView.layer.addSublayer(shapeLayer)
    }
}

extension DVCanvasViewController: PKCanvasViewDelegate{
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        print("here")
    }
}

