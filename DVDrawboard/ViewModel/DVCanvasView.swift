//
//  DVCanvasView.swift
//  DVDrawboard
//
//  Created by Moin Uddin on 14/9/21.
//

import UIKit
import Photos

// Delegate protocol
protocol DVCanvasViewDelegate{
    func onUndoChange(_ isEnabled: Bool)
    func onRedoChange(_ isEnabled: Bool)
    func showAlert(_ title: String, message: String)
}

class DVCanvasView: UIView{
    
    enum DVTool: Int{
        case pencil, selection
    }
    
    public var selectedTool: DVTool = .pencil
    public var selectedColor: UIColor = .black
    
    private var selectedShapeLayer: DVShapeLayer?
    
    var delegate: DVCanvasViewDelegate?
    
    private var shapes: [DVShape] = []{
        didSet{
            delegate?.onUndoChange(shapes.count > 0)
        }
    }
    
    private var redoShapes: [DVShape] = []{
        didSet{
            delegate?.onRedoChange(redoShapes.count > 0)
        }
    }
}

extension DVCanvasView{
    
    // MARK: - Saving current state
    public func saveCurrentState(){
        let userDefautls = UserDefaults.standard
        
        do{
            let shapeData = try JSONEncoder().encode(shapes)
            userDefautls.set(shapeData, forKey: "kDVShapes")
            
            let redoData = try JSONEncoder().encode(redoShapes)
            userDefautls.set(redoData, forKey: "kDVRedoShapes")
            
            UserDefaults.standard.synchronize()
        }catch{
            print(error.localizedDescription)
        }
    }
    
    // MARK: - Restore saved state
    public func restoreRecentState(){
        let userDefautls = UserDefaults.standard
        
        do{
            if let shapeData = userDefautls.value(forKey: "kDVShapes") as? Data{
                let shapes = try JSONDecoder().decode([DVShape].self, from: shapeData)
                self.shapes = shapes.map{
                    var shape = $0
                    // reset layer index
                    shape.layerIndex -= 1
                    return shape
                }
            }
            if let redoShapesData = userDefautls.value(forKey: "kDVRedoShapes") as? Data{
                let redoShapes = try JSONDecoder().decode([DVShape].self, from: redoShapesData)
                self.redoShapes = redoShapes.map{
                    var shape = $0
                    // reset layer index
                    shape.layerIndex -= 1
                    return shape
                }
            }
        }catch{
            print(error.localizedDescription)
        }
        
        // Frist clear all current shapes
        self.layer.sublayers?.removeAll()
        
        // Draw the restored shapes on the canvas
        drawShapes(.all)
    }
}

extension DVCanvasView{
    // MARK: - Move Shape Layer
    
    /// This method moves the shape layer to the new position
    private func moveShapeLayer(_ shapeLayer: DVShapeLayer, to point: CGPoint, didMoveEnd: Bool = false){
        // Check if the shapelayer has path
        guard let oldPath = shapeLayer.path else{ return }
        
        // Calculate the new position for the layer
        let newPoint = CGPoint(x: point.x - oldPath.currentPoint.x, y: point.y - oldPath.currentPoint.y)
        
        let bezeirPath = UIBezierPath()
        bezeirPath.cgPath = oldPath
        bezeirPath.apply(CGAffineTransform(translationX: newPoint.x, y: newPoint.y))

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        shapeLayer.path = bezeirPath.cgPath
        CATransaction.commit()
        
        if didMoveEnd, let index = shapes.firstIndex(where: {$0.id == shapeLayer.shape?.id}){
            shapes[index].paths.append(bezeirPath.cgPath)
        }
    }
    
    // MARK: - Touch Event Handlers
    
    // Preventing extending/overriding this method
    // Handling the touch begin event to determine whether the user is selecting an existing shape or started a new drawing
    final override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Set the selection to nil to start over
        selectedShapeLayer = nil
        
        guard let point = touches.first?.location(in: self) else {
            return
        }
        
