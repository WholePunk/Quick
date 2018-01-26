//
//  QuickParser.swift
//  Quick
//
//  Created by Bob Warwick on 2018-01-10.
//  Copyright © 2018 Whole Punk Creators Ltd. All rights reserved.
//

/****************/
/* QUICK PARSER */
/****************/

class Parser {
    
    var tokenIndex = 0
    var tokens : Array<Token> = []
    var errorAt = -1
    var lastCreatedQuickObject : QuickObject?
    var root = QuickMultilineStatement()
    var symbolTable = QuickSymbolTable()
    var currentLine = 0
    var highlightedSource : NSMutableAttributedString = NSMutableAttributedString(string: "")
    
    func currentToken() -> Token {
        return tokens[tokenIndex]
    }
    
    func currentType() -> TokenType {
        return tokens[tokenIndex].tokenType
    }
    
    func nextType() -> TokenType {
        return tokens[tokenIndex + 1].tokenType
    }
    
    func highlightSource(fromSource: String) {
        
        highlightedSource = NSMutableAttributedString(string: fromSource)
        while currentType() != TokenType.EOF {
            if currentType() == TokenType.STRING {
                highlightedSource.setAttributes([NSForegroundColorAttributeName: "C41A16".hexColor], range: NSRange(location: currentToken().startIndex, length: (currentToken().endIndex - currentToken().startIndex)))
            }
            if currentType() == TokenType.METHODNAME {
                highlightedSource.setAttributes([NSForegroundColorAttributeName: "2E0D6E".hexColor], range: NSRange(location: currentToken().startIndex, length: (currentToken().endIndex - currentToken().startIndex)))
            }
            if currentType() == TokenType.ASSIGNMENT || currentType() == TokenType.OPENBRACE || currentType() == TokenType.CLOSEBRACE || currentType() == TokenType.IF || currentType() == TokenType.FOR || currentType() == TokenType.IN || currentType() == TokenType.WHILE || currentType() == TokenType.PLUS || currentType() == TokenType.MINUS || currentType() == TokenType.MULTIPLY || currentType() == TokenType.DIVIDE || currentType() == TokenType.MOD || currentType() == TokenType.OPENARGUMENTS || currentType() == TokenType.CLOSEARGUMENTS || currentType() == TokenType.ARGUMENTSEPERATOR || currentType() == TokenType.KEYVALUESEPERATOR  || currentType() == TokenType.AND  || currentType() == TokenType.OR  || currentType() == TokenType.NOT  || currentType() == TokenType.EQUALS || currentType() == TokenType.DOESNOTEQUAL || currentType() == TokenType.SMALLERTHAN || currentType() == TokenType.SMALLERTHANOREQUAL || currentType() == TokenType.LARGERTHAN || currentType() == TokenType.LARGERTHANOREQUAL || currentType() == TokenType.STARTARRAY || currentType() == TokenType.ENDARRAY || currentType() == TokenType.CAST || currentType() == TokenType.RETURN {
                highlightedSource.setAttributes([NSForegroundColorAttributeName: "AA0D91".hexColor], range: NSRange(location: currentToken().startIndex, length: (currentToken().endIndex - currentToken().startIndex)))
            }
            if currentType() == TokenType.INTEGER || currentType() == TokenType.FLOAT || currentType() == TokenType.TRUE || currentType() == TokenType.FALSE || currentType() == TokenType.COLOR {
                highlightedSource.setAttributes([NSForegroundColorAttributeName: "1C00CF".hexColor], range: NSRange(location: currentToken().startIndex, length: (currentToken().endIndex - currentToken().startIndex)))
            }
            if currentType() == TokenType.INTEGERTYPE || currentType() == TokenType.FLOATTYPE || currentType() == TokenType.BOOLEANTYPE || currentType() == TokenType.STRINGTYPE || currentType() == TokenType.DICTIONARYTYPE || currentType() == TokenType.ARRAYTYPE || currentType() == TokenType.COLORTYPE || currentType() == TokenType.IMAGETYPE {
                highlightedSource.setAttributes([NSForegroundColorAttributeName: "5C2699".hexColor], range: NSRange(location: currentToken().startIndex, length: (currentToken().endIndex - currentToken().startIndex)))
            }
            
            tokenIndex += 1
        }
        highlightedSource.addAttributes([NSFontAttributeName: UIFont.monospacedDigitSystemFont(ofSize: 18.0, weight: UIFontWeightMedium)], range: NSRange(location: 0, length: fromSource.utf16.count))
        
    }
    
