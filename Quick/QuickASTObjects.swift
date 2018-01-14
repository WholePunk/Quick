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
        for i in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Statement\n")
        content?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        content?.checkSymbols(symbolTable: symbolTable)
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
        symbolTable.printSymbolTable()
        symbolTable.popScope()
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
    
}

class QuickInteger : QuickObject {
    
    var content : Int = 0
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Integer (\(content))\n")
    }
    
    override func getType() -> String {
        return "Integer"
    }
    
}

class QuickFloat : QuickObject {
    
    var content : Float = 0
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Float (\(content))\n")
    }
    
    override func getType() -> String {
        return "Float"
    }

    
}

class QuickTrue : QuickObject {
    
    let content : Bool = true
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick True\n")
    }
    
    override func getType() -> String {
        return "Boolean"
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
    
}

class QuickMathExpression : QuickObject {
    
    var content : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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
    
}

class QuickMathOperator : QuickObject {
    
    var content : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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
    
}

class QuickMultiply : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

}

class QuickDivide : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

}

class QuickMod : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

}

class QuickEqual : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

}

class QuickNotEqual : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

}

class QuickLessThan : QuickObject {
    
    var leftSide : QuickObject?
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

}

class QuickNot : QuickObject {
    
    var rightSide : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

}

class QuickParameters : QuickObject {
    
    var parameters : Array<QuickObject> = []
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

    
}

class QuickMethodCall : QuickObject {
    
    var methodName = ""
    var parameters : QuickParameters?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
            Output.shared.string.append("-")
        }
        Output.shared.string.append("Quick Method Call = \(methodName)\n")
        parameters?.printDebugDescription(withLevel: withLevel + 1)
    }
    
    override func checkSymbols(symbolTable : QuickSymbolTable) {
        symbolTable.expectSymbol(methodName)
        parameters?.checkSymbols(symbolTable: symbolTable)
    }

    
}

class QuickProperty : QuickObject {
    
    var content : Array<QuickIdentifier> = []
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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


    
}

class QuickValue : QuickObject {
    
    var content : QuickObject?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

    
}

class QuickAssignment : QuickObject {
    
    var leftSide : QuickProperty?
    var rightSide : QuickObject?
    var parent : QuickStatement?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

    
}

class QuickArray : QuickObject {
    
    var parameters : QuickParameters?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

    
}

class QuickIfStatement : QuickObject {
    
    var expression : QuickLogicalExpression?
    var executionBlock : QuickMultilineStatement?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

    
}

class QuickForLoop : QuickObject {
    
    var identifier : QuickIdentifier?
    var array : QuickArray?
    var executionBlock : QuickMultilineStatement?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

}

class QuickWhileLoop : QuickObject {
    
    var expression : QuickLogicalExpression?
    var executionBlock : QuickMultilineStatement?
    var parent : QuickObject?
    
    override func printDebugDescription(withLevel: Int) {
        for i in 0...withLevel {
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

    
}

