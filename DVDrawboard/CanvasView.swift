//
//  CanvasView.swift
//  CanvasView
//
//  Created by Moin Uddin on 14/9/21.
//

import UIKit
import Photos

class CanvasView: UIView{
    
    var selectedShapeLayer: CAShapeLayer?
    
    var shapes: [DVShape] = []
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let newShapes = shapes.filter{!$0.isRendered}
        
        for shape in newShapes where newShapes.count > 0{
            
            if let count = self.layer.sublayers?.count, shape.layerIndex < count{
                self.layer.sublayers?.remove(at: shape.layerIndex)
            }
            
            let bezierPath = UIBezierPath()
            
            for (i, point) in shape.points.enumerated() where shape.points.count > 0{
                if i == 0{
                    bezierPath.move(to: point)
                }else{
                    bezierPath.addLine(to: point)
                }
            }
            
            let shapeLayer = CAShapeLayer()
            shapeLayer.path = bezierPath.cgPath
            shapeLayer.strokeColor = shape.strokeColor.cgColor
            shapeLayer.fillColor = shape.fillColor.cgColor
            shapeLayer.lineWidth = shape.lineWidth
            
            self.layer.insertSublayer(shapeLayer, at: UInt32(shape.layerIndex))
        }
    }
    
    func moveShapeLayer(_ shapeLayer: CAShapeLayer, to point: CGPoint){
        guard let oldPath = shapeLayer.path else{ return }
        
        
        let newPoint = CGPoint(x: point.x - oldPath.currentPoint.x, y: point.y - oldPath.currentPoint.y)
        
        let bezeirPath = UIBezierPath()
        bezeirPath.cgPath = oldPath
        bezeirPath.apply(CGAffineTransform(translationX: newPoint.x, y: newPoint.y))

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shapeLayer.path = bezeirPath.cgPath
        CATransaction.commit()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectedShapeLayer = nil
        
        guard let point = touches.first?.location(in: self) else {
            return
        }
        
        guard let shapeLayers: [CAShapeLayer] = self.layer.sublayers?.filter({$0.isKind(of: CAShapeLayer.self)}) as? [CAShapeLayer] else{
            return
        }
        
        for shapeLayer in shapeLayers.reversed() {
            if shapeLayer.path?.contains(point) == true{
                selectedShapeLayer = shapeLayer
                break
            }
        }
        
        if selectedShapeLayer == nil{
            let layerIndex = self.layer.sublayers?.count ?? 0
            shapes.append(DVShape(strokeColor: .red, fillColor: .clear, lineWidth: 6, points: [point], layerIndex: layerIndex))
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            return
        }
        
        if let shapeLayer = selectedShapeLayer{
            moveShapeLayer(shapeLayer, to: point)
        }else{
            if var shape = shapes.popLast(){
                shape.points.append(point)
                shapes.append(shape)
                setNeedsDisplay()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else {
            return
        }
        
        if let shapeLayer = selectedShapeLayer{
            moveShapeLayer(shapeLayer, to: point)
        }else{
            if var shape = shapes.popLast(){
                shape.points.append(point)
                shape.isRendered = true
                shapes.append(shape)
                setNeedsDisplay()
            }
        }
        
        selectedShapeLayer = nil
    }
}

extension CanvasView{
    func drawShape(onCanvas canvas: CanvasView,
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
        shapeLayer.fillColor = fillColor
        shapeLayer.strokeColor = strokeColor
        shapeLayer.lineWidth = 4
        
        self.layer.addSublayer(shapeLayer)
    }
}

extension CanvasView{
    func saveImage() async throws -> Bool{
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        self.drawHierarchy(in: self.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if image != nil{
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image!)
            }
            return true
        }
        
        return false
    }
}


