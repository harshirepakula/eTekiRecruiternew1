//
//  PrimaryViewModalTests.swift
//  eTekiRecruiterTests
//
//  Created by Afreen Shaik on 01/10/19.
//  Copyright © 2019 amzurtech. All rights reserved.
//

import XCTest
@testable import eTekiRecruiter
class PrimaryViewModalTests: XCTestCase {
    var createJobModal = CreateJobViewModel()
    
//    func testgetAreasOfExpert(){
//        let areasOfExpertiseResponse = CreateJobResponse(json: ["categories": [["name" : "Application"] , ["name" : "Software"]]], success: true, message: "200 ok")
//        CreateJobStubApi.getAreasOfExpertise = areasOfExpertiseResponse
//        createJobModal.createJobAPI = CreateJobStubApi.self
//        createJobModal.getExpertiseData(requestType: ServerAttributes.areaOfExpertise)
//    }
    override func setUp() {
    
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
