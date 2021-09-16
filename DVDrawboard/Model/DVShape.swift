//
//  DVShape.swift
//  DVShape
//
//  Created by Moin Uddin on 14/9/21.
//

import UIKit

enum DVShapeType: Int, Codable{
    case line, triangle, rectangle, circle
}

struct DVShape: Codable{
    var shapeType: DVShapeType
    var strokeColor: UIColor
    var fillColor: UIColor
    var lineWidth: CGFloat
    var points: [CGPoint]// store the points for the first time drawing/rendering
    var layerIndex: Int // index of the layer where this shape is inserted
    var isRendered: Bool // flag to determine the rendering status
    var paths: [CGPath] // store the paths to be used for future re-drawing; i.e. undo
    var redoPaths: [CGPath] // store the paths to be used for future re-drawing; i.e. redo
    
    private enum CodingKeys: String, CodingKey{
        case shapeType = "shapeType"
        case strokeColor = "strokeColor"
        case fillColor = "fillColor"
        case lineWidth = "lineWidth"
        case points = "points"
        case layerIndex = "layerIndex"
        case isRendered = "isRendered"
        case paths = "paths"
        case redoPaths = "redoPaths"
    }
    
    init(shapeType: DVShapeType = .line,
         strokeColor: UIColor = .black,
         fillColor: UIColor = .black,
         lineWidth: CGFloat = 2,
         points: [CGPoint] = [],
         layerIndex: Int,
         isRendered: Bool = false,
         paths: [CGPath] = [],
         redoPaths: [CGPath] = []){
        
        self.shapeType = shapeType
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.lineWidth = lineWidth
        self.points = points
        self.layerIndex = layerIndex
        self.isRendered = isRendered
        self.paths = paths
        self.redoPaths = redoPaths
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.shapeType = try container.decode(DVShapeType.self, forKey: .shapeType)
        
        if let strokeColorData = try? container.decode(Data.self, forKey: .strokeColor),
            let strokeColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: strokeColorData){
            self.strokeColor = strokeColor
        }else{
            throw DecodingError.dataCorruptedError(forKey: .strokeColor,
                  in: container,
                  debugDescription: "StrokeColor does not match expected format. It should be Data type")
        }
        
        if let fillColorData = try? container.decode(Data.self, forKey: .fillColor),
            let fillColor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: UIColor.self, from: fillColorData){
            self.fillColor = fillColor
        }else{
            throw DecodingError.dataCorruptedError(forKey: .strokeColor,
                  in: container,
                  debugDescription: "FillColor does not match expected format. It should be Data type")
        }
        
        self.lineWidth = try container.decode(CGFloat.self, forKey: .lineWidth)
        self.points = try container.decode([CGPoint].self, forKey: .points)
        self.layerIndex = try container.decode(Int.self, forKey: .layerIndex)
        self.isRendered = try container.decode(Bool.self, forKey: .isRendered)
        
        if let pathData = try? container.decode([Data].self, forKey: .paths), let paths = try? pathData.map({try NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: $0)!.cgPath}){
            self.paths = paths
        }else{
            throw DecodingError.dataCorruptedError(forKey: .paths,
                  in: container,
                  debugDescription: "Paths does not match expected format. It should be [Data] type")
        }
        
        if let redoData = try? container.decode([Data].self, forKey: .redoPaths), let redoPaths = try? redoData.map({try NSKeyedUnarchiver.unarchivedObject(ofClass: UIBezierPath.self, from: $0)!.cgPath}){
            self.redoPaths = redoPaths
        }else{
            throw DecodingError.dataCorruptedError(forKey: .redoPaths,
                  in: container,
                  debugDescription: "RedoPaths does not match expected format. It should be [Data] type")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encodeIfPresent(shapeType, forKey: .shapeType)
        
        if let strokeColorData = try? NSKeyedArchiver.archivedData(withRootObject: strokeColor, requiringSecureCoding: false){
            try container.encodeIfPresent(strokeColorData, forKey: .strokeColor)
        }else{
            let context = EncodingError.Context(codingPath: encoder.codingPath,
                                                      debugDescription: "Invalid strokeColor. It should be UIColor type")
            throw EncodingError.invalidValue(self, context)
        }
        
        if let fillColorData = try? NSKeyedArchiver.archivedData(withRootObject: fillColor, requiringSecureCoding: false){
            try container.encodeIfPresent(fillColorData, forKey: .fillColor)
        }else{
            let context = EncodingError.Context(codingPath: encoder.codingPath,
                                                      debugDescription: "Invalid fillColor. It should be UIColor type")
            throw EncodingError.invalidValue(self, context)
        }
        
        try container.encodeIfPresent(lineWidth, forKey: .lineWidth)
        try container.encodeIfPresent(points, forKey: .points)
        try container.encodeIfPresent(layerIndex, forKey: .layerIndex)
        try container.encodeIfPresent(isRendered, forKey: .isRendered)
        
        do{
            let pathsObject: [Data] = try paths.map{try NSKeyedArchiver.archivedData(withRootObject: UIBezierPath(cgPath: $0), requiringSecureCoding: false)}
            try container.encodeIfPresent(pathsObject, forKey: .paths)
        }catch{
            let context = EncodingError.Context(codingPath: encoder.codingPath,
                                                debugDescription: error.localizedDescription)
            throw EncodingError.invalidValue(self, context)
        }
        
        do{
            let redoObject: [Data] = try redoPaths.map{try NSKeyedArchiver.archivedData(withRootObject: UIBezierPath(cgPath: $0), requiringSecureCoding: false)}
            try container.encodeIfPresent(redoObject, forKey: .redoPaths)
        }catch{
            let context = EncodingError.Context(codingPath: encoder.codingPath,
                                                debugDescription: error.localizedDescription)
            throw EncodingError.invalidValue(self, context)
        }
    }
}

class DVShapeLayer: CAShapeLayer{
    var index: Int = 0
}

