//
//  DVShape.swift
//  DVShape
//
//  Created by Moin Uddin on 14/9/21.
//

import UIKit

struct DVShape{
    let strokeColor: UIColor
    let fillColor: UIColor
    let lineWidth: CGFloat
    var points: [CGPoint]
    let layerIndex: Int
    var isRendered: Bool = false
}
