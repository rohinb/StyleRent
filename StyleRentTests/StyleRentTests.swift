//
//  StyleRentTests.swift
//  StyleRentTests
//
//  Created by Rohin Bhushan on 5/23/18.
//  Copyright © 2018 Rohin Bhushan. All rights reserved.
//

import XCTest

class StyleRentTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
		DB.shared().delegate = self
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let basicUser = User()
		basicUser?._emailAddress = "test1-email"
		basicUser?._name = "Test 1"
		basicUser?._password = "Test 1 Password"
		DB.shared().createUser(user: basicUser)
		// TODO: Make test work for delegate callback model
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
