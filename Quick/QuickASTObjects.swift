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

class QuickObject {
    
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
        return content?.execute()
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
        QuickSymbolTable.sharedRoot?.pushScope()
        for statement in content {
            statement.checkSymbols(symbolTable: QuickSymbolTable.sharedRoot!)
        }
        for statement in content {
            let returnValue = statement.execute()
            if returnValue != nil {
                QuickSymbolTable.sharedRoot?.popScope()
                return returnValue
            }
        }
        QuickSymbolTable.sharedRoot?.popScope()
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
        QuickMemory.shared.stack.append(content)
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
            if QuickSymbolTable.sharedRoot!.getType(ofIdentifier: content) != "Array" && QuickSymbolTable.sharedRoot!.getType(ofIdentifier: content) != "Dictionary" {
                QuickError.shared.setErrorMessage("Subscripts are only allowed on arrays and dictionaries", withLine: -2)
            }
            if QuickSymbolTable.sharedRoot!.getType(ofIdentifier: content) == "Array" {
                if subscriptValue?.getType() != "Integer" {
                    QuickError.shared.setErrorMessage("Array subscripts must be integers", withLine: -2)
                }
            }
            if QuickSymbolTable.sharedRoot!.getType(ofIdentifier: content) == "Dictionary" {
                if subscriptValue?.getType() != "String" {
                    QuickError.shared.setErrorMessage("Dictionary subscripts must be strings", withLine: -2)
                }
            }
        }
        
        
        
        symbolTable.expectSymbol(content)
    }
    
    override func getType() -> String {
        
        guard QuickSymbolTable.sharedRoot != nil else {
            return "Symbol Table Error"
        }
        
        if subscriptValue != nil {
            return ""
        }
        
        return QuickSymbolTable.sharedRoot!.getType(ofIdentifier: content)
    }
    
    override func execute() -> Any? {
        let storedValue = QuickMemory.shared.heap[content]
        if storedValue == nil {
            QuickError.shared.setErrorMessage("Corrupted heap", withLine: -2)
        } else {
            
            if subscriptValue == nil {
                QuickMemory.shared.stack.append(storedValue!)
            } else {
                if QuickSymbolTable.sharedRoot!.getType(ofIdentifier: content) == "Array" {
                    let parametersArray = storedValue as! Array<Any>
                    subscriptValue?.execute()
                    let subscriptInt = QuickMemory.shared.stack.popLast() as! Int
                    if subscriptInt >= parametersArray.count {
                        QuickError.shared.setErrorMessage("Array index is out of bounds", withLine: -2)
                    }
                    QuickMemory.shared.stack.append(parametersArray[subscriptInt])
                } else if QuickSymbolTable.sharedRoot!.getType(ofIdentifier: content) == "Dictionary" {
                    subscriptValue?.execute()
                    let subscriptString = QuickMemory.shared.stack.popLast() as! String
                    let dictionary = storedValue as! Dictionary<String, Any>
                    if dictionary[subscriptString] == nil {
                        QuickMemory.shared.stack.append("NULL")
                    } else {
                        QuickMemory.shared.stack.append(dictionary[subscriptString]!)
                    }
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
        QuickMemory.shared.stack.append(content)
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
        QuickMemory.shared.stack.append(content)
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
        QuickMemory.shared.stack.append(content)
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
        QuickMemory.shared.stack.append(content)
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
        var leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        var rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) + (rightSideValue as! Int)
            QuickMemory.shared.stack.append(computed)
        } else if getType() == "Float" {
            if leftSideValue is CGFloat {
                leftSideValue = Float(leftSideValue as! CGFloat)
            }
            if rightSideValue is CGFloat {
                rightSideValue = Float(rightSideValue as! CGFloat)
            }
            let computed = (leftSideValue as! Float) + (rightSideValue as! Float)
            QuickMemory.shared.stack.append(computed)
        } else {
            QuickMemory.shared.stack.append(0)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) - (rightSideValue as! Int)
            QuickMemory.shared.stack.append(computed)
        } else if getType() == "Float" {
            let computed = (leftSideValue as! Float) - (rightSideValue as! Float)
            QuickMemory.shared.stack.append(computed)
        } else {
            QuickMemory.shared.stack.append(0)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) * (rightSideValue as! Int)
            QuickMemory.shared.stack.append(computed)
        } else if getType() == "Float" {
            let computed = (leftSideValue as! Float) * (rightSideValue as! Float)
            QuickMemory.shared.stack.append(computed)
        } else {
            QuickMemory.shared.stack.append(0)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) / (rightSideValue as! Int)
            QuickMemory.shared.stack.append(computed)
        } else if getType() == "Float" {
            let computed = (leftSideValue as! Float) / (rightSideValue as! Float)
            QuickMemory.shared.stack.append(computed)
        } else {
            QuickMemory.shared.stack.append(0)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) % (rightSideValue as! Int)
            QuickMemory.shared.stack.append(computed)
        } else if getType() == "Float" {
            let computed = (leftSideValue as! Float).truncatingRemainder(dividingBy: (rightSideValue as! Float))
            QuickMemory.shared.stack.append(computed)
        } else {
            QuickMemory.shared.stack.append(0)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) == (rightSideValue as! Int)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) == (rightSideValue as! Float)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "String" {
            let result = (leftSideValue as! String) == (rightSideValue as! String)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "Boolean" {
            let result = (leftSideValue as! Bool) == (rightSideValue as! Bool)
            QuickMemory.shared.stack.append(result)
        } else {
            QuickMemory.shared.stack.append(false)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) != (rightSideValue as! Int)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) != (rightSideValue as! Float)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "String" {
            let result = (leftSideValue as! String) != (rightSideValue as! String)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "Boolean" {
            let result = (leftSideValue as! Bool) != (rightSideValue as! Bool)
            QuickMemory.shared.stack.append(result)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) < (rightSideValue as! Int)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) < (rightSideValue as! Float)
            QuickMemory.shared.stack.append(result)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) > (rightSideValue as! Int)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) > (rightSideValue as! Float)
            QuickMemory.shared.stack.append(result)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) <= (rightSideValue as! Int)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) <= (rightSideValue as! Float)
            QuickMemory.shared.stack.append(result)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let result = (leftSideValue as! Int) >= (rightSideValue as! Int)
            QuickMemory.shared.stack.append(result)
        } else if getType() == "Float" {
            let result = (leftSideValue as! Float) >= (rightSideValue as! Float)
            QuickMemory.shared.stack.append(result)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        let result = (leftSideValue as! Bool) && (rightSideValue as! Bool)
        QuickMemory.shared.stack.append(result)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        let result = (leftSideValue as! Bool) || (rightSideValue as! Bool)
        QuickMemory.shared.stack.append(result)
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
        let rightSideValue = QuickMemory.shared.stack.popLast()
        let result = !(rightSideValue as! Bool)
        QuickMemory.shared.stack.append(result)
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
            computed.append(QuickMemory.shared.stack.popLast()!)
        }
        QuickMemory.shared.stack.append(computed)
        return nil
    }

}

