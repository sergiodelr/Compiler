import XCTest

import projectTests

var tests = [XCTestCaseEntry]()
tests += projectTests.allTests()
XCTMain(tests)
