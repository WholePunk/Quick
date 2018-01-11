//
//  QuickTests.swift
//  QuickTests
//
//  Created by Bob Warwick on 2018-01-10.
//  Copyright © 2018 Whole Punk Creators Ltd. All rights reserved.
//

import XCTest
@testable import Quick

class QuickTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    /****************/
    /* PARSER TESTS */
    /****************/
    
      func testEmptySource() {
          let source = ""
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMultilineStatement() {
          let source = """

          foo = "a"
          foo = bar

          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testEmptyArray() {

          let source = """
          foo = []
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testArrayOfIntegers() {

          let source = """
          foo = [1, 2, 3, 4, 5, 6]
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testArrayOfFloats() {

          let source = """
          foo = [1.1, 2.2, 3.3, 4.6, 5.6, 6.6]
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testArrayOfStrings() {

          let source = """
          foo = ["first", "second", "third"]
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testArrayOfBools() {

          let source = """
          foo = [true, false, true, false, false]
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithNoArgument() {

          let source = """
          foo = someMethod()
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithIntArgument() {

          let source = """
          foo = someMethod(1)
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithFloatArgument() {

          let source = """
          foo = someMethod(1.0)
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithStringArgument() {

          let source = """
          foo = someMethod("Test")
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithTrueArgument() {

          let source = """
          foo = someMethod(true)
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithFalseArgument() {

          let source = """
          foo = someMethod(false)
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithArrayArgument() {

          let source = """
          if someMethod([1, 2, 4]) {
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithIntArguments() {

          let source = """
          foo = someMethod(1, 2)
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithFloatArguments() {

          let source = """
          while someMethod(1.0, 2.0) {
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithStringArguments() {

          let source = """
          test = someMethod("Test", "Nobody listens to zathras")
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithTrueArguments() {

          let source = """
          test = someMethod(true, true)
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithFalseArguments() {

          let source = """
          test = someMethod(false, false)
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testMethodCallWithArrayArguments() {

          let source = """
          test = someMethod([1, 2, 4], ["hello"])
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignIdentifierToIdentifier() {

          let source = """
          foo = bar
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignIdentifierToProperty() {

          let source = """
          foo.baz = bar
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignIntToIdentifier() {

          let source = """
          foo = 1
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignIntToProperty() {

          let source = """
          foo.baz = 2
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignFloatToIdentifier() {

          let source = """
          foo = 1.0
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignFloatToProperty() {

          let source = """
          foo.baz = 2.1
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignStringToIdentifier() {

          let source = """
          foo = "comic"
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignStringToProperty() {

          let source = """
          foo.baz = "sans is for dogs"
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignTrueToIdentifier() {

          let source = """
          foo = true
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignTrueToProperty() {

          let source = """
          foo.baz = true
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignFalseToIdentifier() {

          let source = """
          foo = false
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignFalseToProperty() {

          let source = """
          foo.baz = false
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignArrayToIdentifier() {

          let source = """
          foo = [1, 2, 42]
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testAssignArrayToProperty() {

          let source = """
          foo.baz = ["a", 1, foo]
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testIfStatement() {

          let source = """
          if true {
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfStatementWithContentBlock() {

          let source = """
          if true {
              foo = bar
              doFrob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfStatementWithContentBlockAndEqualsComparison() {

          let source = """
          if foo == "xyzzy" {
              foo = bar
              doFrob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfStatementWithContentBlockAndNotEqualComparison() {

          let source = """
          if foo != "xyzzy" {
              foo = bar
              doFrob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfStatementWithContentBlockAndLessThanComparison() {

          let source = """
          if foo < "xyzzy" {
              foo = bar
              doFrob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfStatementWithContentBlockAndLessThanOrEqualComparison() {

          let source = """
          if foo <= "xyzzy" {
              foo = bar
              doFrob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfStatementWithContentBlockAndGreaterThanComparison() {

          let source = """
          if foo > "xyzzy" {
              foo = bar
              doFrob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfStatementWithContentBlockAndGreaterThanOrEqualComparison() {

          let source = """
          if foo >= "xyzzy" {
              foo = bar
              doFrob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfStatementWithContentBlockAndNotComparison() {

          let source = """
          if !foo {
              foo = bar
              doFrob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfStatementWithContentBlockAndIdentifierComparison() {

          let source = """
          if foo {
              foo = bar
              doFrob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testWhileStatement() {

          let source = """
          while true {
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testWhileStatementWithContentBlock() {

          let source = """
          while true {
              test = frob
              doSomething(test)
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testForStatementWithIdentifierAndNoContentBlock() {

          let source = """
          for item in items {
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testForStatementWithArrayAndNoContentBlock() {

          let source = """
          for item in [1, 2, 3] {
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testForStatementWithContentBlock() {

          let source = """
          for item in [1, 2, 3] {
              foo = bar
              frob()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testAddition() {

          let source = """
          a = 2 + 2
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testChainedAddition() {

          let source = """
          xyzzy = 2 + 2 + 3
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testSubtraction() {

          let source = """
          foo = 2 - 2
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testChainedSubtraction() {

          let source = """
          bar = 2 - 2 - 3
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testMultiplication() {

          let source = """
          frob = 2 * 2
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testChainedMultiplication() {

          let source = """
          zork = 2 * 2 * 3
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testDivision() {

          let source = """
          zathras = 2 / 2
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testChainedDivision() {

          let source = """
          foobar = 2 / 2 / 3
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testModulus() {

          let source = """
          juno = 2 % 2
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testChainedModulus() {

          let source = """
          whatevs = 2 % 2 % 3
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testAdditionWithIdentifier() {

          let source = """
          frob = 2 + frob
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testAssignmentOfMathExpression() {

          let source = """
          foo = 2 + 2
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testAssignmentOfLogicalExpression() {

          let source = """
          foo = true == false
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testAssignmentOfString() {

          let source = """
          foo = "this is a test"
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testAssignmentOfMethodCall() {

          let source = """
          foo = fooBar(frob)
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testAssignmentOfArray() {

          let source = """
          foo = [1, 2, 3]
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)

      }

      func testIfWithAnd() {

          let source = """
          if true and false {
              doSomething()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testIfWithOr() {

          let source = """
          if true or false {
              doSomething()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

      func testIfWithComplexStatement() {

          let source = """
          foo = 1 == 2
          bar = 2 > 3
          if foo and bar {
              doSomething()
          }
          """
          let parser = Parser()
          let result = parser.parse(fromSource: source)
          assert(result == true)
      }

}
