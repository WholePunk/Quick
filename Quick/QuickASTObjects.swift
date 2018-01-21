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
    
    func execute() {
        
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
    
    override func execute() {
        content?.execute()
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
    
    override func execute() {
        QuickSymbolTable.sharedRoot?.pushScope()
        for statement in content {
            statement.checkSymbols(symbolTable: QuickSymbolTable.sharedRoot!)
        }
        for statement in content {
            statement.execute()
        }
        QuickSymbolTable.sharedRoot?.popScope()
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
    
    override func execute() {
        QuickMemory.shared.stack.append(content)
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
    
    override func execute() {
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
    
    override func execute() {
        QuickMemory.shared.stack.append(content)
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

    override func execute() {
        QuickMemory.shared.stack.append(content)
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
    
    override func execute() {
        QuickMemory.shared.stack.append(content)
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
    
    override func execute() {
        QuickMemory.shared.stack.append(content)
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
    
    override func execute() {
        content?.execute()
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
    
    override func execute() {
        content?.execute()
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
    
    override func execute() {
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
    
    override func execute() {
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

    override func execute() {
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

    override func execute() {
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

    override func execute() {
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

    override func execute() {
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

    override func execute() {
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

    override func execute() {
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

    override func execute() {
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

    override func execute() {
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

    override func execute() {
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

    override func execute() {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        let result = (leftSideValue as! Bool) && (rightSideValue as! Bool)
        QuickMemory.shared.stack.append(result)
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

    override func execute() {
        leftSide?.execute()
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        let result = (leftSideValue as! Bool) || (rightSideValue as! Bool)
        QuickMemory.shared.stack.append(result)
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

    override func execute() {
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        let result = !(rightSideValue as! Bool)
        QuickMemory.shared.stack.append(result)
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
    
    override func execute() {
        content?.execute()
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

    override func execute() {
        var computed : Array<Any> = []
        for parameter in parameters {
            parameter.execute()
            computed.append(QuickMemory.shared.stack.popLast()!)
        }
        QuickMemory.shared.stack.append(computed)
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

    override func execute() {
        if methodName == "print" {
            executePrintWithParameters(parameters!)
        }
        if methodName == "getJSONArray" {
            executeGetJSONArrayWithParameters(parameters!)
        }
        if methodName == "getJSONDictionary" {
            executeGetJSONDictionaryWithParameters(parameters!)
        }
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

    override func execute() {
        
        var propertyString = ""
        for obj in content {
            if propertyString != "" {
                propertyString.append(".")
            }
            propertyString.append(obj.content)
        }
        QuickMemory.shared.stack.append(propertyString)
        
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

    override func execute() {
        content?.execute()
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

    override func execute() {
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
        }
        
        if rightSideResult != nil && (leftSideResult as? String) != nil {
            // Check to see if left side result is an external symbol, set directly if it is
            if QuickSymbolTable.externalSymbols[leftSideResult as! String] != nil {
                let propertyId = (leftSideResult as! NSString).components(separatedBy: ".").last! // Update with the actual property derived from left side result
                DispatchQueue.main.async {
                    (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.updateViewProperty(forIdentifier: propertyId, withNewValue: rightSideResult, withDuration: 0.3)
                    (QuickSymbolTable.externalSymbols[leftSideResult as! String] as? ViewRenderer)?.render()
                }
            }
            // Not an external symbol, assign it in the heap
            QuickMemory.shared.heap[leftSideResult as! String] = rightSideResult!
        } else {
            QuickError.shared.setErrorMessage("Bad value from stack during assignment", withLine: -2)
        }
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
    
    override func execute() {
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
    
    override func execute() {
        var computed : Dictionary<String, Any> = [:]
        key?.execute()
        let keyValue = QuickMemory.shared.stack.popLast()!
        value?.execute()
        let valueValue = QuickMemory.shared.stack.popLast()!
        computed["\(keyValue)"] = valueValue
        QuickMemory.shared.stack.append(computed)
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
    
    override func execute() {
        
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

    override func execute() {
        
        expression?.execute()
        let expressionResult = QuickMemory.shared.stack.popLast() as! Bool
        if expressionResult {
            executionBlock?.execute()
        }
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

    override func execute() {

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
            }

            QuickMemory.shared.heap[identifier!.content] = cleanObject
            executionBlock?.execute()
        }

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

    override func execute() {
        
        expression?.execute()
        var expressionResult = QuickMemory.shared.stack.popLast() as! Bool
        while expressionResult {
            executionBlock?.execute()
            expression?.execute()
            expressionResult = QuickMemory.shared.stack.popLast() as! Bool
        }
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

