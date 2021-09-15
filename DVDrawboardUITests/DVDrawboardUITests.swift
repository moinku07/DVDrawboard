//
//  DVDrawboardUITests.swift
//  DVDrawboardUITests
//
//  Created by Moin Uddin on 13/9/21.
//

import XCTest

class DVDrawboardUITests: XCTestCase {
    
    let app = XCUIApplication()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func test_01_when_i_open_the_app_then_i_should_see_a_canvas(){
        // When I (user) open the app
        app.launch()
        
        // Then I should see a canvas
        let canvasView = app.otherElements["DVCanvasView"]
        if(!canvasView.waitForExistence(timeout: 5)){
            XCTFail("Canvas View does not exist")
        }
    }
}