        if selectedTool == .selection{
            // Find if the touch event intersect any DVShapeLayer
            if let shapeLayers: [DVShapeLayer] = self.layer.sublayers?.filter({$0.isKind(of: DVShapeLayer.self)}) as? [DVShapeLayer]{
                for shapeLayer in shapeLayers.reversed() {
                    if shapeLayer.path?.contains(point) == true{
                        selectedShapeLayer = shapeLayer
                        break
                    }
                }
            }
        }else if selectedTool == .pencil{
            // Create a new shape
            let layerIndex = self.layer.sublayers?.count ?? 0
            shapes.append(DVShape(strokeColor: selectedColor, fillColor: .clear, lineWidth: 6, points: [point], layerIndex: layerIndex))
            drawShapes()
            
            // Invalidate all redos when a new shape is created
            redoShapes.removeAll()
        }
    }
    
    // Preventing extending/overriding this method
    // Handle the touch move event to either draw shape or move the selected shape
    final override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        
        if selectedTool == .selection, let shapeLayer = selectedShapeLayer{
            // when the tool is a selection tool and a shape is selected
            // the shape can be moved to a new position
            moveShapeLayer(shapeLayer, to: point)
        }else if selectedTool == .pencil{
            // continue drawing the current shape
            if var shape = shapes.popLast(){
                shape.points.append(point)
                shapes.append(shape)
                drawShapes()
            }
        }
    }
    
    // Preventing extending/overriding this method
    // Handle the touch end event to complete the current drawing event
    final override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let point = touches.first?.location(in: self) else { return }
        
        if selectedTool == .selection, let shapeLayer = selectedShapeLayer{
            // end moving the selected shape to the final position
            moveShapeLayer(shapeLayer, to: point, didMoveEnd: true)
        }else if selectedTool == .pencil{
            // end the current shape by setting isRendered true
            if var shape = shapes.popLast(){
                shape.isRendered = true
                shapes.append(shape)
            }
        }
    }
}

extension DVCanvasView{
    // Determine the shape rendering state
    enum DVShapeRenderType: Int{
        case all, rendered, unrendered
    }
    
    // MARK: - Add a shape
    /// This method adds a new shape on the canvas
    public func addShape(ofType type: DVShapeType,
                         fillColor: UIColor = UIColor.black,
                         strokeColor: UIColor = UIColor.black,
                         lineWidth: CGFloat = 2){
        
        let midPoint = self.center
        
        var paths: [CGPath] = []
        var points: [CGPoint] = [
            CGPoint(x: midPoint.x - 100, y: midPoint.y),
            CGPoint(x: midPoint.x + 100, y: midPoint.y)
        ]
        
        if type == .triangle{
            // predefined triangle
            points = [
                CGPoint(x: midPoint.x, y: midPoint.y - 100),
                CGPoint(x: midPoint.x + 100, y: midPoint.y + 50),
                CGPoint(x: midPoint.x - 100, y: midPoint.y + 50)
            ]
        }else if type == .rectangle{
            // predefined rectangle
            points = [
                CGPoint(x: midPoint.x - 100, y: 50),
                CGPoint(x: midPoint.x + 100, y: 50),
                CGPoint(x: midPoint.x + 100, y: 250),
                CGPoint(x: midPoint.x - 100, y: 250)
            ]
        }else if type == .circle{
            // predefined circle
            points = [midPoint]
            // because circle is different, we set the path for it
            paths = [UIBezierPath(ovalIn: CGRect(x: midPoint.x - 50, y: midPoint.y - 50, width: 100, height: 100)).cgPath]
        }
        
        let layerIndex = self.layer.sublayers?.count ?? 0
        let shape = DVShape(shapeType: type,
                            strokeColor: strokeColor,
                            fillColor: fillColor,
                            lineWidth: lineWidth,
                            points: points,
                            layerIndex: layerIndex,
                            isRendered: type == .circle ? true : false,
                            paths: paths)
        if var shape = drawShape(using: shape){
            shape.isRendered = true
            shapes.append(shape)
        }
    }
    
    // MARK: - Render Shapes
    /// This method draw the shapes on the canvas
    /// By default, it draws thes shapes that have not rendered yet
    private func drawShapes(_ type: DVShapeRenderType = .unrendered){
        for (index, shape) in shapes.enumerated() where shapes.count > 0{
            
            // skiping based on the type
            if (type == .unrendered && shape.isRendered) || (type == .rendered && !shape.isRendered){
                continue
            }
            
            if let shape = drawShape(using: shape){
                shapes[index] = shape
            }
        }
    }
    
    // MARK: - Draw shape
    
