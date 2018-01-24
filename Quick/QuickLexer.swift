//
//  QuickLexer.swift
//  Quick
//
//  Created by Bob Warwick on 2018-01-10.
//  Copyright © 2018 Whole Punk Creators Ltd. All rights reserved.
//

import Foundation

/***************/
/* QUICK LEXER */
/***************/

class Token {
    var tokenType : TokenType = TokenType.NONE
    var tokenString : String = ""
}

enum TokenType {
    case NONE
    case IDENTIFIER
    case ASSIGNMENT
    case STRING
    case INTEGER
    case FLOAT
    case OPENBRACE
    case CLOSEBRACE
    case FOR
    case IN
    case WHILE
    case IF
    case PLUS
    case MINUS
    case MULTIPLY
    case DIVIDE
    case MOD
    case METHODNAME
    case OPENARGUMENTS
    case CLOSEARGUMENTS
    case ARGUMENTSEPERATOR
    case KEYVALUESEPERATOR
    case NEWLINE
    case TRUE
    case FALSE
    case AND
    case OR
    case NOT
    case EQUALS
    case DOESNOTEQUAL
    case SMALLERTHAN
    case SMALLERTHANOREQUAL
    case LARGERTHAN
    case LARGERTHANOREQUAL
    case STARTARRAY
    case ENDARRAY
    case CAST
    case INTEGERTYPE
    case FLOATTYPE
    case BOOLEANTYPE
    case STRINGTYPE
    case DICTIONARYTYPE
    case ARRAYTYPE
    case IMAGETYPE
    case COLORTYPE
    case COLOR
    case RETURN
    case EOF
    case ERROR
}

class Tokenizer {
    
    // Tokens in Quick are whitespace separated, except for some special casing in methods
    // Named tokens (for, while, etc) are exact matches
    // Numbers are composed entirely of digits
    // Identifiers are composed of digits, underscores, and letters.  Identifiers may not start with a digit.
    // Strings are composed of arbitrary non-double-quote characters, surrounded by double quotes
    // Method signatures looks like this someMethodName(expression, expression)
    // Arrays are collections of numbers, strings, and identifiers between [ and ]
    
    var currentTokenString = ""
    var currentToken = TokenType.NONE
    var inString = false
    var inSubscript = true
    var tokens : Array<Token> = []
    var currentLine = 0
    
    func commitToken() {

        if currentToken == TokenType.STRING {
            // Remove the first and last characters, as they're extraneous quotes
            currentTokenString = currentTokenString.substring(from: currentTokenString.characters.index(currentTokenString.startIndex, offsetBy: 1))
            currentTokenString = currentTokenString.substring(to: currentTokenString.characters.index(currentTokenString.endIndex, offsetBy: -1))
        }
        
        let token = Token()
        token.tokenType = currentToken
        token.tokenString = currentTokenString
        tokens.append(token)
        
        if currentToken == .NEWLINE {
            currentLine += 1
        }
        
        if currentToken == .ERROR {
            QuickError.shared.setErrorMessage("Invalid token \"\(currentTokenString)\"", withLine: currentLine)
        }

        currentTokenString = ""
        currentToken = TokenType.NONE
        inString = false
        
    }
    
    func popLastCharacter() {
        currentTokenString = String(currentTokenString.characters.dropLast())
    }
    
