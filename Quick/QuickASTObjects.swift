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
        symbolTable.expectSymbol(content)
    }
    
    override func getType() -> String {
        
        guard QuickSymbolTable.sharedRoot != nil else {
            return "Symbol Table Error"
        }
        
        return QuickSymbolTable.sharedRoot!.getType(ofIdentifier: content)
    }
    
    override func execute() {
        let storedValue = QuickMemory.shared.heap[content]
        if storedValue == nil {
            QuickError.shared.setErrorMessage("Corrupted stack", withLine: -2)
        } else {
            QuickMemory.shared.stack.append(storedValue!)
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
        let leftSideValue = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideValue = QuickMemory.shared.stack.popLast()
        if getType() == "Integer" {
            let computed = (leftSideValue as! Int) + (rightSideValue as! Int)
            QuickMemory.shared.stack.append(computed)
        } else if getType() == "Float" {
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
    }
    
    func executePrintWithParameters(_ parameters : QuickParameters) {
        
        for parameter in parameters.parameters {
            parameter.execute()
            let valueToPrint = QuickMemory.shared.stack.popLast()!
            Output.shared.userVisible.append("\(valueToPrint)\n")
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
    var parent : QuickStatement?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Assignment\n")
        leftSide?.printDebugDescription(withLevel: withLevel + 1)
        rightSide?.printDebugDescription(withLevel: withLevel + 1)
    }
        
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        leftSide?.addSymbols(symbolTable: symbolTable)
        leftSide?.checkSymbols(symbolTable: symbolTable)
        rightSide?.checkSymbols(symbolTable: symbolTable)
        
        guard leftSide != nil && rightSide != nil else {
            return
        }
        
        for identifier in leftSide!.content {
            let type = rightSide!.getType()
            symbolTable.checkType(type, ofIdentifier: identifier.content)
        }
        
    }

    override func execute() {
        leftSide?.execute()
        let leftSideResult = QuickMemory.shared.stack.popLast()
        rightSide?.execute()
        let rightSideResult = QuickMemory.shared.stack.popLast()
        if rightSideResult != nil && (leftSideResult as? String) != nil {
            QuickMemory.shared.heap[leftSideResult as! String] = rightSideResult!
        } else {
            QuickError.shared.setErrorMessage("Bad value from stack during assignment", withLine: -2)
        }
    }
    
}

class QuickArray : QuickObject {
    
    var parameters : QuickParameters?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Array\n")
        parameters?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        parameters?.checkSymbols(symbolTable: symbolTable)
    }

    override func getType() -> String {
        return "Array"
    }

    override func execute() {
        parameters?.execute()
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
    var array : QuickValue?
    var executionBlock : QuickMultilineStatement?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for _ in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick For Loop\n")
        identifier?.printDebugDescription(withLevel: withLevel + 1)
        array?.printDebugDescription(withLevel: withLevel + 1)
        executionBlock?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        identifier?.addSymbols(symbolTable: symbolTable)
        identifier?.checkSymbols(symbolTable: symbolTable)
        array?.checkSymbols(symbolTable: symbolTable)
        executionBlock?.checkSymbols(symbolTable: symbolTable)
    }

    override func execute() {

        array?.execute()
        let collection = QuickMemory.shared.stack.popLast() as! Array<Any>
        for obj in collection {
            QuickMemory.shared.heap[identifier!.content] = obj
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
