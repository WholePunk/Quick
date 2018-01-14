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
    
    func currentToken() -> Token {
        return tokens[tokenIndex]
    }
    
    func currentType() -> TokenType {
        return tokens[tokenIndex].tokenType
    }
    
    func nextType() -> TokenType {
        return tokens[tokenIndex + 1].tokenType
    }
    
    func parse(fromSource: String) -> Bool {
        
        QuickSymbolTable.sharedRoot = symbolTable
        Output.shared.string = ""
        self.tokens = Tokenizer().tokens(fromSource: fromSource)
        
        lastCreatedQuickObject = root
        
        // We expect that a program should be composed of newlines and statements, until it hits an EOF, then we're done.
        while currentType() != TokenType.EOF && errorAt == -1 {
            
            if currentType() == TokenType.NEWLINE {
                tokenIndex += 1
            } else {
                if !parseStatement() {
                    errorAt = tokenIndex
                    return false
                }
                root.addStatement(lastCreatedQuickObject as! QuickStatement)
            }
            
        }
        
        root.checkSymbols(symbolTable: symbolTable)
        
        return true
        
    }
    
    func parseMultilineStatement() -> Bool {
        
        let backtrackIndex = tokenIndex
        var astObject = QuickMultilineStatement()
        
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
            let recursiveObject = lastCreatedQuickObject as! QuickMultilineStatement
            for statement in recursiveObject.content {
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
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                return false
            }
        } else if parseForLoop() {
            if currentType() == TokenType.NEWLINE {
                astObject.content = lastCreatedQuickObject as? QuickForLoop
                lastCreatedQuickObject = astObject
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                return false
            }
        } else if parseWhileLoop() {
            if currentType() == TokenType.NEWLINE {
                astObject.content = lastCreatedQuickObject as? QuickWhileLoop
                lastCreatedQuickObject = astObject
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                return false
            }
        } else if parseIfStatement() {
            if currentType() == TokenType.NEWLINE {
                astObject.content = lastCreatedQuickObject as? QuickIfStatement
                lastCreatedQuickObject = astObject
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                return false
            }
        } else if parseMethodCall() {
            if currentType() == TokenType.NEWLINE {
                astObject.parent?.addStatement(astObject)
                tokenIndex += 1
                return true
            } else {
                tokenIndex = backtrackIndex
                return false
            }
        } else {
            tokenIndex = backtrackIndex
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
        } else if currentType() == TokenType.IDENTIFIER {
            let identifierObject = QuickIdentifier()
            identifierObject.parent = astObject
            identifierObject.content = currentToken().tokenString
            astObject.content = identifierObject
            lastCreatedQuickObject = astObject
            tokenIndex += 1
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
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
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
            
        } else if currentType() == TokenType.IDENTIFIER {
            let quickIdentifier = QuickIdentifier()
            quickIdentifier.content = currentToken().tokenString
            quickIdentifier.parent = astObject
            astObject.content = quickIdentifier
            tokenIndex += 1
            
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
        var astObject = QuickForLoop()
        
        if currentType() == TokenType.FOR {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if currentType() == TokenType.IDENTIFIER {
            let identifierObject = QuickIdentifier()
            identifierObject.content = currentToken().tokenString
            identifierObject.parent = astObject
            astObject.identifier = identifierObject
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
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
        astObject.array = lastCreatedQuickObject as? QuickArray
        
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
        var astObject = QuickIfStatement()
        
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
        
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseProperty() -> Bool {
        
        let backtrackIndex = tokenIndex
        let astObject = QuickProperty()
        
        if currentType() != TokenType.IDENTIFIER {
            tokenIndex = backtrackIndex
            return false
        }
        
        let identifierObject = QuickIdentifier()
        identifierObject.content = currentToken().tokenString
        identifierObject.parent = astObject
        astObject.content.append(identifierObject)
        
        tokenIndex += 1
        if currentType() == TokenType.DOT {
            tokenIndex += 1
            if parseProperty() {
                let recursiveObject = lastCreatedQuickObject as? QuickProperty
                if recursiveObject != nil {
                    for identifier in recursiveObject!.content {
                        astObject.content.append(identifier)
                    }
                }
            }
        }
        
        lastCreatedQuickObject = astObject
        return true
        
    }
    
    func parseMethodCall() -> Bool {
        
        let backtrackIndex = tokenIndex
        var astObject = QuickMethodCall()
        
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
        var astObject = QuickParameters()
        
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
        var astObject = QuickArray()
        
        if currentType() == TokenType.STARTARRAY {
            tokenIndex += 1
        } else {
            tokenIndex = backtrackIndex
            return false
        }
        
        if currentType() == TokenType.ENDARRAY {
            tokenIndex += 1
            lastCreatedQuickObject = astObject
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
            
            lastCreatedQuickObject = astObject
            return true
            
        }
        
        tokenIndex = backtrackIndex
        return false
        
    }
    
}