    func tokens(fromSource: String) -> Array<Token> {
        
        self.tokens = []
        
        // Add a newline at the end of the source.  Let's us then assume that all tokens end with whitespace
        var fromSource = fromSource
        fromSource.append("\n")
        
        for character in fromSource.utf16 {
            let asCharacter = Character(UnicodeScalar(character)!)
            if (CharacterSet.whitespacesAndNewlines as NSCharacterSet).characterIsMember(character) && !inString {
                
                if currentToken != TokenType.NONE {
                    commitToken()
                }
                
                if asCharacter == "\n" {
                    currentToken = TokenType.NEWLINE
                    currentTokenString = "\n"
                    commitToken()
                }
                
            } else {
                currentTokenString.append(asCharacter)
                
                if currentToken == TokenType.NONE {
                    if (CharacterSet.letters as NSCharacterSet).characterIsMember(character) {
                        currentToken = TokenType.IDENTIFIER
                    } else if asCharacter == "=" {
                        currentToken = TokenType.ASSIGNMENT
                    } else if asCharacter == "\"" {
                        currentToken = TokenType.STRING
                        inString = true
                    } else if (CharacterSet.decimalDigits as NSCharacterSet).characterIsMember(character) {
                        currentToken = TokenType.INTEGER
                    } else if asCharacter == "{" {
                        currentToken = TokenType.OPENBRACE
                    } else if asCharacter == "}" {
                        currentToken = TokenType.CLOSEBRACE
                    } else if asCharacter == "+" {
                        currentToken = TokenType.PLUS
                    } else if asCharacter == "-" {
                        currentToken = TokenType.MINUS
                    } else if asCharacter == "/" {
                        currentToken = TokenType.DIVIDE
                    } else if asCharacter == "*" {
                        currentToken = TokenType.MULTIPLY
                    } else if asCharacter == "%" {
                        currentToken = TokenType.MOD
                    } else if asCharacter == "!" {
                        currentToken = TokenType.NOT
                    } else if asCharacter == ">" {
                        currentToken = TokenType.LARGERTHAN
                    } else if asCharacter == "<" {
                        currentToken = TokenType.SMALLERTHAN
                    } else if asCharacter == "[" {
                        currentToken = TokenType.STARTARRAY
                        commitToken()
                    } else if asCharacter == "]" {
                        currentToken = TokenType.ENDARRAY
                        commitToken()
                    } else if asCharacter == "(" {
                        currentToken = TokenType.OPENARGUMENTS
                        commitToken()
                    } else if asCharacter == ")" {
                        currentToken = TokenType.CLOSEARGUMENTS
                        commitToken()
                    } else if asCharacter == "," {
                        currentToken = TokenType.ARGUMENTSEPERATOR
                        commitToken()
                    } else if asCharacter == ":" {
                        currentToken = TokenType.KEYVALUESEPERATOR
                        commitToken()
                    } else if asCharacter == "#" {
                        currentToken = TokenType.COLOR
                    } else {
                        currentToken = TokenType.ERROR
                    }
                    continue
                }
                
                if currentToken == TokenType.IDENTIFIER {
                    if (CharacterSet.alphanumerics as NSCharacterSet).characterIsMember(character) || asCharacter == "." {
                        currentToken = TokenType.IDENTIFIER
                    } else if asCharacter == "_" {
                        currentToken = TokenType.IDENTIFIER
                    } else if asCharacter == "(" {
                        currentToken = TokenType.METHODNAME
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.OPENARGUMENTS
                        commitToken()
                    } else if asCharacter == ")" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.CLOSEARGUMENTS
                        commitToken()
                    } else if asCharacter == "," {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.ARGUMENTSEPERATOR
                        commitToken()
                    } else if asCharacter == ":" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.KEYVALUESEPERATOR
                        commitToken()
                    } else if asCharacter == "[" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.STARTARRAY
                        commitToken()
                    } else if asCharacter == "]" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.ENDARRAY
                        commitToken()
                    } else if asCharacter == "}" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.CLOSEBRACE
                        commitToken()
                    } else {
                        currentToken = TokenType.ERROR
                    }
                    
                    if currentTokenString == "for" {
                        currentToken = TokenType.FOR
                    }
                    
                    if currentTokenString == "in" {
                        currentToken = TokenType.IN
                    }
                    
                    if currentTokenString == "while" {
                        currentToken = TokenType.WHILE
                    }
                    
                    if currentTokenString == "if" {
                        currentToken = TokenType.IF
                    }
                    
                    if currentTokenString == "true" {
                        currentToken = TokenType.TRUE
                    }
                    
                    if currentTokenString == "false" {
                        currentToken = TokenType.FALSE
                    }
                    
                    if currentTokenString == "and" {
                        currentToken = TokenType.AND
                    }
                    
                    if currentTokenString == "or" {
                        currentToken = TokenType.OR
                    }

                    if currentTokenString == "as" {
                        currentToken = TokenType.CAST
                    }

                    if currentTokenString == "Dictionary" {
                        currentToken = TokenType.DICTIONARYTYPE
                    }

                    if currentTokenString == "Array" {
                        currentToken = TokenType.ARRAYTYPE
                    }

                    if currentTokenString == "Image" {
                        currentToken = TokenType.IMAGETYPE
                    }

                    if currentTokenString == "String" {
                        currentToken = TokenType.STRINGTYPE
                    }

                    if currentTokenString == "Boolean" {
                        currentToken = TokenType.BOOLEANTYPE
                    }

                    if currentTokenString == "Float" {
                        currentToken = TokenType.FLOATTYPE
                    }

                    if currentTokenString == "Integer" {
                        currentToken = TokenType.INTEGERTYPE
                    }

                    if currentTokenString == "return" {
                        currentToken = TokenType.RETURN
                    }

                    continue
                }
                
                if currentToken == TokenType.ASSIGNMENT {
                    if asCharacter == "=" {
                        currentToken = TokenType.EQUALS
                    } else {
                        currentToken = TokenType.ERROR // Assignments can't have any other second characters
                    }
                    continue
                }
                
                if currentToken == TokenType.EQUALS {
                    currentToken = TokenType.ERROR
                    continue
                }

                if currentToken == TokenType.COLOR {
                    if ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "A", "B", "C", "D", "E", "F", "a", "b", "c", "d", "e", "f"].contains(asCharacter) {
                        currentToken = TokenType.COLOR
                    } else {
                        currentToken = TokenType.ERROR
                    }
                    continue
                }

                if currentToken == TokenType.LARGERTHAN {
                    if asCharacter == "=" {
                        currentToken = TokenType.LARGERTHANOREQUAL
                    } else {
                        currentToken = TokenType.ERROR // Largerthan can't have any other second characters
                    }
                    continue
                }
                
                if currentToken == TokenType.LARGERTHANOREQUAL {
                    currentToken = TokenType.ERROR // No more characters
                    continue
                }
                
                if currentToken == TokenType.SMALLERTHAN {
                    if asCharacter == "=" {
                        currentToken = TokenType.SMALLERTHANOREQUAL
                    } else {
                        currentToken = TokenType.ERROR // Smallerthan can't have any other second characters
                    }
                    continue
                }
                
                if currentToken == TokenType.SMALLERTHANOREQUAL {
                    currentToken = TokenType.ERROR // No more characters
                    continue
                }
                
                if currentToken == TokenType.STRING {
                    // Throw an error if we don't close the quotes
                    if inString == false {
                        if asCharacter == ")" {
                            popLastCharacter()
                            commitToken()
                            currentToken = TokenType.CLOSEARGUMENTS
                            commitToken()
                        } else if asCharacter == "]" {
                            popLastCharacter()
                            commitToken()
                            currentToken = TokenType.ENDARRAY
                            commitToken()
                        } else if asCharacter == "}" {
                            popLastCharacter()
                            commitToken()
                            currentToken = TokenType.CLOSEBRACE
                            commitToken()
                        } else if asCharacter == ":" {
                            popLastCharacter()
                            commitToken()
                            currentToken = TokenType.KEYVALUESEPERATOR
                            commitToken()
                        } else if asCharacter == "," {
                            popLastCharacter()
                            commitToken()
                            currentToken = TokenType.ARGUMENTSEPERATOR
                            commitToken()
                        } else {
                            currentToken = TokenType.ERROR
                        }
                    }
                    if asCharacter == "\"" {
                        inString = false
                    }
                    continue
                }
                
                if currentToken == TokenType.INTEGER {
                    if (CharacterSet.decimalDigits as NSCharacterSet).characterIsMember(character) {
                        currentToken = TokenType.INTEGER
                    } else if asCharacter == "." {
                        currentToken = TokenType.FLOAT
                    } else if asCharacter == ")" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.CLOSEARGUMENTS
                        commitToken()
                    } else if asCharacter == "}" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.CLOSEBRACE
                        commitToken()
                    } else if asCharacter == "]" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.ENDARRAY
                        commitToken()
                    } else if asCharacter == "," {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.ARGUMENTSEPERATOR
                        commitToken()
                    } else {
                        currentToken = TokenType.ERROR
                    }
                    continue
                }
                
                if currentToken == TokenType.FLOAT {
                    if (CharacterSet.decimalDigits as NSCharacterSet).characterIsMember(character) {
                        currentToken = TokenType.FLOAT
                    } else if asCharacter == ")" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.CLOSEARGUMENTS
                        commitToken()
                    } else if asCharacter == "}" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.CLOSEBRACE
                        commitToken()
                    } else if asCharacter == "]" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.ENDARRAY
                        commitToken()
                    } else if asCharacter == "," {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.ARGUMENTSEPERATOR
                        commitToken()
                    } else {
                        currentToken = TokenType.ERROR
                    }
                    continue
                }
                
                if currentToken == TokenType.OPENBRACE {
                    if asCharacter == "\"" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.STRING
                        currentTokenString = "\(asCharacter)"
                        inString = true
                    } else if (CharacterSet.alphanumerics as NSCharacterSet).characterIsMember(character) {
                        commitToken()
                        currentToken = TokenType.IDENTIFIER
                        currentTokenString = "\(asCharacter)"
                    } else {
                        currentToken = TokenType.ERROR
                    }
                    continue
                }
                
                if currentToken == TokenType.CLOSEBRACE {
                    currentToken = TokenType.ERROR // Close Braces can't have a second character
                    continue
                }
                
                if currentToken == TokenType.PLUS {
                    currentToken = TokenType.ERROR // Plus can't have a second character
                    continue
                }
                
                if currentToken == TokenType.MINUS {
                    currentToken = TokenType.ERROR // Minus can't have a second character
                    continue
                }
                
                if currentToken == TokenType.MULTIPLY {
                    currentToken = TokenType.ERROR // Multiply can't have a second character
                    continue
                }
                
                if currentToken == TokenType.DIVIDE {
                    currentToken = TokenType.ERROR // Divide can't have a second character
                    continue
                }
                
                if currentToken == TokenType.MOD {
                    currentToken = TokenType.ERROR // Modulus can't have a second character
                    continue
                }
                
                if currentToken == TokenType.NOT {
                    if asCharacter == "=" {
                        currentToken = TokenType.DOESNOTEQUAL
                        continue
                    } else if (CharacterSet.alphanumerics as NSCharacterSet).characterIsMember(character) || asCharacter == "_" {
                        commitToken()
                        currentToken = TokenType.IDENTIFIER
                        currentTokenString = "\(asCharacter)"
                    } else {
                        currentToken = TokenType.ERROR
                    }
                }
                
                if currentToken == TokenType.DOESNOTEQUAL {
                    currentToken = TokenType.ERROR // We can't add more characters to a does not equal
                    continue
                }
                
                if currentToken == TokenType.FOR || currentToken == TokenType.IN || currentToken == TokenType.WHILE || currentToken == TokenType.IF || currentToken == TokenType.AND || currentToken == TokenType.OR || currentToken == TokenType.TRUE || currentToken == TokenType.FALSE || currentToken == TokenType.NOT {
                    if (CharacterSet.alphanumerics as NSCharacterSet).characterIsMember(character) {
                        currentToken = TokenType.IDENTIFIER
                    } else if asCharacter == "_" {
                        currentToken = TokenType.IDENTIFIER
                    } else if asCharacter == ")" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.CLOSEARGUMENTS
                        commitToken()
                    } else if asCharacter == "}" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.CLOSEBRACE
                        commitToken()
                    } else if asCharacter == "]" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.ENDARRAY
                        commitToken()
                    } else if asCharacter == "," {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.ARGUMENTSEPERATOR
                        commitToken()
                    } else if asCharacter == ":" {
                        popLastCharacter()
                        commitToken()
                        currentToken = TokenType.KEYVALUESEPERATOR
                        commitToken()
                    } else {
                        currentToken = TokenType.ERROR
                    }
                    continue
                }
                
            }
        }
        
        currentToken = TokenType.EOF
        commitToken()
        
        return tokens
        
    }
    
}

