//
//  ASTObjects.swift
//  Quick
//
//  Created by Bob Warwick on 2018-01-10.
//  Copyright © 2018 Whole Punk Creators Ltd. All rights reserved.
//

/************************/
/* Abstract Syntax Tree */
/************************/

import Alamofire
import SWXMLHash

class QuickObject : NSObject {
    
    var parser : Parser?
    var sourceLine = -1
    
    func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Object\n")
    }
    
    func checkSymbols(symbolTable : QuickSymbolTable) {
        
    }
    
    func addSymbols(symbolTable : QuickSymbolTable) {
        
    }
    
    func getType() -> String {
        return ""
    }
    
    func execute() -> Any? {
        return nil
    }
        
}

class QuickStatement : QuickObject {
    
    var content : QuickObject?
    var parent : QuickMultilineStatement?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Statement\n")
        content?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        content?.checkSymbols(symbolTable: symbolTable)
    }
    
    override func execute() -> Any? {
        let returnValue = content?.execute()
        return returnValue
    }
    
}

class QuickMultilineStatement : QuickObject {
    
    var content : Array<QuickStatement> = []
    var parent : QuickObject?
    
    func addStatement(_ statement: QuickStatement) {
        content.append(statement)
    }
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick MultilineStatement\n")
        for statement in content {
            statement.printDebugDescription(withLevel: withLevel + 1)
        }
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        symbolTable.pushScope()
        for statement in content {
            statement.checkSymbols(symbolTable: symbolTable)
        }
        symbolTable.popScope()
    }
    
    override func execute() -> Any? {
        QuickSymbolTable.rootSymbolTableForParser(parser!).pushScope()
        for statement in content {
            statement.checkSymbols(symbolTable: QuickSymbolTable.rootSymbolTableForParser(parser!))
        }
        for statement in content {
            let returnValue = statement.execute()
            if returnValue != nil {
                QuickSymbolTable.rootSymbolTableForParser(parser!).popScope()
                return returnValue
            }
        }
        QuickSymbolTable.rootSymbolTableForParser(parser!).popScope()
        return nil
    }
    
}

class QuickString : QuickObject {
    
    var content = ""
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick String (\(content))\n")
    }
    
    override func getType() -> String {
        return "String"
    }
    
    override func execute() -> Any? {
        QuickMemory.shared.pushObject(content, inStackForParser: self.parser!)
        return nil
    }

}

class QuickIdentifier : QuickObject {
    
    var content = ""
    var subscriptValue : QuickValue?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Identifier (\(content))\n")
    }
    
    override func addSymbols(symbolTable : QuickSymbolTable) {
        symbolTable.addSymbol(content, ofType: "")
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        
        if subscriptValue != nil {
            if QuickSymbolTable.rootSymbolTableForParser(parser!).getType(ofIdentifier: content) != "Array" && QuickSymbolTable.rootSymbolTableForParser(parser!).getType(ofIdentifier: content) != "Dictionary" {
                QuickError.shared.setErrorMessage("Subscripts are only allowed on arrays and dictionaries", withLine: -2)
            }
            if QuickSymbolTable.rootSymbolTableForParser(parser!).getType(ofIdentifier: content) == "Array" {
                if subscriptValue?.getType() != "Integer" {
                    QuickError.shared.setErrorMessage("Array subscripts must be integers", withLine: -2)
                }
            }
            if QuickSymbolTable.rootSymbolTableForParser(parser!).getType(ofIdentifier: content) == "Dictionary" {
                if subscriptValue?.getType() != "String" {
                    QuickError.shared.setErrorMessage("Dictionary subscripts must be strings", withLine: -2)
                }
            }
        }
        
        
        
        symbolTable.expectSymbol(content)
    }
    
    override func getType() -> String {
        
        guard QuickSymbolTable.rootSymbolTableForParser(parser!) != nil else {
            return "Symbol Table Error"
        }
        
        if subscriptValue != nil {
            return ""
        }
        
        return QuickSymbolTable.rootSymbolTableForParser(parser!).getType(ofIdentifier: content)
    }
    
    override func execute() -> Any? {
        let storedValue = QuickMemory.shared.getObjectForKey(content, inHeapForParser: self.parser!)
        if storedValue == nil {
            QuickError.shared.setErrorMessage("Corrupted heap", withLine: -2)
        } else {
            
            if subscriptValue == nil {
                QuickMemory.shared.pushObject(storedValue, inStackForParser: self.parser!)
            } else {
                if QuickSymbolTable.rootSymbolTableForParser(parser!).getType(ofIdentifier: content) == "Array" {
                    let parametersArray = storedValue as! Array<Any>
                    subscriptValue?.execute()
                    let subscriptInt = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! Int
                    if subscriptInt >= parametersArray.count {
                        QuickError.shared.setErrorMessage("Array index is out of bounds", withLine: -2)
                        QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
                    } else {
                        QuickMemory.shared.pushObject(parametersArray[subscriptInt], inStackForParser: self.parser!)
                    }
                } else if QuickSymbolTable.rootSymbolTableForParser(parser!).getType(ofIdentifier: content) == "Dictionary" {
                    subscriptValue?.execute()
                    let subscriptString = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! String
                    let dictionary = storedValue as! Dictionary<String, Any>
                    if dictionary[subscriptString] == nil {
                        QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
                    } else {
                        QuickMemory.shared.pushObject(dictionary[subscriptString]!, inStackForParser: self.parser!)
                    }
                } else {
                    QuickMemory.shared.pushObject("Could not dereference value from unknown type", inStackForParser: self.parser!)
                }
            }
            
        }
        return nil
    }
    
}

class QuickInteger : QuickObject {
    
    var content : Int = 0
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Integer (\(content))\n")
    }
    
    override func getType() -> String {
        return "Integer"
    }
    
    override func execute() -> Any? {
        QuickMemory.shared.pushObject(content, inStackForParser: self.parser!)
        return nil
    }
    
}

class QuickFloat : QuickObject {
    
    var content : Float = 0
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Float (\(content))\n")
    }
    
    override func getType() -> String {
        return "Float"
    }

    override func execute() -> Any? {
        QuickMemory.shared.pushObject(content, inStackForParser: self.parser!)
        return nil
    }

}

class QuickTrue : QuickObject {
    
    let content : Bool = true
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick True\n")
    }
    
    override func getType() -> String {
        return "Boolean"
    }
    
    override func execute() -> Any? {
        QuickMemory.shared.pushObject(content, inStackForParser: self.parser!)
        return nil
    }
    

}

class QuickFalse : QuickObject {
    
    let content : Bool = false
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick False\n")
    }
    
    override func getType() -> String {
        return "Boolean"
    }
    
    override func execute() -> Any? {
        QuickMemory.shared.pushObject(content, inStackForParser: self.parser!)
        return nil
    }

}

class QuickMathExpression : QuickObject {
    
    var content : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Math Expression\n")
        content?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        content?.checkSymbols(symbolTable: symbolTable)
    }

    override func getType() -> String {
        if content != nil {
            return content!.getType()
        }
        return ""
    }
    
    override func execute() -> Any? {
        content?.execute()
        return nil
    }
    
}

class QuickMathOperator : QuickObject {
    
    var content : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Math Operator\n")
        content?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        content?.checkSymbols(symbolTable: symbolTable)
    }
    
    override func getType() -> String {
        
        guard content != nil else {
            return ""
        }
        
        return content!.getType()
    }
    
    override func execute() -> Any? {
        content?.execute()
        return nil
    }
    
}

