//
//  Jenkins_iOS_ExampleTests.swift
//  Jenkins iOS ExampleTests
//
//  Created by Kent Sutherland on 4/16/17.
//  Copyright © 2017 Kent Sutherland. All rights reserved.
//

import XCTest
@testable import Jenkins_iOS_Example

class Jenkins_iOS_ExampleTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testIncrement() {
        let counter = Counter()

        counter.increment()

        XCTAssertEqual(counter.count, 1)
    }

    func testIncrementBy() {
        let counter = Counter()

        counter.increment(by: 10)

        XCTAssertEqual(counter.count, 10)
    }
    
}