    func parse(fromSource: String) -> Bool {
        
        symbolTable.addSymbol("print", ofType: "String")
        symbolTable.addSymbol("getJSONArray", ofType: "Array")
        symbolTable.addSymbol("getJSONDictionary", ofType: "Dictionary")
        symbolTable.addSymbol("getImage", ofType: "Image")
        symbolTable.addSymbol("encodeBase64", ofType: "String")
        symbolTable.addSymbol("countArray", ofType: "Integer")
        symbolTable.addSymbol("countDictionary", ofType: "Integer")
        symbolTable.addSymbol("getDictionaryKeys", ofType: "Array")
        symbolTable.addSymbol("addItemToDictionary", ofType: "Dictionary")
        symbolTable.addSymbol("removeItemFromDictionary", ofType: "Dictionary")
        symbolTable.addSymbol("addItemToArray", ofType: "Array")
        symbolTable.addSymbol("setAppVariable", ofType: "Boolean")
        symbolTable.addSymbol("getAppVariable", ofType: "")
        symbolTable.addSymbol("setScreenVariable", ofType: "Boolean")
        symbolTable.addSymbol("getScreenVariable", ofType: "")

        QuickSymbolTable.sharedRoot = symbolTable
        Output.shared.string = ""
        self.tokens = Tokenizer().tokens(fromSource: fromSource)
        
        lastCreatedQuickObject = root
        
        highlightSource(fromSource: fromSource)
        
        // We expect that a program should be composed of newlines and statements, until it hits an EOF, then we're done.
        tokenIndex = 0
        while currentType() != TokenType.EOF && errorAt == -1 {
            
            if currentType() == TokenType.NEWLINE {
                currentLine += 1
                tokenIndex += 1
            } else {
                if !parseStatement() {
                    errorAt = tokenIndex
                    QuickError.shared.setErrorMessage("Parse error", withLine: currentLine)
                    return false
                }
                root.addStatement(lastCreatedQuickObject as! QuickStatement)
            }
            
        }
        
        root.checkSymbols(symbolTable: symbolTable)
        
        return true
        
    }
    
    func parseMultilineStatement() -> Bool {
        
        let astObject = QuickMultilineStatement()
        let backtrackIndex = tokenIndex
        
        if currentType() == TokenType.EOF {
            lastCreatedQuickObject = astObject
            return true
        }
        
        if currentType() == TokenType.CLOSEBRACE {
            tokenIndex += 1
            lastCreatedQuickObject = astObject
            return true
        }
        
        while currentType() == TokenType.NEWLINE {
            currentLine += 1
            tokenIndex += 1
            if currentType() == TokenType.EOF {
                lastCreatedQuickObject = astObject
                return true
            }
        }
        
        if parseStatement() {
            astObject.addStatement(lastCreatedQuickObject as! QuickStatement)
        } else {
            tokenIndex += 1
            return true
        }
        
        if parseMultilineStatement() {
            let recursiveObject = lastCreatedQuickObject as? QuickMultilineStatement
            if recursiveObject == nil {
                tokenIndex = backtrackIndex
                return false
            }
            for statement in recursiveObject!.content {
                astObject.addStatement(statement)
            }
        }
        
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseStatement() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickStatement()
        
        if parseAssignment() {
            if currentType() == TokenType.NEWLINE {
                astObject.content = lastCreatedQuickObject as? QuickAssignment
                lastCreatedQuickObject = astObject
                currentLine += 1
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                QuickError.shared.setErrorMessage("Parse error - invalid assignment", withLine: currentLine)
                return false
            }
        } else if parseForLoop() {
            if currentType() == TokenType.NEWLINE {
                astObject.content = lastCreatedQuickObject as? QuickForLoop
                lastCreatedQuickObject = astObject
                currentLine += 1
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                QuickError.shared.setErrorMessage("Parse error - invalid for loop", withLine: currentLine)
                return false
            }
        } else if parseWhileLoop() {
            if currentType() == TokenType.NEWLINE {
                astObject.content = lastCreatedQuickObject as? QuickWhileLoop
                lastCreatedQuickObject = astObject
                currentLine += 1
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                QuickError.shared.setErrorMessage("Parse error - invalid while loop", withLine: currentLine)
                return false
            }
        } else if parseIfStatement() {
            if currentType() == TokenType.NEWLINE {
                astObject.content = lastCreatedQuickObject as? QuickIfStatement
                lastCreatedQuickObject = astObject
                currentLine += 1
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                QuickError.shared.setErrorMessage("Parse error - invalid if statement", withLine: currentLine)
                return false
            }
        } else if parseMethodCall() {
            if currentType() == TokenType.NEWLINE {
                astObject.content = lastCreatedQuickObject as? QuickMethodCall
                lastCreatedQuickObject = astObject
                currentLine += 1
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                QuickError.shared.setErrorMessage("Parse error - invalid method call", withLine: currentLine)
                return false
            }
        } else if parseReturnStatement() {
            if currentType() == TokenType.NEWLINE {
                astObject.content = lastCreatedQuickObject as? QuickReturnStatement
                lastCreatedQuickObject = astObject
                currentLine += 1
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                QuickError.shared.setErrorMessage("Parse error - invalid return statement", withLine: currentLine)
                return false
            }
        } else {
            tokenIndex = backtrackIndex
            QuickError.shared.setErrorMessage("Parse error - invalid statement", withLine: currentLine)
            return false
        }
        
    }
    
    func parseValue() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickValue()
        
