//
//  CanvasViewController.swift
//  CanvasViewController
//
//  Created by Moin Uddin on 14/9/21.
//

import UIKit

class CanvasViewController: UIViewController {

    @IBOutlet weak var canvasView: CanvasView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        canvasView.isUserInteractionEnabled = true
        
        let points = [CGPoint(x: 50, y: 50), CGPoint(x: 250, y: 50), CGPoint(x: 250, y: 250), CGPoint(x: 50, y: 250), CGPoint(x: 50, y: 50)]
        
        canvasView.drawShape(onCanvas: canvasView, pointArrays: points)
        
        canvasView.drawShape(onCanvas: canvasView, pointArrays: points, fillColor: UIColor.blue.cgColor)
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
    
}