    /// Draw a shape using the DVShape and returns the updated DVShape
    private func drawShape(using shape: DVShape) -> DVShape?{
        // Check if the shape has at least one point or path
        guard shape.points.count > 0 || shape.paths.count > 0 else{ return nil }
        
        var shape = shape
        
        // remove if the shape was partially rendered (during the touch move)
        if shape.layerIndex > -1, let count = self.layer.sublayers?.count, shape.layerIndex < count{
            self.layer.sublayers?.remove(at: shape.layerIndex)
        }else{
            shape.layerIndex = self.layer.sublayers?.count ?? 0
        }
        
        // creating a DVShapeLayer
        let shapeLayer = DVShapeLayer(shape)
        
        // saving the path
        if let path = shapeLayer.path{
            shape.paths = [path]
        }
        
        // finally, insert the shape to the desired sub layer location
        self.layer.insertSublayer(shapeLayer, at: UInt32(shape.layerIndex))
        
        return shape
    }
}

extension DVCanvasView{
    // MARK: - Update shape attributes
    final public func updateSelectedShape(strokeColor: UIColor?, fillColor: UIColor?, lineWidth: CGFloat?){
        if let dvlayer = selectedShapeLayer, let index = shapes.firstIndex(where: {$0.id == dvlayer.shape?.id}){
            var shape = shapes[index]
            if let strokeColor = strokeColor {
                shape.strokeColor = strokeColor
                dvlayer.strokeColor = strokeColor.cgColor
            }
            if let fillColor = fillColor, shape.shapeType != .line { // we do not want to update fill color for line
                shape.fillColor = fillColor
                dvlayer.fillColor = fillColor.cgColor
            }
            if let lineWidth = lineWidth {
                shape.lineWidth = lineWidth
                dvlayer.lineWidth = lineWidth
            }
            shapes[index] = shape
        }
    }
    
    // MARK: - Undo
    /// This method undo the last update
    final public func undo(){
        if shapes.count > 0, var shape = shapes.popLast(){
            /*
             // TODO: - Future Improvements
            // when a shape has more than one path components
            // that means the shape was moved from it's original position
            // we want to undo the position first
            if shape.paths.count > 1{
                if let mostRecentPath = shape.paths.popLast(), let layer = self.layer.sublayers?[shape.layerIndex] as? DVShapeLayer{
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    layer.path = mostRecentPath
                    CATransaction.commit()
                    shape.redoPaths.append(mostRecentPath)
                }
                shapes.removeLast()
                shapes.append(shape)
            }else{*/
            
            if let layerIndex = self.layer.sublayers?.firstIndex(where: {($0 as? DVShapeLayer)?.shape?.id == shape.id}){
                self.layer.sublayers?.remove(at: layerIndex)
                shape.layerIndex = -1
                redoShapes.append(shape)
            }
        }
    }
    
    // MARK: - Redo
    /// This method redo the last update
    final public func redo(){
        if redoShapes.count > 0{
            
            /*
             // TODO: - Future Improvements
            // when a shape has more than one redo path components
            // that means the shape was moved from it's most recent position
            // we want to redo the position first
            
            let sublayerCount = self.layer.sublayers?.count ?? 0
            
            if shape.layerIndex < sublayerCount, shape.redoPaths.count > 0, let layer = self.layer.sublayers?[shape.layerIndex] as? DVShapeLayer{
                if let mostRecentPath = shape.redoPaths.popLast(){
                    CATransaction.begin()
                    CATransaction.setDisableActions(true)
                    layer.path = mostRecentPath
                    CATransaction.commit()
                    shape.paths.append(mostRecentPath)
                }
                redoShapes.removeLast()
                redoShapes.append(shape)
            }else
            */
            if var shape = redoShapes.popLast(){
                shape.layerIndex = self.layer.sublayers?.count ?? 0
                if var renderedShape = drawShape(using: shape){
                    renderedShape.isRendered = true
                    shapes.append(renderedShape)
                }
            }
        }
    }
    
    // MARK: - Delete selected shape
    final public func deleteSelectedShape(){
        if let shapeLayer = selectedShapeLayer, let index = shapes.firstIndex(where: {$0.id == shapeLayer.shape?.id}){
            if let shapeIndex = self.layer.sublayers?.firstIndex(where: { ($0 as? DVShapeLayer) == shapeLayer}){
                let shape = shapes[index]
                redoShapes = [shape]
                shapes.remove(at: index)
                self.layer.sublayers?.remove(at: shapeIndex)
            }else{
                delegate?.showAlert("Warning", message: "No shape was selected. Please select a shape.")
            }
        }else{
            delegate?.showAlert("Warning", message: "No shape was selected. Please select a shape.")
        }
    }
    
    // MARK: - Save as Image
    final public func saveImage() async throws -> Bool{
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
