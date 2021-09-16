//
//  DVShapeLayer.swift
//  DVDrawboard
//
//  Created by Moin Uddin on 16/9/21.
//

import UIKit

class DVShapeLayer: CAShapeLayer{
    var index: Int = 0
    var shape: DVShape?
    
    override init() {
        super.init()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    convenience init(_ shape: DVShape){
        self.init()
        
        self.shape = shape

        self.index = shape.layerIndex
        self.strokeColor = shape.strokeColor.cgColor
        self.fillColor = shape.fillColor.cgColor
        self.lineWidth = shape.lineWidth

        if shape.isRendered, shape.paths.count > 0{
            // using existing path for a rendered shape
            self.path = shape.paths.last!
        }else{
            // drawing the path from the points
            let bezierPath = UIBezierPath()

            for (i, point) in shape.points.enumerated() where shape.points.count > 0{
                if i == 0{
                    bezierPath.move(to: point)
                }else{
                    bezierPath.addLine(to: point)
                }
            }

            if [DVShapeType.triangle , DVShapeType.rectangle].contains(shape.shapeType){
                bezierPath.close()
            }

            self.path = bezierPath.cgPath
        }
    }
}