class QuickPlus : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Plus\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            print("ERROR: type \(leftType) and type \(rightType) do not match")
        }
    }
    
    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }
    
    override func execute() -> Any? {
        leftSide?.execute()
        var leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        var rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) + (rightSideValue as! Int)
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            if leftSideValue is CGFloat {
                leftSideValue = Float(leftSideValue as! CGFloat)
            }
            if rightSideValue is CGFloat {
                rightSideValue = Float(rightSideValue as! CGFloat)
            }
            let computed = (leftSideValue as! Float) + (rightSideValue as! Float)
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else if getType() == "String" {
            let computed = "\(leftSideValue)\(rightSideValue)"
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else {
            QuickMemory.shared.pushObject(0, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickMinus : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Minus\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }
    }
    
    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }
    
    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) - (rightSideValue as! Int)
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let computed = (leftSideValue as! Float) - (rightSideValue as! Float)
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else {
            QuickMemory.shared.pushObject(0, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickMultiply : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Multiply\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) * (rightSideValue as! Int)
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let computed = (leftSideValue as! Float) * (rightSideValue as! Float)
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else {
            QuickMemory.shared.pushObject(0, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickDivide : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Divide\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) / (rightSideValue as! Int)
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let computed = (leftSideValue as! Float) / (rightSideValue as! Float)
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else {
            QuickMemory.shared.pushObject(0, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickMod : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Mod\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) % (rightSideValue as! Int)
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let computed = (leftSideValue as! Float).truncatingRemainder(dividingBy: (rightSideValue as! Float))
            QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        } else {
            QuickMemory.shared.pushObject(0, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickEqual : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Equal\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }

    }
    
    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) == (rightSideValue as! Int)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) == (rightSideValue as! Float)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "String" {
            let result = (leftSideValue as! String) == (rightSideValue as! String)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Boolean" {
            let result = (leftSideValue as! Bool) == (rightSideValue as! Bool)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Color" {
            let result = (leftSideValue as! UIColor) == (rightSideValue as! UIColor)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickNotEqual : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Not Equal\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) != (rightSideValue as! Int)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) != (rightSideValue as! Float)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "String" {
            let result = (leftSideValue as! String) != (rightSideValue as! String)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Boolean" {
            let result = (leftSideValue as! Bool) != (rightSideValue as! Bool)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Color" {
            let result = (leftSideValue as! UIColor) != (rightSideValue as! UIColor)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickLessThan : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Less Than\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) < (rightSideValue as! Int)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) < (rightSideValue as! Float)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickGreaterThan : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Greater Than\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) > (rightSideValue as! Int)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) > (rightSideValue as! Float)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickLessThanOrEqualTo : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Less Than or Equal To\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) <= (rightSideValue as! Int)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) <= (rightSideValue as! Float)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickGreaterThanOrEqualTo : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Greater Than or Equal To\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        let rightType = rightSide!.getType()
        if leftType != rightType {
            QuickError.shared.setErrorMessage("Type \(leftType) and type \(rightType) do not match", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) >= (rightSideValue as! Int)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) >= (rightSideValue as! Float)
            QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        }
        return nil
    }

}

class QuickAnd : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick And\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        if leftType != "Boolean" {
            QuickError.shared.setErrorMessage("Type \(leftType) is not a boolean", withLine: -2)
        }
        let rightType = rightSide!.getType()
        if rightType != "Boolean" {
            QuickError.shared.setErrorMessage("Type \(rightType) is not a boolean", withLine: -2)
        }

    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        let result = (leftSideValue as! Bool) && (rightSideValue as! Bool)
        QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        return nil
    }

}

class QuickOr : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Or\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        let leftType = leftSide!.getType()
        if leftType != "Boolean" {
            QuickError.shared.setErrorMessage("Type \(leftType) is not a boolean", withLine: -2)
        }
        let rightType = rightSide!.getType()
        if rightType != "Boolean" {
            QuickError.shared.setErrorMessage("Type \(rightType) is not a boolean", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard leftSide != nil else {
            return ""
        }
        
        return leftSide!.getType()
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        let result = (leftSideValue as! Bool) || (rightSideValue as! Bool)
        QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        return nil
    }

}

class QuickNot : QuickObject {
    
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Not\n")
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard rightSide != nil else {
            return
        }
        
        let rightType = rightSide!.getType()
        if rightType != "Boolean" {
            QuickError.shared.setErrorMessage("Type \(rightType) is not a boolean", withLine: -2)
        }
    }

    override func getType() -> String {
        
        guard rightSide != nil else {
            return ""
        }
        
        return rightSide!.getType()
    }

    override func execute() -> Any? {
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        let result = !(rightSideValue as! Bool)
        QuickMemory.shared.pushObject(result, inStackForParser: self.parser!)
        return nil
    }

}

class QuickLogicalExpression : QuickObject {
    
    var content : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Logical Expression\n")
        content?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        content?.checkSymbols(symbolTable: symbolTable)
    }

    override func getType() -> String {
        return "Boolean"
    }
    
    override func execute() -> Any? {
        content?.execute()
        return nil
    }

}

class QuickParameters : QuickObject {
    
    var parameters : Array<QuickObject> = []
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Parameters\n")
        for parameter in parameters {
            parameter.printDebugDescription(withLevel: withLevel + 1)
        }
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        for parameter in parameters {
            parameter.checkSymbols(symbolTable: symbolTable)
        }
    }

    override func execute() -> Any? {
        var computed : Array<Any> = []
        for parameter in parameters {
            parameter.execute()
            computed.append(QuickMemory.shared.popObject(inStackForParser: self.parser!))
        }
        QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        return nil
    }

}

