//
//  DVShape.swift
//  DVShape
//
//  Created by Moin Uddin on 14/9/21.
//

import UIKit

enum DVShapeType: Int{
    case line, triangle, rectangle
}

struct DVShape{
    var shapeType: DVShapeType = .line
    var strokeColor: UIColor
    var fillColor: UIColor
    var lineWidth: CGFloat
    var points: [CGPoint] // store the points for the first time drawing/rendering
    var layerIndex: Int // index of the layer where this shape is inserted
    var isRendered: Bool = false // flag to determine the rendering status
    var paths: [CGPath] = [] // store the paths to be used for future re-drawing; i.e. undo
    var redoPaths: [CGPath] = [] // store the paths to be used for future re-drawing; i.e. redo
}

class DVShapeLayer: CAShapeLayer{
    var index: Int = 0
}
