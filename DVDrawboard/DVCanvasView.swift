//
//  DVCanvasView.swift
//  DVDrawboard
//
//  Created by Moin Uddin on 14/9/21.
//

import PencilKit
import Photos

class DVCanvasView: PKCanvasView{
    
    var selectedShapeLayer: CAShapeLayer?
    
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
        
        for shapeLayer in shapeLayers {
            if shapeLayer.path?.contains(point) == true{
                selectedShapeLayer = shapeLayer
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let shapeLayer = selectedShapeLayer, let point = touches.first?.location(in: self) else {
            return
        }
        
        moveShapeLayer(shapeLayer, to: point)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let shapeLayer = selectedShapeLayer, let point = touches.first?.location(in: self) else {
            return
        }
        
        moveShapeLayer(shapeLayer, to: point)
        
        selectedShapeLayer = nil
    }
}

extension DVCanvasView{
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