class QuickMethodCall : QuickObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var methodName = ""
    var parameters : QuickParameters?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Method Call = \(methodName)\n")
        parameters?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        symbolTable.expectSymbol(methodName)
        parameters?.checkSymbols(symbolTable: symbolTable)
        
        if methodName == "print" {
            symbolTable.checkArguments(parameters, types: ["Any"], methodName: methodName)
        }
        if methodName == "getJSONArray" {
            symbolTable.checkArguments(parameters, types: ["String", "Dictionary"], methodName: methodName)
        }
        if methodName == "getJSONDictionary" {
            if parameters == nil || parameters!.parameters.count == 0 || parameters!.parameters.count > 2 {
                QuickError.shared.setErrorMessage("Expected 1 or 2 parameters when calling \(methodName)", withLine: -2)
            }
        }
        if methodName == "getImage" {
            if parameters == nil || parameters!.parameters.count == 0 || parameters!.parameters.count > 2 {
                QuickError.shared.setErrorMessage("Expected 1 or 2 parameters when calling \(methodName)", withLine: -2)
            }
        }
        if methodName == "encodeBase64" {
            symbolTable.checkArguments(parameters, types: ["String"], methodName: methodName)
        }
        if methodName == "countArray" {
            symbolTable.checkArguments(parameters, types: ["Array"], methodName: methodName)
        }
        if methodName == "countDictionary" {
            symbolTable.checkArguments(parameters, types: ["Dictionary"], methodName: methodName)
        }
        if methodName == "getDictionaryKeys" {
            symbolTable.checkArguments(parameters, types: ["Dictionary"], methodName: methodName)
        }
        if methodName == "addItemToDictionary" {
            symbolTable.checkArguments(parameters, types: ["Dictionary", "String", "Any"], methodName: methodName)
        }
        if methodName == "removeItemFromDictionary" {
            symbolTable.checkArguments(parameters, types: ["Dictionary", "String"], methodName: methodName)
        }
        if methodName == "addItemToArray" {
            symbolTable.checkArguments(parameters, types: ["Array", "Any"], methodName: methodName)
        }
        if methodName == "removeItemFromArray" {
            symbolTable.checkArguments(parameters, types: ["Array", "Integer"], methodName: methodName)
        }
        if methodName == "setAppVariable" {
            symbolTable.checkArguments(parameters, types: ["String", "Any"], methodName: methodName)
        }
        if methodName == "getAppVariable" {
            symbolTable.checkArguments(parameters, types: ["String"], methodName: methodName)
        }
        if methodName == "setScreenVariable" {
            symbolTable.checkArguments(parameters, types: ["String", "Any"], methodName: methodName)
        }
        if methodName == "getScreenVariable" {
            symbolTable.checkArguments(parameters, types: ["String"], methodName: methodName)
        }
        if methodName == "replaceString" {
            symbolTable.checkArguments(parameters, types: ["String", "String", "String"], methodName: methodName)
        }
        if methodName == "pushScreen" {
            symbolTable.checkArguments(parameters, types: ["String"], methodName: methodName)
        }
        if methodName == "popScreen" {
            symbolTable.checkArguments(parameters, types: [], methodName: methodName)
        }
        if methodName == "popToRootScreen" {
            symbolTable.checkArguments(parameters, types: [], methodName: methodName)
        }
        if methodName == "showAlert" {
            if parameters == nil || parameters!.parameters.count < 3 {
                QuickError.shared.setErrorMessage("Expected three or more arguments when calling \(methodName), found none", withLine: -2)
            }
        }
        if methodName == "saveToFile" {
            symbolTable.checkArguments(parameters, types: ["String", "Any"], methodName: methodName)
        }
        if methodName == "readFromFile" {
            symbolTable.checkArguments(parameters, types: ["String"], methodName: methodName)
        }
        if methodName == "getImageFromCamera" {
            symbolTable.checkArguments(parameters, types: [], methodName: methodName)
        }
        if methodName == "getImageFromLibrary" {
            symbolTable.checkArguments(parameters, types: [], methodName: methodName)
        }
        if methodName == "postJSONToURL" {
            if parameters == nil || parameters!.parameters.count < 2 {
                QuickError.shared.setErrorMessage("Expected two or more arguments when calling \(methodName)", withLine: -2)
            }
        }
        if methodName == "postFormToURL" {
            if parameters == nil || parameters!.parameters.count < 2 {
                QuickError.shared.setErrorMessage("Expected two or more arguments when calling \(methodName)", withLine: -2)
            }
        }
        if methodName == "signInViaOAuth" {
            symbolTable.checkArguments(parameters, types: ["Dictionary"], methodName: methodName)
        }
        if methodName == "capitalize" {
            symbolTable.checkArguments(parameters, types: ["String"], methodName: methodName)
        }
        if methodName == "sortArray" {
            symbolTable.checkArguments(parameters, types: ["Array"], methodName: methodName)
        }
        if methodName == "random" {
            symbolTable.checkArguments(parameters, types: ["Integer", "Integer"], methodName: methodName)
        }
        if methodName == "getDictionaryFromXML" {
            if parameters == nil || parameters!.parameters.count == 0 || parameters!.parameters.count > 2 {
                QuickError.shared.setErrorMessage("Expected 1 or 2 parameters when calling \(methodName)", withLine: -2)
            }
        }

    }
    
    override func getType() -> String {
        if methodName == "print" {
            return "String"
        }
        if methodName == "getJSONArray" {
            return "Array"
        }
        if methodName == "getJSONDictionary" {
            return "Dictionary"
        }
        if methodName == "getImage" {
            return "Image"
        }
        if methodName == "encodeBase64" {
            return "String"
        }
        if methodName == "countArray" {
            return "Integer"
        }
        if methodName == "countDictionary" {
            return "Integer"
        }
        if methodName == "getDictionaryKeys" {
            return "Array"
        }
        if methodName == "addItemToDictionary" {
            return "Dictionary"
        }
        if methodName == "removeItemFromDictionary" {
            return "Dictionary"
        }
        if methodName == "addItemToArray" {
            return "Array"
        }
        if methodName == "removeItemFromArray" {
            return "Array"
        }
        if methodName == "setAppVariable" {
            return "Boolean"
        }
        if methodName == "getAppVariable" {
            return ""
        }
        if methodName == "setScreenVariable" {
            return "Boolean"
        }
        if methodName == "getScreenVariable" {
            return ""
        }
        if methodName == "replaceString" {
            return "String"
        }
        if methodName == "pushScreen" {
            return "String"
        }
        if methodName == "popScreen" {
            return "String"
        }
        if methodName == "popToRootScreen" {
            return "String"
        }
        if methodName == "showAlert" {
            return "String"
        }
        if methodName == "saveToFile" {
            return "Boolean"
        }
        if methodName == "readFromFile" {
            return "String"
        }
        if methodName == "getImageFromCamera" {
            return "Image"
        }
        if methodName == "getImageFromLibrary" {
            return "Image"
        }
        if methodName == "postJSONToURL" {
            return "Boolean"
        }
        if methodName == "postFormToURL" {
            return "Boolean"
        }
        if methodName == "signInViaOAuth" {
            return "Boolean"
        }
        if methodName == "capitalize" {
            return "String"
        }
        if methodName == "sortArray" {
            return "Array"
        }
        if methodName == "random" {
            return "Integer"
        }
        if methodName == "getDictionaryFromXML" {
            return "Dictionary"
        }

        return ""

    }

    override func execute() -> Any? {
        if methodName == "print" {
            executePrintWithParameters(parameters!)
        }
        if methodName == "getJSONArray" {
            executeGetJSONArrayWithParameters(parameters!)
        }
        if methodName == "getJSONDictionary" {
            executeGetJSONDictionaryWithParameters(parameters!)
        }
        if methodName == "getImage" {
            executeGetImageWithParameters(parameters!)
        }
        if methodName == "encodeBase64" {
            executeEncodeBase64(parameters!)
        }
        if methodName == "countArray" {
            executeCountArray(parameters!)
        }
        if methodName == "countDictionary" {
            executeCountDictionary(parameters!)
        }
        if methodName == "getDictionaryKeys" {
            executeGetDictionaryKeys(parameters!)
        }
        if methodName == "addItemToDictionary" {
            executeAddItemToDictionary(parameters!)
        }
        if methodName == "removeItemFromDictionary" {
            executeRemoveItemFromDictionary(parameters!)
        }
        if methodName == "addItemToArray" {
            executeAddItemToArray(parameters!)
        }
        if methodName == "removeItemFromArray" {
            executeRemoveItemFromArray(parameters!)
        }
        if methodName == "setAppVariable" {
            executeSetAppVariable(parameters!)
        }
        if methodName == "getAppVariable" {
            executeGetAppVariable(parameters!)
        }
        if methodName == "setScreenVariable" {
            executeSetScreenVariable(parameters!)
        }
        if methodName == "getScreenVariable" {
            executeGetScreenVariable(parameters!)
        }
        if methodName == "replaceString" {
            executeReplaceString(parameters!)
        }
        if methodName == "pushScreen" {
            executePushScreen(parameters!)
        }
        if methodName == "popScreen" {
            executePopScreen()
        }
        if methodName == "popToRootScreen" {
            executePopToRootScreen()
        }
        if methodName == "showAlert" {
            executeShowAlert(parameters!)
        }
        if methodName == "saveToFile" {
            executeSaveToFile(parameters!)
        }
        if methodName == "readFromFile" {
            executeReadFromFile(parameters!)
        }
        if methodName == "getImageFromCamera" {
            executeGetImageFromCamera()
        }
        if methodName == "getImageFromLibrary" {
            executeGetImageFromLibrary()
        }
        if methodName == "postJSONToURL" {
            executePostJSONToURL(parameters!)
        }
        if methodName == "postFormToURL" {
            executePostFormToURL(parameters!)
        }
        if methodName == "signInViaOAuth" {
            executeSignInViaOAuth(parameters!)
        }
        if methodName == "capitalize" {
            executeCapitalize(parameters!)
        }
        if methodName == "sortArray" {
            executeSortArray(parameters!)
        }
        if methodName == "random" {
            executeRandom(parameters!)
        }
        if methodName == "getDictionaryFromXML" {
            executeGetDictionaryFromXML(parameters!)
        }

        QuickMemory.shared.archiveHeapForParser(parser!, onLine: sourceLine)

        return nil

    }
    
    func executePrintWithParameters(_ parameters : QuickParameters) {
        
        for parameter in parameters.parameters {
            parameter.execute()
            let valueToPrint = QuickMemory.shared.popObject(inStackForParser: self.parser!)
            Output.shared.userVisible.append("\(valueToPrint)\n")
        }
        
    }

    func executeGetJSONArrayWithParameters(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 2 || parameters.parameters.count == 0 {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue as? String != nil else {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        let url = URL(string: parameterValue as! String)
        guard url != nil else {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        var headersDictionary : Dictionary<String, String>? = nil
        
        if parameters.parameters.count > 1 {
            let headersParameter = parameters.parameters[1]
            headersParameter.execute()
            let headersParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
            
            guard headersParameterValue as? Dictionary<String, String> != nil else {
                QuickMemory.shared.pushObject([:], inStackForParser: self.parser!)
                return
            }
            
            headersDictionary = headersParameterValue as? Dictionary<String, String>
        }
        
        var data : Data?
        var response : URLResponse?
        var error : Error?
        (data, response, error) = URLSession.shared.synchronousDataTask(with: url!, andHeaders: headersDictionary)
        
        if error != nil {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        do {
            if let data = data,
                let json = try JSONSerialization.jsonObject(with: data) as? [Any] {
                QuickMemory.shared.pushObject(json, inStackForParser: self.parser!)
                return
            }
        } catch {
            print("Error deserializing JSON")
        }
        
        QuickMemory.shared.pushObject([], inStackForParser: self.parser!)

    }
    
    func executeGetJSONDictionaryWithParameters(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 2 || parameters.parameters.count == 0 {
            QuickMemory.shared.pushObject(["error": "getJSONDictionary expects one or two arguments"], inStackForParser: self.parser!)
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        _ = parameter.execute()
        let parameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue as? String != nil else {
            QuickMemory.shared.pushObject(["error": "getJSONDictionary expects a string as the first parameter"], inStackForParser: self.parser!)
            return
        }
        
        let url = URL(string: (parameterValue as! String))
        guard url != nil else {
            QuickMemory.shared.pushObject(["error":"Invalid url to getJSONDictionary call"], inStackForParser: self.parser!)
            return
        }
        
        var headersDictionary : Dictionary<String, String>? = nil
        
        if parameters.parameters.count > 1 {
            let headersParameter = parameters.parameters[1]
            _ = headersParameter.execute()
            let headersParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
            
            guard headersParameterValue as? Dictionary<String, String> != nil else {
                QuickMemory.shared.pushObject(["error": "getJSONDictionary expects a dictionary of strings as the first parameter"], inStackForParser: self.parser!)
                return
            }
            
            headersDictionary = headersParameterValue as? Dictionary<String, String>
        }
        
        var data : Data?
        var response : URLResponse?
        var error : Error?
        (data, response, error) = URLSession.shared.synchronousDataTask(with: url!, andHeaders: headersDictionary)
        
        if error != nil {
            QuickMemory.shared.pushObject(["error": error.debugDescription], inStackForParser: self.parser!)
            return
        }
        
        do {
            if let data = data,
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                QuickMemory.shared.pushObject(json, inStackForParser: self.parser!)
                return
            }
        } catch {
            print("Error deserializing JSON")
        }
        
        QuickMemory.shared.pushObject(["error": "No JSON dictionary available"], inStackForParser: self.parser!)
        
    }

    func executeGetImageWithParameters(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 2 || parameters.parameters.count == 0 {
            QuickMemory.shared.pushObject(["error": "getJSONDictionary expects one or two arguments"], inStackForParser: self.parser!)
            return
        }

        let parameter = parameters.parameters[0]
        _ = parameter.execute()
        let parameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue as? String != nil else {
            QuickMemory.shared.pushObject(UIImage(named: "blank") as Any, inStackForParser: self.parser!)
            return
        }
        
        let url = URL(string: parameterValue as! String)
        guard url != nil else {
            QuickMemory.shared.pushObject(UIImage(named: "blank") as Any, inStackForParser: self.parser!)
            return
        }
        
        var headersDictionary : Dictionary<String, String>? = nil
        
        if parameters.parameters.count > 1 {
            let headersParameter = parameters.parameters[1]
            _ = headersParameter.execute()
            let headersParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
            
            guard headersParameterValue as? Dictionary<String, String> != nil else {
                QuickMemory.shared.pushObject(UIImage(named: "blank") as Any, inStackForParser: self.parser!)
                return
            }
            
            headersDictionary = headersParameterValue as? Dictionary<String, String>
        }
        
        var data : Data?
        var response : URLResponse?
        var error : Error?
        (data, response, error) = URLSession.shared.synchronousDataTask(with: url!, andHeaders: headersDictionary)
        
        if error != nil {
            QuickMemory.shared.pushObject(UIImage(named: "blank") as Any, inStackForParser: self.parser!)
            return
        }
        
        if let data = data,
            let image = UIImage(data: data) {
            QuickMemory.shared.pushObject(image, inStackForParser: self.parser!)
            return
        }
        
        QuickMemory.shared.pushObject(UIImage(named: "blank") as Any, inStackForParser: self.parser!)
        
    }

    func executeEncodeBase64(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue as? String != nil else {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        
        let base64String = (parameterValue as! String).data(using: String.Encoding.utf8)!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        
        QuickMemory.shared.pushObject(base64String, inStackForParser: self.parser!)
        
    }

    func executeCountArray(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.pushObject(0, inStackForParser: self.parser!)
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue as? Array<Any> != nil else {
            QuickMemory.shared.pushObject(0, inStackForParser: self.parser!)
            return
        }
        
        let count = (parameterValue as! Array<Any>).count
        
        QuickMemory.shared.pushObject(count, inStackForParser: self.parser!)
        
    }

    func executeCountDictionary(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.pushObject(0, inStackForParser: self.parser!)
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue as? Dictionary<String, Any> != nil else {
            QuickMemory.shared.pushObject(0, inStackForParser: self.parser!)
            return
        }
        
        let count = (parameterValue as! Dictionary<String, Any>).count
        
        QuickMemory.shared.pushObject(count, inStackForParser: self.parser!)
        
    }

    func executeGetDictionaryKeys(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue as? Dictionary<String, Any> != nil else {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        var allKeys : Array<Any> = []
        for key in (parameterValue as! Dictionary<String, Any>).keys {
            allKeys.append(key)
        }
        
        QuickMemory.shared.pushObject(allKeys, inStackForParser: self.parser!)
        
    }
    
    func executeAddItemToDictionary(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 3 {
            QuickMemory.shared.pushObject([:], inStackForParser: self.parser!)
            return
        }
        
        // We have three parameters.  Verify that the first is a dictionary and the second is a string
        var parameter = parameters.parameters[0]
        parameter.execute()
        let dictionaryParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard dictionaryParameterValue as? Dictionary<String, Any> != nil else {
            QuickMemory.shared.pushObject([:], inStackForParser: self.parser!)
            return
        }
        
        parameter = parameters.parameters[1]
        parameter.execute()
        let keyParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.pushObject([:], inStackForParser: self.parser!)
            return
        }
        
        parameter = parameters.parameters[2]
        parameter.execute()
        let valueParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        var newDictionary : Dictionary<String, Any> = [:]
        for key in (dictionaryParameterValue as! Dictionary<String, Any>).keys {
            newDictionary[key] = (dictionaryParameterValue as! Dictionary<String, Any>)[key]
        }
        newDictionary[keyParameterValue as! String] = valueParameterValue
        
        QuickMemory.shared.pushObject(newDictionary, inStackForParser: self.parser!)
        
    }

    func executeRemoveItemFromDictionary(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.pushObject([:], inStackForParser: self.parser!)
            return
        }
        
        // We have three parameters.  Verify that the first is a dictionary and the second is a string
        var parameter = parameters.parameters[0]
        parameter.execute()
        let dictionaryParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard dictionaryParameterValue as? Dictionary<String, Any> != nil else {
            QuickMemory.shared.pushObject([:], inStackForParser: self.parser!)
            return
        }
        
        parameter = parameters.parameters[1]
        parameter.execute()
        let keyParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.pushObject([:], inStackForParser: self.parser!)
            return
        }
        
        var newDictionary : Dictionary<String, Any> = [:]
        for key in (dictionaryParameterValue as! Dictionary<String, Any>).keys {
            newDictionary[key] = (dictionaryParameterValue as! Dictionary<String, Any>)[key]
        }
        newDictionary[keyParameterValue as! String] = nil
        
        QuickMemory.shared.pushObject(newDictionary, inStackForParser: self.parser!)
        
    }
    
    func executeAddItemToArray(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        // We have three parameters.  Verify that the first is a dictionary and the second is a string
        var parameter = parameters.parameters[0]
        parameter.execute()
        let arrayParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard arrayParameterValue as? Array<Any> != nil else {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        parameter = parameters.parameters[1]
        parameter.execute()
        let valueParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        var newArray : Array<Any> = []
        for item in arrayParameterValue as! Array<Any> {
            newArray.append(item)
        }
        newArray.append(valueParameterValue)
        
        QuickMemory.shared.pushObject(newArray, inStackForParser: self.parser!)
        
    }

    func executeRemoveItemFromArray(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        // We have three parameters.  Verify that the first is an array and the second is an integer
        var parameter = parameters.parameters[0]
        parameter.execute()
        let arrayParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard arrayParameterValue as? Array<Any> != nil else {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        parameter = parameters.parameters[1]
        parameter.execute()
        let valueParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard valueParameterValue as? Int != nil else {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }

        var newArray : Array<Any> = []
        var i = 0
        for item in arrayParameterValue as! Array<Any> {
            if i != valueParameterValue as! Int {
                newArray.append(item)
            }
            i = i + 1
        }
        
        QuickMemory.shared.pushObject(newArray, inStackForParser: self.parser!)
        
    }

    func executeSetAppVariable(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        // We have two parameters.  Verify that the first is a string.  The second one can be any type.
        let keyParameter = parameters.parameters[0]
        _ = keyParameter.execute()
        let keyParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        let valueParameter = parameters.parameters[1]
        _ = valueParameter.execute()
        let valueParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        // Save to some app-wide context
        let fullKeyName = "app.\(keyParameterValue as! String)"
        QuickMemory.shared.setObject(valueParameterValue as Any, forKey: fullKeyName, inHeapForParser: nil)
        
        QuickMemory.shared.pushObject(true, inStackForParser: self.parser!)
        
    }

    func executeGetAppVariable(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 1 {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        // We have one parameter.  Verify that the first is a string.
        let keyParameter = parameters.parameters[0]
        _ = keyParameter.execute()
        let keyParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        // Grab from the app wide context
        let fullKeyName = "app.\(keyParameterValue as! String)"
        let value = QuickMemory.shared.getObjectForKey(fullKeyName, inHeapForParser: nil)
        
        QuickMemory.shared.pushObject(value, inStackForParser: self.parser!)
        
    }

    func executeSetScreenVariable(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        // We have two parameters.  Verify that the first is a string.  The second one can be any type.
        let keyParameter = parameters.parameters[0]
        _ = keyParameter.execute()
        let keyParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        let valueParameter = parameters.parameters[1]
        _ = valueParameter.execute()
        let valueParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        // Save to some app-wide context
        let visibleViewController = RenderCompiler.sharedInstance.appRenderer!.getVisibleViewController()!
        let fullKeyName = "screen.\(visibleViewController.getId()).\(keyParameterValue as! String)"
        QuickMemory.shared.setObject(valueParameterValue as Any, forKey: fullKeyName, inHeapForParser: nil)

        QuickMemory.shared.pushObject(true, inStackForParser: self.parser!)
        
    }
    
    func executeGetScreenVariable(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 1 {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        // We have one parameter.  Verify that the first is a string.
        let keyParameter = parameters.parameters[0]
        _ = keyParameter.execute()
        let keyParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        // Grab from the app wide context
        let visibleViewController = RenderCompiler.sharedInstance.appRenderer!.getVisibleViewController()!
        let fullKeyName = "screen.\(visibleViewController.getId()).\(keyParameterValue as! String)"
        let value = QuickMemory.shared.getObjectForKey(fullKeyName, inHeapForParser: nil)
        
        QuickMemory.shared.pushObject(value, inStackForParser: self.parser!)

    }
    
    func executeReplaceString(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 3 {
            QuickMemory.shared.pushObject([:], inStackForParser: self.parser!)
            return
        }
        
        // We have three parameters.  Verify that all three are strings
        var parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue1 = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue1 as? String != nil else {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        parameter = parameters.parameters[1]
        parameter.execute()
        let parameterValue2 = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue2 as? String != nil else {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        parameter = parameters.parameters[2]
        parameter.execute()
        let parameterValue3 = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue3 as? String != nil else {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        let replacedString = (parameterValue1 as! String).replacingOccurrences(of: parameterValue2 as! String, with: parameterValue3 as! String)
        
        QuickMemory.shared.pushObject(replacedString, inStackForParser: self.parser!)
        
    }

    func executePushScreen(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 1 && parameters.parameters.count != 2 {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        var parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue1 = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue1 as? String != nil else {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        let screenIdentifier = parameterValue1 as! String
        let navigationController = RenderCompiler.sharedInstance.appRenderer?.getVisibleViewController()?.getActiveNavigationViewController()
        var targetModel : ViewControllerModel?
        for child in navigationController!.isa.children {
            if child is ViewControllerModel {
                if (child as! ViewControllerModel).getProperty(propertyIdentifier: PropertyValues.identifier)?.getValue() as? String == screenIdentifier {
                    targetModel = child as! ViewControllerModel
                }
            }
        }
        
        var rendererForContext : ViewControllerRenderer?
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: { // Some items (eg. MKMapView) need to be rendered on the main thread
        
            if targetModel == nil {
                targetModel = ModelObjectFactory.createViewControllerModel(withParent: navigationController!.isa)
                let identifierProp = targetModel?.getProperty(propertyIdentifier: PropertyValues.identifier)
                identifierProp?.set(value: screenIdentifier)
                targetModel?.setProperty(updatedProperty: identifierProp!)
            }

            guard navigationController != nil else {
                print("Error: attempt to push failed as visibleViewController is nil")
                return
            }
            
            let renderer = ViewControllerRenderer(isa: targetModel!, parent: navigationController)
            renderer.render()
            rendererForContext = renderer
            
            if parameters.parameters.count == 2 {
                let parameter2 = parameters.parameters[1]
                _ = parameter2.execute()
                let parameterValue2 = QuickMemory.shared.popObject(inStackForParser: self.parser!)
                
                guard parameterValue2 as? Dictionary<String, Any> != nil else {
                    QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
                    return
                }
                
                var contextDictionary = parameterValue2 as! Dictionary<String, Any>
                for key in contextDictionary.keys {
                    let fullKeyName = "screen.\(rendererForContext!.getId()).\(key)"
                    QuickMemory.shared.setObject(contextDictionary[key] as Any, forKey: fullKeyName, inHeapForParser: nil)
                }
            }

            // Push the new ViewController
            PreviewViewController.previewViewController?.push(viewControllerRenderer : renderer)
        })
        
        QuickMemory.shared.pushObject("", inStackForParser: self.parser!)

    }
    
    func executePopScreen() {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: { // Some items (eg. MKMapView) need to be rendered on the main thread
            PreviewViewController.previewViewController?.pop()
        })

        QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
        
    }

    func executePopToRootScreen() {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: { // Some items (eg. MKMapView) need to be rendered on the main thread
            PreviewViewController.previewViewController?.popToRoot()
        })

        QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
        
    }

    func executeShowAlert(_ parameters : QuickParameters) {
        
        if parameters.parameters.count <= 2 { // We need at least one button
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        // Each parameter has to be a string
        var strings : Array<String> = []
        for parameter in parameters.parameters {
            _ = parameter.execute()
            let value = QuickMemory.shared.popObject(inStackForParser: self.parser!)
            if value as? String == nil {
                QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
                return
            }
            strings.insert(value as! String, at: 0)
        }
        
        
        
        let alertController = UIAlertController(title: strings.popLast(), message: strings.popLast(), preferredStyle: .alert)
        for string in strings.reversed() {
            alertController.addAction(UIAlertAction(title: string, style: .default, handler: nil))
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now(), execute: {
            PreviewViewController.previewViewController.show(alertController, sender: self)
        })
        
        QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
        
    }
    
    func executeSaveToFile(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        // Two parameters, both should be strings
        var parameter = parameters.parameters[0]
        parameter.execute()
        let dataValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard dataValue as? String != nil else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        parameter = parameters.parameters[1]
        parameter.execute()
        let pathValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard pathValue as? String != nil else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        let documentsUrl : URL = FileManager.default.urls(for : .applicationSupportDirectory, in : .userDomainMask)[0]
        let sandboxPathForCodelessDoc = documentsUrl.appendingPathComponent("Sandbox").appendingPathComponent(ProjectManager.sharedInstance.currentProjectName)
        try? FileManager.default.createDirectory(at: sandboxPathForCodelessDoc, withIntermediateDirectories: true, attributes: nil)
        let documentPath = sandboxPathForCodelessDoc.appendingPathComponent(pathValue as! String)
        
        do {
            try (dataValue as! NSString).write(to: documentPath, atomically: true, encoding: String.Encoding.utf8.rawValue)
        } catch {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        QuickMemory.shared.pushObject(true, inStackForParser: self.parser!)
        
    }

    func executeReadFromFile(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 1 {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        // We just need the nane if the file
        var parameter = parameters.parameters[0]
        parameter.execute()
        let pathValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard pathValue as? String != nil else {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        let documentsUrl : URL = FileManager.default.urls(for : .applicationSupportDirectory, in : .userDomainMask)[0]
        let sandboxPathForCodelessDoc = documentsUrl.appendingPathComponent("Sandbox").appendingPathComponent(ProjectManager.sharedInstance.currentProjectName)
        let documentPath = sandboxPathForCodelessDoc.appendingPathComponent(pathValue as! String)
        
        do {
            let string = try NSString(contentsOf: documentPath, encoding: String.Encoding.utf8.rawValue)
            QuickMemory.shared.pushObject(string, inStackForParser: self.parser!)
        } catch {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
    }

    let cameraSemaphore = DispatchSemaphore(value: 0)
    
    func executeGetImageFromCamera() {
        
        DispatchQueue.main.async {
            
            let visibleViewController = RenderCompiler.sharedInstance.appRenderer?.getVisibleViewController()
            
            if visibleViewController != nil {
                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
                imagePickerController.sourceType = UIImagePickerControllerSourceType.camera
                
                visibleViewController!.viewController!.present(imagePickerController, animated: true, completion: nil)
            }
        }
        
        cameraSemaphore.wait()
        
    }

    func executeGetImageFromLibrary() {
        
        DispatchQueue.main.async {
            
            let visibleViewController = RenderCompiler.sharedInstance.appRenderer?.getVisibleViewController()
            
            if visibleViewController != nil {
                let imagePickerController = UIImagePickerController()
                imagePickerController.delegate = self as! UIImagePickerControllerDelegate & UINavigationControllerDelegate
                imagePickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
                
                visibleViewController!.viewController!.present(imagePickerController, animated: true, completion: nil)
            }
        }
        
        cameraSemaphore.wait()
        
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        QuickMemory.shared.pushObject(UIImage(named: "blank") as Any, inStackForParser: self.parser!)
        cameraSemaphore.signal()
        picker.presentingViewController?.dismiss(animated: true, completion: {
            // https://stackoverflow.com/questions/32455429/wrong-screen-size-after-dismissing-uiimagepickercontroller
            let visibleViewController = RenderCompiler.sharedInstance.appRenderer?.getVisibleViewController()
            visibleViewController!.viewController!.view.frame = PreviewViewController.previewViewController.screenContainer.bounds
            visibleViewController!.viewController!.view.layoutIfNeeded()
            
            visibleViewController!.viewController!.tabBarController?.view.frame = PreviewViewController.previewViewController.screenContainer.bounds
            visibleViewController!.viewController!.tabBarController?.view.layoutIfNeeded()
        })
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        QuickMemory.shared.pushObject(info[UIImagePickerControllerOriginalImage], inStackForParser: self.parser!)
        cameraSemaphore.signal()
        picker.presentingViewController?.dismiss(animated: true, completion: {
            // https://stackoverflow.com/questions/32455429/wrong-screen-size-after-dismissing-uiimagepickercontroller
            let visibleViewController = RenderCompiler.sharedInstance.appRenderer?.getVisibleViewController()
            visibleViewController!.viewController!.view.frame = PreviewViewController.previewViewController.screenContainer.bounds
            visibleViewController!.viewController!.view.layoutIfNeeded()
            
            visibleViewController!.viewController!.tabBarController?.view.frame = PreviewViewController.previewViewController.screenContainer.bounds
            visibleViewController!.viewController!.tabBarController?.view.layoutIfNeeded()
        })
    }
    
    // parameters include a string representing the url, a dictionary representing form fields,
    // and an optional dictionary of headers
    func executePostJSONToURL( _ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 && parameters.parameters.count != 3 {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        // url to post to
        
        let urlParamter = parameters.parameters[0]
        _ = urlParamter.execute()
        let urlParamterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard urlParamterValue as? String != nil else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        let url = URL(string: urlParamterValue as! String)
        guard url != nil else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        // json to post
        
        let jsonParamter = parameters.parameters[1]
        _ = jsonParamter.execute()
        let jsonParamterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        var json : Dictionary<String, Any>?
        
        if jsonParamterValue is Dictionary<String, Any> {
            json = jsonParamterValue as? Dictionary<String, Any>
        } else if jsonParamterValue is Array<Any> {
            json = Dictionary<String, Any>()
            var index = 0
            for value in jsonParamterValue as! Array<Any> {
                json![String(format: "%i", index)] = value
                index += 1
            }
        } else if jsonParamterValue is String {
            if let data = (jsonParamterValue as! String).data(using: .utf8) {
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                } catch {
                    print(error.localizedDescription)
                    QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
                    return
                }
            }
        }
        
        guard json != nil else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        // headers
        
        var headersDictionary : Dictionary<String, String>?
        
        if parameters.parameters.count > 2 {
            let headersParameter = parameters.parameters[2]
            headersParameter.execute()
            let headersParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
            
            guard headersParameterValue as? Dictionary<String, String> != nil else {
                QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
                return
            }
            
            headersDictionary = headersParameterValue as? Dictionary<String, String>
        }
        
        // Sending request
        
        Alamofire.request(url!, method: .post, parameters: json, encoding: JSONEncoding.default, headers: headersDictionary).responseString { (response) in
                print(response)
                QuickMemory.shared.pushObject(true, inStackForParser: self.parser!)
        }
    }
    
    // parameters include a string representing the url, a dictionary representing form fields,
    // and an optional dictionary of headers
    func executePostFormToURL( _ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 && parameters.parameters.count != 3 {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        // url to post to
        
        let urlParamter = parameters.parameters[0]
        _ = urlParamter.execute()
        let urlParamterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard urlParamterValue as? String != nil else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        // form to post
        
        let formParamter = parameters.parameters[1]
        _ = formParamter.execute()
        let formParamterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard formParamterValue as? Dictionary<String, Any> != nil else {
            QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
            return
        }
        
        // headers
        
        var headersDictionary : Dictionary<String, String>? = nil
        
        if parameters.parameters.count > 2 {
            let headersParameter = parameters.parameters[2]
            headersParameter.execute()
            let headersParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
            
            guard headersParameterValue as? Dictionary<String, String> != nil else {
                QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
                return
            }
            
            headersDictionary = headersParameterValue as? Dictionary<String, String>
        }
        
        // etc
        
        Alamofire.upload(
            multipartFormData: { multipartFormData in
                for key in (formParamterValue as! Dictionary<String, Any>).keys {
                    
                    let value = (formParamterValue as! Dictionary<String, Any>)[key]
                    
                    guard value != nil else {
                        continue
                    }
                    
                    // From https://stackoverflow.com/questions/28680589/how-to-convert-an-int-into-nsdata-in-swift
                    if value is Int {
                        var intValue = (value as! Int).bigEndian
                        let data = NSData(bytes: &intValue, length: MemoryLayout<Int>.size)
                        
                        multipartFormData.append(data as Data, withName: key)
                    }
                    if value is Float {
                        var floatValue = value as! Float
                        let data = NSData(bytes: &floatValue, length: MemoryLayout<Float>.size)
                        
                        multipartFormData.append(data as Data, withName: key)
                    }
                    if value is String {
                        let data = (value as! String).data(using: String.Encoding.utf8)!
                        multipartFormData.append(data, withName: key)
                    }
                    if value is Bool {
                        var boolValue = value as! Bool
                        let data = NSData(bytes: &boolValue, length: MemoryLayout<Bool>.size)
                        
                        multipartFormData.append(data as Data, withName: key)
                    }
                    if value is Dictionary<String, Any> ||
                        value is Array<Any> {
                        do {
                            let data = try JSONSerialization.data(withJSONObject: value!, options: .sortedKeys)
                            multipartFormData.append(data, withName: key)
                        } catch {
                            continue
                        }
                    }
                    if value is UIImage {
                        let data = UIImagePNGRepresentation(value as! UIImage)
                        guard data != nil else {
                             continue
                        }
                        
                        multipartFormData.append(data!, withName: key)
                    }
                }
            },
            to: urlParamterValue as! String,
            headers: headersDictionary,
            encodingCompletion: { encodingResult in
                switch encodingResult {
                case .success(let upload, _, _):
                    upload.responseString { response in
                        print(response)
                        QuickMemory.shared.pushObject(true, inStackForParser: self.parser!)
                    }
                    
                case .failure(let encodingError):
                    print(encodingError)
                    QuickMemory.shared.pushObject(false, inStackForParser: self.parser!)
                }
            }
        )
    }
    
    func executeSignInViaOAuth( _ parameters : QuickParameters) {
    }
    
    func executeCapitalize(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 1 {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        var parameter = parameters.parameters[0]
        parameter.execute()
        let stringValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard stringValue as? String != nil else {
            QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            return
        }
        
        let capitalized = (stringValue as! String).capitalized
        QuickMemory.shared.pushObject(capitalized, inStackForParser: self.parser!)
        return
        
    }

    func executeSortArray(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 1 {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        
        let parameter = parameters.parameters[0]
        _ = parameter.execute()
        let arrayValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard arrayValue as? Array<Any> != nil else {
            QuickMemory.shared.pushObject([], inStackForParser: self.parser!)
            return
        }
        guard arrayValue as? Array<String> != nil else {
            QuickMemory.shared.pushObject(arrayValue, inStackForParser: self.parser!)
            return
        }
        
        let sorted = (arrayValue as! Array<String>).sorted()
        QuickMemory.shared.pushObject(sorted, inStackForParser: self.parser!)
        return
        
    }

    func executeRandom(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.pushObject(-1, inStackForParser: self.parser!)
            return
        }
        
        let parameter = parameters.parameters[0]
        _ = parameter.execute()
        let lowBoundValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard lowBoundValue as? Int != nil else {
            QuickMemory.shared.pushObject(-1, inStackForParser: self.parser!)
            return
        }

        let parameter2 = parameters.parameters[1]
        _ = parameter2.execute()
        let highBoundValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard highBoundValue as? Int != nil else {
            QuickMemory.shared.pushObject(-1, inStackForParser: self.parser!)
            return
        }

        let randomWithZeroAsLowest = arc4random_uniform(UInt32((highBoundValue as! Int) - (lowBoundValue as! Int) + 1))
        let random = randomWithZeroAsLowest + (lowBoundValue as! Int)
        
        QuickMemory.shared.pushObject(Int(random), inStackForParser: self.parser!)
        return
        
    }
    
    func executeGetDictionaryFromXML(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 2 || parameters.parameters.count == 0 {
            QuickMemory.shared.pushObject(["error": "getDictionaryFromXML expects one or two arguments"], inStackForParser: self.parser!)
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        _ = parameter.execute()
        let parameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        guard parameterValue as? String != nil else {
            QuickMemory.shared.pushObject(["error": "getDictionaryFromXML expects a string as the first parameter"], inStackForParser: self.parser!)
            return
        }
        
        let url = URL(string: (parameterValue as! String))
        guard url != nil else {
            QuickMemory.shared.pushObject(["error":"Invalid url to getDictionaryFromXML call"], inStackForParser: self.parser!)
            return
        }
        
        var headersDictionary : Dictionary<String, String>? = nil
        
        if parameters.parameters.count > 1 {
            let headersParameter = parameters.parameters[1]
            _ = headersParameter.execute()
            let headersParameterValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
            
            guard headersParameterValue as? Dictionary<String, String> != nil else {
                QuickMemory.shared.pushObject(["error": "getDictionaryFromXML expects a dictionary of strings as the first parameter"], inStackForParser: self.parser!)
                return
            }
            
            headersDictionary = headersParameterValue as? Dictionary<String, String>
        }
        
        var data : Data?
        var response : URLResponse?
        var error : Error?
        (data, response, error) = URLSession.shared.synchronousDataTask(with: url!, andHeaders: headersDictionary)
        
        if error != nil {
            QuickMemory.shared.pushObject(["error": error.debugDescription], inStackForParser: self.parser!)
            return
        }
        
        if data != nil {
            let xml = SWXMLHash.parse(data!)
            QuickMemory.shared.pushObject(xml, inStackForParser: self.parser!)
        } else {
            QuickMemory.shared.pushObject(["error": "No XML data available"], inStackForParser: self.parser!)
        }

    }

}

class QuickProperty : QuickObject {
    
    var content : Array<QuickIdentifier> = []
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Property\n")
        for identifier in content {
            identifier.printDebugDescription(withLevel: withLevel + 1)
        }
    }
    
    override func addSymbols(symbolTable : QuickSymbolTable) {
        for identifier in content {
            identifier.addSymbols(symbolTable: symbolTable)
        }
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        for identifier in content {
            identifier.checkSymbols(symbolTable: symbolTable)
        }
    }

    override func execute() -> Any? {

        var propertyString = ""
        for obj in content {
            if propertyString != "" {
                propertyString.append(".")
            }
            propertyString.append(obj.content)
        }

        QuickMemory.shared.pushObject(propertyString, inStackForParser: self.parser!)

        return nil
    }

}

class QuickValue : QuickObject {
    
    var content : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Value\n")
        content?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func addSymbols(symbolTable : QuickSymbolTable) {
        content?.addSymbols(symbolTable: symbolTable)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        content?.checkSymbols(symbolTable: symbolTable)
    }

    override func getType() -> String {
        if content != nil {
            return content!.getType()
        }
        return ""
    }

    override func execute() -> Any? {
        content?.execute()
        return nil
    }

}

class QuickAssignment : QuickObject {
    
    var leftSide : QuickProperty?
    var rightSide : QuickObject?
    var castingType : String?
    var parent : QuickStatement?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Assignment\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
        if castingType != nil {
            for _ in 0...(withLevel+1) {
                Output.shared.string.append("-")
            }
            Output.shared.string.append("Quick Type: \(castingType!)\n")
        }
    }
        
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.addSymbols(symbolTable: symbolTable)
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        var leftSideString = ""
        for identifier in leftSide!.content {
            if leftSideString != "" {
                leftSideString.append(".")
            }
            leftSideString.append(identifier.content)
        }
        let type = rightSide!.getType()
        symbolTable.checkType(type, ofIdentifier: leftSideString)
        
        if castingType != nil {
            symbolTable.checkType(castingType!, ofIdentifier: leftSideString)
        }
        
    }

    override func execute() -> Any? {
        leftSide?.execute()
        let leftSideResult = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        rightSide?.execute()
        var rightSideResult = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        
        if castingType == "Integer" {
            if !(rightSideResult is Int) {
                rightSideResult = 0
            }
        } else if castingType == "Float" {
            if !(rightSideResult is Float) {
                rightSideResult = 0.0
            }
        } else if castingType == "Boolean" {
            if !(rightSideResult is Bool) {
                rightSideResult = false
            }
        } else if castingType == "String" {
            if !(rightSideResult is String) {
                rightSideResult = ""
            }
        } else if castingType == "Dictionary" {
            if !(rightSideResult is Dictionary<String, Any>) {
                rightSideResult = [:]
            }
        } else if castingType == "Array" {
            if !(rightSideResult is Array<Any>) {
                rightSideResult = []
            }
        } else if castingType == "Image" {
            if !(rightSideResult is UIImage) {
                rightSideResult = UIImage(named: "blank") as Any
            }
        }

        if rightSideResult != nil && (leftSideResult as? String) != nil {
            // Check to see if left side result is an external symbol, set directly if it is
            if QuickSymbolTable.externalSymbols[leftSideResult as! String] != nil {
                let propertyId = (leftSideResult as! NSString).components(separatedBy: ".").last! // Update with the actual property derived from left side result
                
                if Thread.isMainThread {
                    
                    if rightSideResult is UIImage {
                        let imageUUID = UUID().uuidString
                        ImageManager.sharedInstance.addTempImage(rightSideResult as! UIImage, withName: imageUUID)
                        (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.updateViewProperty(forIdentifier: propertyId, withNewValue: imageUUID, withDuration: 0.3)
//                        (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.render()
                    } else {
                        (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.updateViewProperty(forIdentifier: propertyId, withNewValue: rightSideResult, withDuration: 0.3)
//                        (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.render()
                    }
                    
                } else {

                    DispatchQueue.main.sync {
                        
                        if rightSideResult is UIImage {
                            let imageUUID = UUID().uuidString
                            ImageManager.sharedInstance.addTempImage(rightSideResult as! UIImage, withName: imageUUID)
                            (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.updateViewProperty(forIdentifier: propertyId, withNewValue: imageUUID, withDuration: 0.3)
//                            (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.render()
                        } else {
                            (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.updateViewProperty(forIdentifier: propertyId, withNewValue: rightSideResult, withDuration: 0.3)
//                            (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.render()
                        }
                        
                    }
                    
                }
            
            }
            // Assign it in the heap, regardless of if it's an external symbol
            QuickMemory.shared.setObject(rightSideResult, forKey: (leftSideResult as! String), inHeapForParser: self.parser!)
        } else {
            QuickError.shared.setErrorMessage("Bad value from stack during assignment", withLine: -2)
        }
        QuickMemory.shared.archiveHeapForParser(parser!, onLine: sourceLine)
        return nil
    }
    
}

class QuickArray : QuickObject {
    
    var parameters : QuickParameters?
    var subscriptValue : QuickValue?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Array\n")
        parameters?.printDebugDescription(withLevel: withLevel + 1)
        subscriptValue?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        parameters?.checkSymbols(symbolTable: symbolTable)
        
        if subscriptValue != nil {
            let subscriptType = subscriptValue!.getType()
            if subscriptType != "Integer" {
                QuickError.shared.setErrorMessage("Type \(subscriptType) is not an Integer", withLine: -2)
            }
        }
    }
    
    override func getType() -> String {
        if subscriptValue == nil {
            return "Array"
        }
        return ""
    }
    
    override func execute() -> Any? {
        parameters?.execute()
        
        if subscriptValue != nil {
            let parametersArray = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! Array<Any>
            subscriptValue?.execute()
            let subscriptInt = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! Int
            if subscriptInt >= parametersArray.count {
                QuickError.shared.setErrorMessage("Array index is out of bounds", withLine: -2)
            }

            QuickMemory.shared.pushObject(parametersArray[subscriptInt], inStackForParser: self.parser!)
        }

        return nil
    }
    
}

class QuickKeyValuePair : QuickObject {
    
    var key : QuickValue?
    var value : QuickValue?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Key Value Pair\n")
        key?.printDebugDescription(withLevel: withLevel + 1)
        value?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        key?.checkSymbols(symbolTable: symbolTable)
        value?.checkSymbols(symbolTable: symbolTable)
    }
    
    override func execute() -> Any? {
        var computed : Dictionary<String, Any> = [:]
        key?.execute()
        let keyValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        value?.execute()
        let valueValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        computed["\(keyValue)"] = valueValue
        QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        return nil
    }
    
}

class QuickDictionary : QuickObject {
    
    var content : Array<QuickKeyValuePair> = []
    var subscriptValue : QuickValue?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Dictionary\n")
        for pair in content {
            pair.printDebugDescription(withLevel: withLevel + 1)
        }
        subscriptValue?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        
        for pair in content {
            pair.checkSymbols(symbolTable: symbolTable)
        }

        if subscriptValue != nil {
            let subscriptType = subscriptValue!.getType()
            if subscriptType != "String" {
                QuickError.shared.setErrorMessage("Type \(subscriptType) is not an String", withLine: -2)
            }
        }
    }
    
    override func getType() -> String {
        if subscriptValue == nil {
            return "Dictionary"
        }
        return ""
    }
    
    override func execute() -> Any? {

        var computed : Dictionary<String, Any> = [:]
        for pair in content {
            pair.execute()
            let pairResult = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! Dictionary<String, Any>
            computed.add(dictionary: pairResult)
        }

        QuickMemory.shared.pushObject(computed, inStackForParser: self.parser!)
        
        if subscriptValue != nil {
            subscriptValue?.execute()
            let subscriptString = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! String
            if computed[subscriptString] == nil {
                QuickMemory.shared.pushObject("", inStackForParser: self.parser!)
            } else {
                QuickMemory.shared.pushObject(computed[subscriptString]!, inStackForParser: self.parser!)
            }
        }

        return nil
        
    }
    
}

class QuickIfStatement : QuickObject {
    
    var expression : QuickLogicalExpression?
    var executionBlock : QuickMultilineStatement?
    var elseBlock : QuickMultilineStatement?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick If Statement\n")
        expression?.printDebugDescription(withLevel: withLevel + 1)
        executionBlock?.printDebugDescription(withLevel: withLevel + 1)
        elseBlock?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func addSymbols(symbolTable : QuickSymbolTable) {
        executionBlock?.addSymbols(symbolTable: symbolTable)
        elseBlock?.addSymbols(symbolTable: symbolTable)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        expression?.checkSymbols(symbolTable: symbolTable)
        executionBlock?.checkSymbols(symbolTable: symbolTable)
        elseBlock?.checkSymbols(symbolTable: symbolTable)
    }

    override func execute() -> Any? {

        expression?.execute()
        let expressionResult = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! Bool
        if expressionResult {
            executionBlock?.execute()
        } else {
            elseBlock?.execute()
        }

        return nil
    }
    
}

class QuickForLoop : QuickObject {
    
    var identifier : QuickIdentifier?
    var castingType : String?
    var array : QuickValue?
    var executionBlock : QuickMultilineStatement?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick For Loop\n")
        identifier?.printDebugDescription(withLevel: withLevel + 1)
        if castingType != nil {
            for _ in 0...(withLevel+1) {
                Output.shared.string.append("-")
            }
            Output.shared.string.append("Quick Type: \(castingType!)\n")
        }
        array?.printDebugDescription(withLevel: withLevel + 1)
        executionBlock?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        identifier?.addSymbols(symbolTable: symbolTable)
        identifier?.checkSymbols(symbolTable: symbolTable)
        
        if castingType != nil {
            symbolTable.checkType(castingType!, ofIdentifier: identifier!.content)
        }
        
        array?.checkSymbols(symbolTable: symbolTable)
        executionBlock?.checkSymbols(symbolTable: symbolTable)
    }

    override func execute() -> Any? {

        array?.execute()
        let collection = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! Array<Any>
        for obj in collection {
            
            var cleanObject = obj
            
            if castingType == "Integer" {
                if !(cleanObject is Int) {
                    cleanObject = 0
                }
            } else if castingType == "Float" {
                if !(cleanObject is Float) {
                    cleanObject = 0.0
                }
            } else if castingType == "Boolean" {
                if !(cleanObject is Bool) {
                    cleanObject = false
                }
            } else if castingType == "String" {
                if !(cleanObject is String) {
                    cleanObject = ""
                }
            } else if castingType == "Dictionary" {
                if !(cleanObject is Dictionary<String, Any>) {
                    cleanObject = [:]
                }
            } else if castingType == "Array" {
                if !(cleanObject is Array<Any>) {
                    cleanObject = []
                }
            } else if castingType == "Image" {
                if !(cleanObject is UIImage) {
                    cleanObject = UIImage(named: "blank")
                }
            }

            QuickMemory.shared.setObject(cleanObject, forKey: identifier!.content, inHeapForParser: self.parser!)
            executionBlock?.execute()
        }

        return nil

    }

}

class QuickWhileLoop : QuickObject {
    
    var expression : QuickLogicalExpression?
    var executionBlock : QuickMultilineStatement?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick While Loop\n")
        expression?.printDebugDescription(withLevel: withLevel + 1)
        executionBlock?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        expression?.checkSymbols(symbolTable: symbolTable)
        executionBlock?.checkSymbols(symbolTable: symbolTable)
    }

    override func execute() -> Any? {

        expression?.execute()
        var expressionResult = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! Bool
        while expressionResult {
            executionBlock?.execute()
            expression?.execute()
            expressionResult = QuickMemory.shared.popObject(inStackForParser: self.parser!) as! Bool
        }

        return nil
    }

}

class QuickReturnStatement : QuickObject {
    
    var content : QuickValue?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Return Statement\n")
        content?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        content?.checkSymbols(symbolTable: symbolTable)
    }
    
    override func execute() -> Any? {
        _ = content?.execute()
        let returnValue = QuickMemory.shared.popObject(inStackForParser: self.parser!)
        return returnValue
    }
    
}

class QuickColor : QuickObject {
    
    var content : UIColor?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Color (\(content))\n")
    }
    
    override func getType() -> String {
        return "Color"
    }
    
    override func execute() -> Any? {
        QuickMemory.shared.pushObject(content as Any, inStackForParser: self.parser!)
        return nil
    }

}


// Thanks to https://stackoverflow.com/a/34308158/3266978
extension URLSession {
    func synchronousDataTask(with url: URL, andHeaders headers : Dictionary<String, String>? = nil) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        var request = URLRequest(url: url)
        
        if headers != nil {
            for key in headers!.keys {
                let value = headers![key]!
                request.addValue(value, forHTTPHeaderField: key)
            }
        }
        
        let dataTask = self.dataTask(with: request) {
            data = $0
            response = $1
            error = $2
            
            semaphore.signal()
        }
        
        dataTask.resume()
        
        _ = semaphore.wait(timeout: .distantFuture)
        
        return (data, response, error)
    }
}
