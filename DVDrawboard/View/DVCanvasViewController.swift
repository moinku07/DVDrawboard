//
//  DVCanvasViewController.swift
//  DVDrawboard
//
//  Created by Moin Uddin on 14/9/21.
//

import UIKit

class DVCanvasViewController: UIViewController {

    @IBOutlet weak var pencilButton: UIBarButtonItem!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var undoButton: UIBarButtonItem!
    @IBOutlet weak var redoButton: UIBarButtonItem!
    
    @IBOutlet weak var canvasView: DVCanvasView!
    
    var colorPicker: UIColorPickerViewController = UIColorPickerViewController()
    var selectedColor: UIColor = .black{
        didSet{
            pencilButton.tintColor = selectedColor
            canvasView.selectedColor = selectedColor
            canvasView.updateSelectedShape(strokeColor: selectedColor, fillColor: selectedColor, lineWidth: nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // setup the canvasview and tools
        pencilButton.tintColor = selectedColor
        pencilButton.isSelected = true
        selectButton.isSelected = false
        undoButton.isEnabled = false
        redoButton.isEnabled = false
        
        canvasView.clipsToBounds = true
        canvasView.isUserInteractionEnabled = true
        canvasView.selectedTool = .pencil
        canvasView.selectedColor = selectedColor
        canvasView.delegate = self
        
        colorPicker.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: UIScene.willDeactivateNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        canvasView.restoreRecentState()
        
//        canvasView.addShape(ofType: .triangle)
//
//        canvasView.addShape(ofType: .rectangle, fillColor: UIColor.blue)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIScene.willDeactivateNotification, object: nil)
    }
    
    @objc func willResignActive(){
        canvasView.saveCurrentState()
    }
    
    @IBAction func onSaveTap(_ sender: UIBarButtonItem) {
        canvasView.saveCurrentState()
    }
    
    @IBAction func onLoadTap(_ sender: UIBarButtonItem) {
        canvasView.restoreRecentState()
    }
    
    @IBAction func onPencilTap(_ sender: UIBarButtonItem) {
        if selectButton.isSelected && !sender.isSelected{
            selectButton.isSelected = false
            sender.isSelected = !sender.isSelected
            canvasView.selectedTool = .pencil
        }
    }
    
    @IBAction func onSelectTap(_ sender: UIBarButtonItem) {
        if pencilButton.isSelected && !sender.isSelected{
            pencilButton.isSelected = false
            sender.isSelected = !sender.isSelected
            canvasView.selectedTool = .selection
        }
    }
    
    @IBAction func onColorPickerTap(_ sender: UIBarButtonItem) {
        colorPicker.selectedColor = selectedColor
        self.present(colorPicker, animated: true, completion: nil)
    }
    
    @IBAction func onUndoTap(_ sender: UIBarButtonItem) {
        canvasView.undo()
    }
    
    @IBAction func onRedoTap(_ sender: UIBarButtonItem) {
        canvasView.redo()
    }
    
    @IBAction func onDownloadTap(_ sender: UIBarButtonItem) {
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
    
    @IBAction func onTriangleTap(_ sender: UIBarButtonItem) {
        canvasView.addShape(ofType: .triangle, fillColor: selectedColor, strokeColor: selectedColor)
    }
    
    @IBAction func onRectangleTap(_ sender: UIBarButtonItem) {
        canvasView.addShape(ofType: .rectangle, fillColor: selectedColor, strokeColor: selectedColor)
    }
    
    @IBAction func onCircleTap(_ sender: UIBarButtonItem) {
        canvasView.addShape(ofType: .circle, fillColor: selectedColor, strokeColor: selectedColor)
    }
    
    
    @IBAction func onTrashTap(_ sender: UIBarButtonItem) {
        canvasView.deleteSelectedShape()
    }
    
}

extension DVCanvasViewController: DVCanvasViewDelegate{
    func onUndoChange(_ isEnabled: Bool) {
        undoButton.isEnabled = isEnabled
    }
    
    func onRedoChange(_ isEnabled: Bool) {
        redoButton.isEnabled = isEnabled
    }
    
    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
}

extension DVCanvasViewController: UIColorPickerViewControllerDelegate{
    func colorPickerViewController(_ viewController: UIColorPickerViewController, didSelect color: UIColor, continuously: Bool) {
        selectedColor = color
    }
}