        if parseMathExpression() {
            astObject.content = lastCreatedQuickObject as? QuickMathExpression
            lastCreatedQuickObject = astObject
            return true
        } else if parseIdentifier() {
            astObject.content = lastCreatedQuickObject as? QuickIdentifier
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.STRING {
            let stringObject = QuickString()
            stringObject.parent = astObject
            stringObject.content = currentToken().tokenString
            astObject.content = stringObject
            lastCreatedQuickObject = astObject
            tokenIndex += 1
            return true
        } else if parseMethodCall() {
            astObject.content = lastCreatedQuickObject as? QuickMethodCall
            lastCreatedQuickObject = astObject
            return true
        } else if parseArray() {
            astObject.content = lastCreatedQuickObject as? QuickArray
            lastCreatedQuickObject = astObject
            return true
        } else if parseDictionary() {
            astObject.content = lastCreatedQuickObject as? QuickDictionary
            lastCreatedQuickObject = astObject
            return true
        } else if parseColor() {
            astObject.content = lastCreatedQuickObject as? QuickColor
            lastCreatedQuickObject = astObject
            return true
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
    }
    
    func parseIdentifier() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickIdentifier()
        
        if currentType() == TokenType.IDENTIFIER {
            astObject.content = currentToken().tokenString
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        // Identifiers *can* be followed by an immediate subscript, but don't require it
        if currentType() != TokenType.STARTARRAY {
            lastCreatedQuickObject = astObject
            return true // No subscript, let's keep going
        }
        tokenIndex += 1
        
        if !parseValue() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.subscriptValue = lastCreatedQuickObject as? QuickValue
        
        if currentType() != TokenType.ENDARRAY {
            tokenIndex = backtrackIndex
            return false
        }
        tokenIndex += 1
        
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseMathOperators() -> Bool {
        
        let backtrackIndex = tokenIndex
        
        if currentType() == TokenType.PLUS {
            tokenIndex += 1
            let astObject = QuickPlus()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.MINUS {
            tokenIndex += 1
            let astObject = QuickMinus()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.MULTIPLY {
            tokenIndex += 1
            let astObject = QuickMultiply()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.DIVIDE {
            tokenIndex += 1
            let astObject = QuickDivide()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.MOD {
            tokenIndex += 1
            let astObject = QuickMod()
            lastCreatedQuickObject = astObject
            return true
        }
        
        tokenIndex = backtrackIndex
        return false
        
    }
    
    func parseMathExpression() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickMathExpression()
        
        if currentType() == TokenType.INTEGER {
            let quickInteger = QuickInteger()
            quickInteger.content = Int(currentToken().tokenString)!
            quickInteger.parent = astObject
            astObject.content = quickInteger
            
            tokenIndex += 1
            
            if !parseMathOperators() {
                lastCreatedQuickObject = astObject
                return true
            }
            quickInteger.parent = lastCreatedQuickObject
            (lastCreatedQuickObject as? QuickPlus)?.leftSide = quickInteger
            (lastCreatedQuickObject as? QuickMinus)?.leftSide = quickInteger
            (lastCreatedQuickObject as? QuickMultiply)?.leftSide = quickInteger
            (lastCreatedQuickObject as? QuickDivide)?.leftSide = quickInteger
            (lastCreatedQuickObject as? QuickMod)?.leftSide = quickInteger
            
            if parseMathExpression() {
                (lastCreatedQuickObject as? QuickMathExpression)?.parent = quickInteger.parent
                (quickInteger.parent as? QuickPlus)?.rightSide = lastCreatedQuickObject
                (quickInteger.parent as? QuickMinus)?.rightSide = lastCreatedQuickObject
                (quickInteger.parent as? QuickMultiply)?.rightSide = lastCreatedQuickObject
                (quickInteger.parent as? QuickDivide)?.rightSide = lastCreatedQuickObject
                (quickInteger.parent as? QuickMod)?.rightSide = lastCreatedQuickObject
                astObject.content = quickInteger.parent
                lastCreatedQuickObject = astObject
                return true
            } else {
                return false
            }
            
        } else if currentType() == TokenType.FLOAT {
            let quickFloat = QuickFloat()
            quickFloat.content = Float(currentToken().tokenString)!
            quickFloat.parent = astObject
            astObject.content = quickFloat
            tokenIndex += 1
            
            if !parseMathOperators() {
                lastCreatedQuickObject = astObject
                return true
            }
            quickFloat.parent = lastCreatedQuickObject
            (lastCreatedQuickObject as? QuickPlus)?.leftSide = quickFloat
            (lastCreatedQuickObject as? QuickMinus)?.leftSide = quickFloat
            (lastCreatedQuickObject as? QuickMultiply)?.leftSide = quickFloat
            (lastCreatedQuickObject as? QuickDivide)?.leftSide = quickFloat
            (lastCreatedQuickObject as? QuickMod)?.leftSide = quickFloat
            
            if parseMathExpression() {
                (lastCreatedQuickObject as? QuickMathExpression)?.parent = quickFloat.parent
                (quickFloat.parent as? QuickPlus)?.rightSide = lastCreatedQuickObject
                (quickFloat.parent as? QuickMinus)?.rightSide = lastCreatedQuickObject
                (quickFloat.parent as? QuickMultiply)?.rightSide = lastCreatedQuickObject
                (quickFloat.parent as? QuickDivide)?.rightSide = lastCreatedQuickObject
                (quickFloat.parent as? QuickMod)?.rightSide = lastCreatedQuickObject
                astObject.content = quickFloat.parent
                lastCreatedQuickObject = astObject
                return true
            } else {
                return false
            }
            
        } else if parseIdentifier() {
            let quickIdentifier = lastCreatedQuickObject as! QuickIdentifier
            astObject.content = quickIdentifier
            
            if !parseMathOperators() {
                lastCreatedQuickObject = astObject
                return true
            }
            quickIdentifier.parent = lastCreatedQuickObject
            (lastCreatedQuickObject as? QuickPlus)?.leftSide = quickIdentifier
            (lastCreatedQuickObject as? QuickMinus)?.leftSide = quickIdentifier
            (lastCreatedQuickObject as? QuickMultiply)?.leftSide = quickIdentifier
            (lastCreatedQuickObject as? QuickDivide)?.leftSide = quickIdentifier
            (lastCreatedQuickObject as? QuickMod)?.leftSide = quickIdentifier
            
            if parseMathExpression() {
                (lastCreatedQuickObject as? QuickMathExpression)?.parent = quickIdentifier.parent
                (quickIdentifier.parent as? QuickPlus)?.rightSide = lastCreatedQuickObject
                (quickIdentifier.parent as? QuickMinus)?.rightSide = lastCreatedQuickObject
                (quickIdentifier.parent as? QuickMultiply)?.rightSide = lastCreatedQuickObject
                (quickIdentifier.parent as? QuickDivide)?.rightSide = lastCreatedQuickObject
                (quickIdentifier.parent as? QuickMod)?.rightSide = lastCreatedQuickObject
                astObject.content = quickIdentifier.parent
                lastCreatedQuickObject = astObject
                return true
            } else {
                return false
            }
        }
        
        tokenIndex = backtrackIndex
        return false
        
    }
    
    func parseLogicalOperator() -> Bool {
        
        let backtrackIndex = tokenIndex
        
        if currentType() == TokenType.EQUALS {
            tokenIndex += 1
            let astObject = QuickEqual()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.DOESNOTEQUAL {
            tokenIndex += 1
            let astObject = QuickNotEqual()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.LARGERTHAN {
            tokenIndex += 1
            let astObject = QuickGreaterThan()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.SMALLERTHAN {
            tokenIndex += 1
            let astObject = QuickLessThan()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.LARGERTHANOREQUAL {
            tokenIndex += 1
            let astObject = QuickGreaterThanOrEqualTo()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.SMALLERTHANOREQUAL {
            tokenIndex += 1
            let astObject = QuickLessThanOrEqualTo()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.AND {
            tokenIndex += 1
            let astObject = QuickAnd()
            lastCreatedQuickObject = astObject
            return true
        } else if currentType() == TokenType.OR {
            tokenIndex += 1
            let astObject = QuickOr()
            lastCreatedQuickObject = astObject
            return true
        }
        
        tokenIndex = backtrackIndex
        return false
        
    }
    
    func parseLogicalExpression() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickLogicalExpression()
        
        if currentType() == TokenType.EOF {
            return false
        } else if currentType() == TokenType.TRUE {
            
            let quickTrue = QuickTrue()
            
            tokenIndex += 1
            
            if parseLogicalOperator() {
                
                let logicalObject = lastCreatedQuickObject
                
                (logicalObject as? QuickEqual)?.parent = astObject
                (logicalObject as? QuickNotEqual)?.parent = astObject
                (logicalObject as? QuickLessThan)?.parent = astObject
                (logicalObject as? QuickGreaterThan)?.parent = astObject
                (logicalObject as? QuickGreaterThanOrEqualTo)?.parent = astObject
                (logicalObject as? QuickLessThanOrEqualTo)?.parent = astObject
                (logicalObject as? QuickAnd)?.parent = astObject
                (logicalObject as? QuickOr)?.parent = astObject
                
                quickTrue.parent = logicalObject
                (logicalObject as? QuickEqual)?.leftSide = quickTrue
                (logicalObject as? QuickNotEqual)?.leftSide = quickTrue
                (logicalObject as? QuickLessThan)?.leftSide = quickTrue
                (logicalObject as? QuickGreaterThan)?.leftSide = quickTrue
                (logicalObject as? QuickGreaterThanOrEqualTo)?.leftSide = quickTrue
                (logicalObject as? QuickLessThanOrEqualTo)?.leftSide = quickTrue
                (logicalObject as? QuickAnd)?.leftSide = quickTrue
                (logicalObject as? QuickOr)?.leftSide = quickTrue
                
                if parseValue() {
                    (lastCreatedQuickObject as? QuickValue)?.parent = logicalObject
                    (logicalObject as? QuickEqual)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickNotEqual)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickLessThan)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickGreaterThan)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickGreaterThanOrEqualTo)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickLessThanOrEqualTo)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickAnd)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickOr)?.rightSide = lastCreatedQuickObject
                    astObject.content = logicalObject
                    lastCreatedQuickObject = astObject
                    return true
                } else if currentType() == TokenType.TRUE {
                    tokenIndex += 1
                    let trueObj = QuickTrue()
                    trueObj.parent = logicalObject
                    (logicalObject as? QuickEqual)?.rightSide = trueObj
                    (logicalObject as? QuickNotEqual)?.rightSide = trueObj
                    (logicalObject as? QuickLessThan)?.rightSide = trueObj
                    (logicalObject as? QuickGreaterThan)?.rightSide = trueObj
                    (logicalObject as? QuickGreaterThanOrEqualTo)?.rightSide = trueObj
                    (logicalObject as? QuickLessThanOrEqualTo)?.rightSide = trueObj
                    (logicalObject as? QuickAnd)?.rightSide = trueObj
                    (logicalObject as? QuickOr)?.rightSide = trueObj
                    astObject.content = logicalObject
                    lastCreatedQuickObject = astObject
                    return true
                } else if currentType() == TokenType.FALSE {
                    tokenIndex += 1
                    let falseObj = QuickFalse()
                    falseObj.parent = logicalObject
                    (logicalObject as? QuickEqual)?.rightSide = falseObj
                    (logicalObject as? QuickNotEqual)?.rightSide = falseObj
                    (logicalObject as? QuickLessThan)?.rightSide = falseObj
                    (logicalObject as? QuickGreaterThan)?.rightSide = falseObj
                    (logicalObject as? QuickGreaterThanOrEqualTo)?.rightSide = falseObj
                    (logicalObject as? QuickLessThanOrEqualTo)?.rightSide = falseObj
                    (logicalObject as? QuickAnd)?.rightSide = falseObj
                    (logicalObject as? QuickOr)?.rightSide = falseObj
                    astObject.content = logicalObject
                    lastCreatedQuickObject = astObject
                    return true
                }else {
                    tokenIndex = backtrackIndex
                    return false
                }
            } else {
                quickTrue.parent = astObject
                astObject.content = quickTrue
                lastCreatedQuickObject = astObject
                return true // Just a bool is a valid logical expression
            }
            
            
        } else if currentType() == TokenType.FALSE {
            
            let quickFalse = QuickFalse()
            
            tokenIndex += 1
            
            if parseLogicalOperator() {
                
                let logicalObject = lastCreatedQuickObject
                
                (logicalObject as? QuickEqual)?.parent = astObject
                (logicalObject as? QuickNotEqual)?.parent = astObject
                (logicalObject as? QuickLessThan)?.parent = astObject
                (logicalObject as? QuickGreaterThan)?.parent = astObject
                (logicalObject as? QuickGreaterThanOrEqualTo)?.parent = astObject
                (logicalObject as? QuickLessThanOrEqualTo)?.parent = astObject
                (logicalObject as? QuickAnd)?.parent = astObject
                (logicalObject as? QuickOr)?.parent = astObject
                
                quickFalse.parent = logicalObject
                (logicalObject as? QuickEqual)?.leftSide = quickFalse
                (logicalObject as? QuickNotEqual)?.leftSide = quickFalse
                (logicalObject as? QuickLessThan)?.leftSide = quickFalse
                (logicalObject as? QuickGreaterThan)?.leftSide = quickFalse
                (logicalObject as? QuickGreaterThanOrEqualTo)?.leftSide = quickFalse
                (logicalObject as? QuickLessThanOrEqualTo)?.leftSide = quickFalse
                (logicalObject as? QuickAnd)?.leftSide = quickFalse
                (logicalObject as? QuickOr)?.leftSide = quickFalse
                
                if parseValue() {
                    (lastCreatedQuickObject as? QuickValue)?.parent = logicalObject
                    (logicalObject as? QuickEqual)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickNotEqual)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickLessThan)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickGreaterThan)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickGreaterThanOrEqualTo)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickLessThanOrEqualTo)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickAnd)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickOr)?.rightSide = lastCreatedQuickObject
                    astObject.content = logicalObject
                    lastCreatedQuickObject = astObject
                    return true
                } else if currentType() == TokenType.TRUE {
                    tokenIndex += 1
                    let trueObj = QuickTrue()
                    trueObj.parent = logicalObject
                    (logicalObject as? QuickEqual)?.rightSide = trueObj
                    (logicalObject as? QuickNotEqual)?.rightSide = trueObj
                    (logicalObject as? QuickLessThan)?.rightSide = trueObj
                    (logicalObject as? QuickGreaterThan)?.rightSide = trueObj
                    (logicalObject as? QuickGreaterThanOrEqualTo)?.rightSide = trueObj
                    (logicalObject as? QuickLessThanOrEqualTo)?.rightSide = trueObj
                    (logicalObject as? QuickAnd)?.rightSide = trueObj
                    (logicalObject as? QuickOr)?.rightSide = trueObj
                    astObject.content = logicalObject
                    lastCreatedQuickObject = astObject
                    return true
                } else if currentType() == TokenType.FALSE {
                    tokenIndex += 1
                    let falseObj = QuickFalse()
                    falseObj.parent = logicalObject
                    (logicalObject as? QuickEqual)?.rightSide = falseObj
                    (logicalObject as? QuickNotEqual)?.rightSide = falseObj
                    (logicalObject as? QuickLessThan)?.rightSide = falseObj
                    (logicalObject as? QuickGreaterThan)?.rightSide = falseObj
                    (logicalObject as? QuickGreaterThanOrEqualTo)?.rightSide = falseObj
                    (logicalObject as? QuickLessThanOrEqualTo)?.rightSide = falseObj
                    (logicalObject as? QuickAnd)?.rightSide = falseObj
                    (logicalObject as? QuickOr)?.rightSide = falseObj
                    astObject.content = logicalObject
                    lastCreatedQuickObject = astObject
                    return true
                }else {
                    tokenIndex = backtrackIndex
                    return false
                }
            } else {
                quickFalse.parent = astObject
                astObject.content = quickFalse
                lastCreatedQuickObject = astObject
                return true // Just a bool is a valid logical expression
            }
        } else if currentType() == TokenType.NOT {
            
            tokenIndex += 1
            let logicalObject = QuickNot()
            
            if parseValue() {
                logicalObject.rightSide = lastCreatedQuickObject as? QuickValue
                (logicalObject.rightSide as? QuickValue)?.parent = logicalObject
                astObject.content = logicalObject
                lastCreatedQuickObject = astObject
                return true
            } else if currentType() == TokenType.TRUE {
                logicalObject.rightSide = QuickTrue()
                (logicalObject.rightSide as? QuickTrue)?.parent = logicalObject
                astObject.content = logicalObject
                lastCreatedQuickObject = astObject
                tokenIndex += 1
                return true
            } else if currentType() == TokenType.FALSE {
                logicalObject.rightSide = QuickFalse()
                (logicalObject.rightSide as? QuickFalse)?.parent = logicalObject
                astObject.content = logicalObject
                lastCreatedQuickObject = astObject
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                return false
            }
            
        } else if parseValue() {
            
            let valueObject = lastCreatedQuickObject
            
            if parseLogicalOperator() {
                
                let logicalObject = lastCreatedQuickObject
                
                (logicalObject as? QuickEqual)?.parent = astObject
                (logicalObject as? QuickNotEqual)?.parent = astObject
                (logicalObject as? QuickLessThan)?.parent = astObject
                (logicalObject as? QuickGreaterThan)?.parent = astObject
                (logicalObject as? QuickGreaterThanOrEqualTo)?.parent = astObject
                (logicalObject as? QuickLessThanOrEqualTo)?.parent = astObject
                (logicalObject as? QuickAnd)?.parent = astObject
                (logicalObject as? QuickOr)?.parent = astObject
                
                (valueObject as? QuickValue)?.parent = logicalObject
                (logicalObject as? QuickEqual)?.leftSide = valueObject
                (logicalObject as? QuickNotEqual)?.leftSide = valueObject
                (logicalObject as? QuickLessThan)?.leftSide = valueObject
                (logicalObject as? QuickGreaterThan)?.leftSide = valueObject
                (logicalObject as? QuickGreaterThanOrEqualTo)?.leftSide = valueObject
                (logicalObject as? QuickLessThanOrEqualTo)?.leftSide = valueObject
                (logicalObject as? QuickAnd)?.leftSide = valueObject
                (logicalObject as? QuickOr)?.leftSide = valueObject
                
                if parseValue() {
                    (lastCreatedQuickObject as? QuickValue)?.parent = logicalObject
                    (logicalObject as? QuickEqual)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickNotEqual)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickLessThan)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickGreaterThan)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickGreaterThanOrEqualTo)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickLessThanOrEqualTo)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickAnd)?.rightSide = lastCreatedQuickObject
                    (logicalObject as? QuickOr)?.rightSide = lastCreatedQuickObject
                    astObject.content = logicalObject
                    lastCreatedQuickObject = astObject
                    return true
                } else if currentType() == TokenType.TRUE {
                    tokenIndex += 1
                    let trueObj = QuickTrue()
                    trueObj.parent = logicalObject
                    (logicalObject as? QuickEqual)?.rightSide = trueObj
                    (logicalObject as? QuickNotEqual)?.rightSide = trueObj
                    (logicalObject as? QuickLessThan)?.rightSide = trueObj
                    (logicalObject as? QuickGreaterThan)?.rightSide = trueObj
                    (logicalObject as? QuickGreaterThanOrEqualTo)?.rightSide = trueObj
                    (logicalObject as? QuickLessThanOrEqualTo)?.rightSide = trueObj
                    (logicalObject as? QuickAnd)?.rightSide = trueObj
                    (logicalObject as? QuickOr)?.rightSide = trueObj
                    astObject.content = logicalObject
                    lastCreatedQuickObject = astObject
                    return true
                } else if currentType() == TokenType.FALSE {
                    tokenIndex += 1
                    let falseObj = QuickFalse()
                    falseObj.parent = logicalObject
                    (logicalObject as? QuickEqual)?.rightSide = falseObj
                    (logicalObject as? QuickNotEqual)?.rightSide = falseObj
                    (logicalObject as? QuickLessThan)?.rightSide = falseObj
                    (logicalObject as? QuickGreaterThan)?.rightSide = falseObj
                    (logicalObject as? QuickGreaterThanOrEqualTo)?.rightSide = falseObj
                    (logicalObject as? QuickLessThanOrEqualTo)?.rightSide = falseObj
                    (logicalObject as? QuickAnd)?.rightSide = falseObj
                    (logicalObject as? QuickOr)?.rightSide = falseObj
                    astObject.content = logicalObject
                    lastCreatedQuickObject = astObject
                    return true
                } else {
                    tokenIndex = backtrackIndex
                    return false
                }
            } else {
                (valueObject as? QuickValue)?.parent = astObject
                astObject.content = valueObject
                lastCreatedQuickObject = astObject
                return true // Just a bool is a valid logical expression
            }
            
        }
        
        tokenIndex = backtrackIndex
        return false
        
    }
    
    func parseForLoop() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickForLoop()
        
        if currentType() == TokenType.FOR {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if parseIdentifier() {
            astObject.identifier = lastCreatedQuickObject as! QuickIdentifier
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if currentType() == TokenType.CAST {
        
            tokenIndex += 1
            
            // We're casting, so the next token has to be the type that we're casting to
            if currentType() == TokenType.INTEGERTYPE {
                tokenIndex += 1
                astObject.castingType = "Integer"
            }
            
            if currentType() == TokenType.FLOATTYPE {
                tokenIndex += 1
                astObject.castingType = "Float"
            }
            
            if currentType() == TokenType.BOOLEANTYPE {
                tokenIndex += 1
                astObject.castingType = "Boolean"
            }
            
            if currentType() == TokenType.STRINGTYPE {
                tokenIndex += 1
                astObject.castingType = "String"
            }
            
            if currentType() == TokenType.ARRAYTYPE {
                tokenIndex += 1
                astObject.castingType = "Array"
            }

            if currentType() == TokenType.IMAGETYPE {
                tokenIndex += 1
                astObject.castingType = "Image"
            }

            if currentType() == TokenType.DICTIONARYTYPE {
                tokenIndex += 1
                astObject.castingType = "Dictionary"
            }

            if currentType() == TokenType.COLORTYPE {
                tokenIndex += 1
                astObject.castingType = "Color"
            }
}
//
        
        if currentType() == TokenType.IN {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if !parseValue() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.array = lastCreatedQuickObject as? QuickValue
        
        if currentType() == TokenType.OPENBRACE {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if !parseMultilineStatement() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.executionBlock = lastCreatedQuickObject as? QuickMultilineStatement
        
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseWhileLoop() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickWhileLoop()
        
        if currentType() == TokenType.WHILE {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if !parseLogicalExpression() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.expression = lastCreatedQuickObject as? QuickLogicalExpression
        
        if currentType() == TokenType.OPENBRACE {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if !parseMultilineStatement() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.executionBlock = lastCreatedQuickObject as? QuickMultilineStatement
        
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseIfStatement() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickIfStatement()
        
        if currentType() == TokenType.IF {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if !parseLogicalExpression() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.expression = lastCreatedQuickObject as? QuickLogicalExpression
        
        if currentType() == TokenType.OPENBRACE {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if !parseMultilineStatement() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.executionBlock = lastCreatedQuickObject as? QuickMultilineStatement
        
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseAssignment() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickAssignment()
        
        if !parseProperty() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.leftSide = lastCreatedQuickObject as? QuickProperty
        
        if currentType() == TokenType.ASSIGNMENT {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if !parseValue() && !parseLogicalExpression() {
            tokenIndex = backtrackIndex
            return false
        }
        if lastCreatedQuickObject as? QuickLogicalExpression != nil {
            astObject.rightSide = lastCreatedQuickObject as? QuickLogicalExpression
        }
        if lastCreatedQuickObject as? QuickValue != nil {
            astObject.rightSide = lastCreatedQuickObject as? QuickValue
        }
        
        if currentType() != TokenType.CAST {
            lastCreatedQuickObject = astObject
            return true
        }
        
        tokenIndex += 1
        
        // We're casting, so the next token has to be the type that we're casting to
        if currentType() == TokenType.INTEGERTYPE {
            tokenIndex += 1
            astObject.castingType = "Integer"
            lastCreatedQuickObject = astObject
            return true
        }

        if currentType() == TokenType.FLOATTYPE {
            tokenIndex += 1
            astObject.castingType = "Float"
            lastCreatedQuickObject = astObject
            return true
        }

        if currentType() == TokenType.BOOLEANTYPE {
            tokenIndex += 1
            astObject.castingType = "Boolean"
            lastCreatedQuickObject = astObject
            return true
        }
        
        if currentType() == TokenType.STRINGTYPE {
            tokenIndex += 1
             astObject.castingType = "String"
            lastCreatedQuickObject = astObject
            return true
        }

        if currentType() == TokenType.ARRAYTYPE {
            tokenIndex += 1
            astObject.castingType = "Array"
            lastCreatedQuickObject = astObject
            return true
        }

        if currentType() == TokenType.IMAGETYPE {
            tokenIndex += 1
            astObject.castingType = "Image"
            lastCreatedQuickObject = astObject
            return true
        }

        if currentType() == TokenType.DICTIONARYTYPE {
            tokenIndex += 1
            astObject.castingType = "Dictionary"
            lastCreatedQuickObject = astObject
            return true
        }

        if currentType() == TokenType.COLORTYPE {
            tokenIndex += 1
            astObject.castingType = "Color"
            lastCreatedQuickObject = astObject
            return true
        }

        return false
        
    }
    
    func parseProperty() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickProperty()
        
        if !parseIdentifier() {
            tokenIndex = backtrackIndex
            return false
        }
        
        let identifierObject = lastCreatedQuickObject as! QuickIdentifier
        astObject.content.append(identifierObject)
                
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseMethodCall() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickMethodCall()
        
        if currentType() == TokenType.METHODNAME {
            astObject.methodName = currentToken().tokenString
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if currentType() == TokenType.OPENARGUMENTS {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if currentType() == TokenType.CLOSEARGUMENTS {
            tokenIndex += 1
            lastCreatedQuickObject = astObject
            return true
        } else {
            
            if !parseParameters() {
                tokenIndex = backtrackIndex
                return false
            }
            astObject.parameters = lastCreatedQuickObject as? QuickParameters
            
            if currentType() == TokenType.CLOSEARGUMENTS {
                tokenIndex += 1
                lastCreatedQuickObject = astObject
                return true
            } else {
                tokenIndex = backtrackIndex
                return false
            }
            
        }
        
        return false
        
    }
    
    func parseParameters() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickParameters()
        
        if !parseValue() && !parseLogicalExpression() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.parameters.append(lastCreatedQuickObject!)
        
        if currentType() == TokenType.ARGUMENTSEPERATOR {
            tokenIndex += 1
            if parseParameters() {
                let recursiveObject = lastCreatedQuickObject as? QuickParameters
                if recursiveObject != nil {
                    for parameter in recursiveObject!.parameters {
                        astObject.parameters.append(parameter)
                    }
                }
            }
        }
        
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseArray() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickArray()
        
        if currentType() == TokenType.STARTARRAY {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if currentType() == TokenType.ENDARRAY {
            tokenIndex += 1
            lastCreatedQuickObject = astObject
            
            if currentType() == TokenType.STARTARRAY {
                tokenIndex += 1
            } else {
                return true // No subscript, we're done here
            }
            
            if !parseValue() {
                tokenIndex = backtrackIndex
                return false
            }
            astObject.subscriptValue = lastCreatedQuickObject as? QuickValue
            
            if currentType() != TokenType.ENDARRAY {
                tokenIndex = backtrackIndex
                return false
            }
            tokenIndex += 1
            
            return true
        } else {
            
            if !parseParameters() {
                tokenIndex = backtrackIndex
                return false
            }
            astObject.parameters = lastCreatedQuickObject as? QuickParameters
            
            if currentType() == TokenType.ENDARRAY {
                tokenIndex += 1
            } else {
                tokenIndex = backtrackIndex
                return false
            }
            
            if currentType() == TokenType.STARTARRAY {
                tokenIndex += 1
            } else {
                lastCreatedQuickObject = astObject
                return true // No subscript, we're done here
            }
            
            if !parseValue() {
                tokenIndex = backtrackIndex
                return false
            }
            astObject.subscriptValue = lastCreatedQuickObject as? QuickValue
            
            
            if currentType() != TokenType.ENDARRAY {
                tokenIndex = backtrackIndex
                return false
            }
            tokenIndex += 1
            
            lastCreatedQuickObject = astObject
            return true
            
        }
        
        tokenIndex = backtrackIndex
        return false
        
    }

    func parseDictionary() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickDictionary()
        
        if currentType() == TokenType.OPENBRACE {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if currentType() == TokenType.CLOSEBRACE {
            tokenIndex += 1
            lastCreatedQuickObject = astObject
            return true
        } else {
            
            while currentType() != TokenType.CLOSEBRACE {
                
                if !parseValue() {
                    tokenIndex = backtrackIndex
                    return false
                }
                
                let keyValue = lastCreatedQuickObject as! QuickValue
                
                if currentType() != TokenType.KEYVALUESEPERATOR {
                    tokenIndex = backtrackIndex
                    return false
                }
                tokenIndex += 1

                if !parseValue() {
                    tokenIndex = backtrackIndex
                    return false
                }
                
                let valueValue = lastCreatedQuickObject as! QuickValue

                let astKeyValuePair = QuickKeyValuePair()
                astKeyValuePair.parent = astObject
                astKeyValuePair.key = keyValue
                astKeyValuePair.value = valueValue
                astObject.content.append(astKeyValuePair)
                
                if currentType() == TokenType.ARGUMENTSEPERATOR {
                    tokenIndex += 1
                }

            }
            
            if currentType() == TokenType.CLOSEBRACE {
                tokenIndex += 1
            } else {
                tokenIndex = backtrackIndex
                return false
            }
            
            if currentType() == TokenType.STARTARRAY {
                tokenIndex += 1
            } else {
                lastCreatedQuickObject = astObject
                return true // No subscript, we're done here
            }
            
            if !parseValue() {
                tokenIndex = backtrackIndex
                return false
            }
            astObject.subscriptValue = lastCreatedQuickObject as? QuickValue
            
            
            if currentType() != TokenType.ENDARRAY {
                tokenIndex = backtrackIndex
                return false
            }
            tokenIndex += 1
            
            lastCreatedQuickObject = astObject
            return true
            
        }
        
        tokenIndex = backtrackIndex
        return false
        
    }

    func parseReturnStatement() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickReturnStatement()
        
        if currentType() == TokenType.RETURN {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }

        if !parseValue() {
            tokenIndex = backtrackIndex
            return false
        }
        astObject.content = lastCreatedQuickObject as! QuickValue
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseColor() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickColor()
        
        if currentType() == TokenType.COLOR {
            let colorString = currentToken().tokenString
            if colorString.count != 9 && colorString.count != 7 {
                return false
            }
            let color = colorString.hexColor
            
            astObject.content = color
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
                
        lastCreatedQuickObject = astObject
        return true
        
    }


}

// Thanks to https://gist.github.com/arshad/de147c42d7b3063ef7bc#gistcomment-1851050
extension String {
    var hexColor: UIColor {
        let hex = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return .clear
        }
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}