class QuickMethodCall : QuickObject {
    
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

        return nil

    }
    
    func executePrintWithParameters(_ parameters : QuickParameters) {
        
        for parameter in parameters.parameters {
            parameter.execute()
            let valueToPrint = QuickMemory.shared.stack.popLast()!
            Output.shared.userVisible.append("\(valueToPrint)\n")
        }
        
    }

    func executeGetJSONArrayWithParameters(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.stack.append([])
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.stack.popLast()
        
        guard parameterValue as? String != nil else {
            QuickMemory.shared.stack.append([])
            return
        }
        
        let url = URL(string: parameterValue as! String)
        guard url != nil else {
            QuickMemory.shared.stack.append([])
            return
        }
        
        var data : Data?
        var response : URLResponse?
        var error : Error?
        (data, response, error) = URLSession.shared.synchronousDataTask(with: url!)
        
        if error != nil {
            QuickMemory.shared.stack.append([])
            return
        }
        
        do {
            if let data = data,
                let json = try JSONSerialization.jsonObject(with: data) as? [Any] {
                QuickMemory.shared.stack.append(json)
                return
            }
        } catch {
            print("Error deserializing JSON")
        }
        
        QuickMemory.shared.stack.append([])

    }
    
    func executeGetJSONDictionaryWithParameters(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.stack.popLast()
        
        guard parameterValue as? String != nil else {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        let url = URL(string: parameterValue as! String)
        guard url != nil else {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        var data : Data?
        var response : URLResponse?
        var error : Error?
        (data, response, error) = URLSession.shared.synchronousDataTask(with: url!)
        
        if error != nil {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        do {
            if let data = data,
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                QuickMemory.shared.stack.append(json)
                return
            }
        } catch {
            print("Error deserializing JSON")
        }
        
        QuickMemory.shared.stack.append([:])
        
    }

    func executeGetImageWithParameters(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.stack.popLast()
        
        guard parameterValue as? String != nil else {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        let url = URL(string: parameterValue as! String)
        guard url != nil else {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        var data : Data?
        var response : URLResponse?
        var error : Error?
        (data, response, error) = URLSession.shared.synchronousDataTask(with: url!)
        
        if error != nil {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        if let data = data,
            let image = UIImage(data: data) {
            QuickMemory.shared.stack.append(image)
            return
        }
        
        QuickMemory.shared.stack.append(UIImage(named: "blank"))
        
    }

    func executeEncodeBase64(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.stack.append("")
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.stack.popLast()
        
        guard parameterValue as? String != nil else {
            QuickMemory.shared.stack.append("")
            return
        }
        
        
        let base64String = (parameterValue as! String).data(using: String.Encoding.utf8)!.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
        
        QuickMemory.shared.stack.append(base64String)
        
    }

    func executeCountArray(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.stack.append(0)
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.stack.popLast()
        
        guard parameterValue as? Array<Any> != nil else {
            QuickMemory.shared.stack.append(0)
            return
        }
        
        let count = (parameterValue as! Array<Any>).count
        
        QuickMemory.shared.stack.append(count)
        
    }

    func executeCountDictionary(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.stack.append(0)
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.stack.popLast()
        
        guard parameterValue as? Dictionary<String, Any> != nil else {
            QuickMemory.shared.stack.append(0)
            return
        }
        
        let count = (parameterValue as! Dictionary<String, Any>).count
        
        QuickMemory.shared.stack.append(count)
        
    }

    func executeGetDictionaryKeys(_ parameters : QuickParameters) {
        
        if parameters.parameters.count > 1 || parameters.parameters.count == 0 {
            QuickMemory.shared.stack.append([])
            return
        }
        
        // We only have a single parameter
        let parameter = parameters.parameters[0]
        parameter.execute()
        let parameterValue = QuickMemory.shared.stack.popLast()
        
        guard parameterValue as? Dictionary<String, Any> != nil else {
            QuickMemory.shared.stack.append([])
            return
        }
        
        var allKeys : Array<Any> = []
        for key in (parameterValue as! Dictionary<String, Any>).keys {
            allKeys.append(key)
        }
        
        QuickMemory.shared.stack.append(allKeys)
        
    }
    
    func executeAddItemToDictionary(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 3 {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        // We have three parameters.  Verify that the first is a dictionary and the second is a string
        var parameter = parameters.parameters[0]
        parameter.execute()
        let dictionaryParameterValue = QuickMemory.shared.stack.popLast()
        
        guard dictionaryParameterValue as? Dictionary<String, Any> != nil else {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        parameter = parameters.parameters[1]
        parameter.execute()
        let keyParameterValue = QuickMemory.shared.stack.popLast()
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        parameter = parameters.parameters[2]
        parameter.execute()
        let valueParameterValue = QuickMemory.shared.stack.popLast()
        
        var newDictionary : Dictionary<String, Any> = [:]
        for key in (dictionaryParameterValue as! Dictionary<String, Any>).keys {
            newDictionary[key] = (dictionaryParameterValue as! Dictionary<String, Any>)[key]
        }
        newDictionary[keyParameterValue as! String] = valueParameterValue
        
        QuickMemory.shared.stack.append(newDictionary)
        
    }

    func executeRemoveItemFromDictionary(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        // We have three parameters.  Verify that the first is a dictionary and the second is a string
        var parameter = parameters.parameters[0]
        parameter.execute()
        let dictionaryParameterValue = QuickMemory.shared.stack.popLast()
        
        guard dictionaryParameterValue as? Dictionary<String, Any> != nil else {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        parameter = parameters.parameters[1]
        parameter.execute()
        let keyParameterValue = QuickMemory.shared.stack.popLast()
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.stack.append([:])
            return
        }
        
        var newDictionary : Dictionary<String, Any> = [:]
        for key in (dictionaryParameterValue as! Dictionary<String, Any>).keys {
            newDictionary[key] = (dictionaryParameterValue as! Dictionary<String, Any>)[key]
        }
        newDictionary[keyParameterValue as! String] = nil
        
        QuickMemory.shared.stack.append(newDictionary)
        
    }
    
    func executeAddItemToArray(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.stack.append([])
            return
        }
        
        // We have three parameters.  Verify that the first is a dictionary and the second is a string
        var parameter = parameters.parameters[0]
        parameter.execute()
        let arrayParameterValue = QuickMemory.shared.stack.popLast()
        
        guard arrayParameterValue as? Array<Any> != nil else {
            QuickMemory.shared.stack.append([])
            return
        }
        
        parameter = parameters.parameters[1]
        parameter.execute()
        let valueParameterValue = QuickMemory.shared.stack.popLast()
        
        var newArray : Array<Any> = []
        for item in arrayParameterValue as! Array<Any> {
            newArray.append(item)
        }
        newArray.append(valueParameterValue!)
        
        QuickMemory.shared.stack.append(newArray)
        
    }

    func executeSetAppVariable(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.stack.append(false)
            return
        }
        
        // We have two parameters.  Verify that the first is a string.  The second one can be any type.
        let keyParameter = parameters.parameters[0]
        _ = keyParameter.execute()
        let keyParameterValue = QuickMemory.shared.stack.popLast()
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.stack.append(false)
            return
        }
        
        let valueParameter = parameters.parameters[1]
        _ = valueParameter.execute()
        let valueParameterValue = QuickMemory.shared.stack.popLast()!
        
        // Save to some app-wide context
        let fullKeyName = "app.\(keyParameterValue as! String)"
        QuickMemory.appWide.heap[fullKeyName] = valueParameterValue
        
        QuickMemory.shared.stack.append(true)
        
    }

    func executeGetAppVariable(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 1 {
            QuickMemory.shared.stack.append("")
            return
        }
        
        // We have one parameter.  Verify that the first is a string.
        let keyParameter = parameters.parameters[0]
        _ = keyParameter.execute()
        let keyParameterValue = QuickMemory.shared.stack.popLast()
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.stack.append("")
            return
        }
        
        // Grab from the app wide context
        let fullKeyName = "app.\(keyParameterValue as! String)"
        let value = QuickMemory.appWide.heap[fullKeyName]
        
        if value != nil {
            QuickMemory.shared.stack.append(value!)
        } else {
            QuickMemory.shared.stack.append("")
        }
        
        
    }

    func executeSetScreenVariable(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 2 {
            QuickMemory.shared.stack.append(false)
            return
        }
        
        // We have two parameters.  Verify that the first is a string.  The second one can be any type.
        let keyParameter = parameters.parameters[0]
        _ = keyParameter.execute()
        let keyParameterValue = QuickMemory.shared.stack.popLast()
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.stack.append(false)
            return
        }
        
        let valueParameter = parameters.parameters[1]
        _ = valueParameter.execute()
        let valueParameterValue = QuickMemory.shared.stack.popLast()
        
        // Save to some app-wide context
        let visibleViewController = RenderCompiler.sharedInstance.appRenderer!.getVisibleViewController()!
        let fullKeyName = "screen.\(visibleViewController.getId()).\(keyParameterValue as! String)"
        QuickMemory.appWide.heap[fullKeyName] = valueParameterValue

        QuickMemory.shared.stack.append(true)
        
    }
    
    func executeGetScreenVariable(_ parameters : QuickParameters) {
        
        if parameters.parameters.count != 1 {
            QuickMemory.shared.stack.append("")
            return
        }
        
        // We have one parameter.  Verify that the first is a string.
        let keyParameter = parameters.parameters[0]
        _ = keyParameter.execute()
        let keyParameterValue = QuickMemory.shared.stack.popLast()
        
        guard keyParameterValue as? String != nil else {
            QuickMemory.shared.stack.append("")
            return
        }
        
        // Grab from the app wide context
        let visibleViewController = RenderCompiler.sharedInstance.appRenderer!.getVisibleViewController()!
        let fullKeyName = "screen.\(visibleViewController.getId()).\(keyParameterValue as! String)"
        let value = QuickMemory.appWide.heap[fullKeyName]
        
        if value != nil {
            QuickMemory.shared.stack.append(value!)
        } else {
            QuickMemory.shared.stack.append("")
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
        QuickMemory.shared.stack.append(propertyString)
        
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
        let leftSideResult = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        var rightSideResult = QuickMemory.shared.stack.popLast()
        
        if castingType == "Integer" {
            if !(rightSideResult is Integer) {
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
                rightSideResult = UIImage(named: "blank")
            }
        }

        if rightSideResult != nil && (leftSideResult as? String) != nil {
            // Check to see if left side result is an external symbol, set directly if it is
            if QuickSymbolTable.externalSymbols[leftSideResult as! String] != nil {
                let propertyId = (leftSideResult as! NSString).components(separatedBy: ".").last! // Update with the actual property derived from left side result
                DispatchQueue.main.async {
                    
                    if rightSideResult is UIImage {
                        let imageUUID = UUID().uuidString
                        ImageManager.sharedInstance.addTempImage(rightSideResult as! UIImage, withName: imageUUID)
                        (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.updateViewProperty(forIdentifier: propertyId, withNewValue: imageUUID, withDuration: 0.3)
                        (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.render()
                    } else {
                        (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.updateViewProperty(forIdentifier: propertyId, withNewValue: rightSideResult, withDuration: 0.3)
                        (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.render()
                    }
                    
                }
            }
            // Not an external symbol, assign it in the heap
            QuickMemory.shared.heap[leftSideResult as! String] = rightSideResult!
        } else {
            QuickError.shared.setErrorMessage("Bad value from stack during assignment", withLine: -2)
        }
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
            let parametersArray = QuickMemory.shared.stack.popLast() as! Array<Any>
            subscriptValue?.execute()
            let subscriptInt = QuickMemory.shared.stack.popLast() as! Int
            if subscriptInt >= parametersArray.count {
                QuickError.shared.setErrorMessage("Array index is out of bounds", withLine: -2)
            }
            QuickMemory.shared.stack.append(parametersArray[subscriptInt])
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
        let keyValue = QuickMemory.shared.stack.popLast()!
        value?.execute()
        let valueValue = QuickMemory.shared.stack.popLast()!
        computed["\(keyValue)"] = valueValue
        QuickMemory.shared.stack.append(computed)
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
            let pairResult = QuickMemory.shared.stack.popLast() as! Dictionary<String, Any>
            computed.add(dictionary: pairResult)
        }
        QuickMemory.shared.stack.append(computed)
        
        if subscriptValue != nil {
            subscriptValue?.execute()
            let subscriptString = QuickMemory.shared.stack.popLast() as! String
            if computed[subscriptString] == nil {
                QuickMemory.shared.stack.append("NULL")
            } else {
                QuickMemory.shared.stack.append(computed[subscriptString]!)
            }
        }
        
        return nil
        
    }
    
}

class QuickIfStatement : QuickObject {
    
    var expression : QuickLogicalExpression?
    var executionBlock : QuickMultilineStatement?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick If Statement\n")
        expression?.printDebugDescription(withLevel: withLevel + 1)
        executionBlock?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func addSymbols(symbolTable : QuickSymbolTable) {
        executionBlock?.addSymbols(symbolTable: symbolTable)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        expression?.checkSymbols(symbolTable: symbolTable)
        executionBlock?.checkSymbols(symbolTable: symbolTable)
    }

    override func execute() -> Any? {

        expression?.execute()
        let expressionResult = QuickMemory.shared.stack.popLast() as! Bool
        if expressionResult {
            executionBlock?.execute()
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
        let collection = QuickMemory.shared.stack.popLast() as! Array<Any>
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

            QuickMemory.shared.heap[identifier!.content] = cleanObject
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
        var expressionResult = QuickMemory.shared.stack.popLast() as! Bool
        while expressionResult {
            executionBlock?.execute()
            expression?.execute()
            expressionResult = QuickMemory.shared.stack.popLast() as! Bool
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
        let returnValue = QuickMemory.shared.stack.popLast()
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
        QuickMemory.shared.stack.append(content as Any)
        return nil
    }

}


// Thanks to https://stackoverflow.com/a/34308158/3266978
extension URLSession {
    func synchronousDataTask(with url: URL) -> (Data?, URLResponse?, Error?) {
        var data: Data?
        var response: URLResponse?
        var error: Error?
        
        let semaphore = DispatchSemaphore(value: 0)
        
        let dataTask = self.dataTask(with: url) {
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

