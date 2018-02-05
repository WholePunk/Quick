//
//  QuickSymbolTable.swift
//  Quick
//
//  Created by Bob Warwick on 2018-01-10.
//  Copyright © 2018 Whole Punk Creators Ltd. All rights reserved.
//

class QuickSymbolTable {
    
//    static var sharedRoot : QuickSymbolTable?
    var symbols : Dictionary<String, String> = [:] // Keys are symbol identifiers, objects are symbol types
    private var parent : QuickSymbolTable?
    private var child : QuickSymbolTable?
    static var externalSymbols : Dictionary<String, ModelRenderer> = [:]
    static var roots = Dictionary<String, QuickSymbolTable>()

    static func rootSymbolTableForParser(_ parser: Parser) -> QuickSymbolTable	 {
        
        if QuickSymbolTable.roots[parser.uuid] == nil {
            QuickSymbolTable.roots[parser.uuid] = QuickSymbolTable()
        }
        
        return QuickSymbolTable.roots[parser.uuid]!
        
    }
    
    func pushScope() {
        
        var smallestScope = self
        while smallestScope.child != nil {
            smallestScope = smallestScope.child!
        }
        
        smallestScope.child = QuickSymbolTable()
        smallestScope.child?.parent = smallestScope
        
    }
    
    func popScope() {
        
        var smallestScope = self
        while smallestScope.child != nil {
            smallestScope = smallestScope.child!
        }

        smallestScope.parent?.child = nil
        
    }
    
    func addSymbol(_ identifier: String, ofType: String) {
        
        guard self.symbols[identifier] == nil else {
            return
        }
        
        if child != nil {
            child?.addSymbol(identifier, ofType: ofType)
            return
        }
        
        self.symbols[identifier] = ofType
        
    }
    
    func expectSymbol(_ identifier : String) {
        
        if self.symbols[identifier] != nil {
            return
        }
        
        if child != nil {
            child?.expectSymbol(identifier)
            return
        }
        
        QuickError.shared.setErrorMessage("Symbol \"\(identifier)\" used before it was declared", withLine: -2)
        
    }

    func checkType(_ type : String, ofIdentifier : String) {
        
        if self.symbols[ofIdentifier] != nil {
            if self.symbols[ofIdentifier] == type {
                return
            }
            if self.symbols[ofIdentifier] == "" {
                self.symbols[ofIdentifier] = type
                return
            }
            QuickError.shared.setErrorMessage("Type \(type) for \(ofIdentifier) does not match existing type of \(self.symbols[ofIdentifier]!)", withLine: -2)
            return
        }
        
        if child != nil {
            child?.checkType(type, ofIdentifier: ofIdentifier)
            return
        } else {
            QuickError.shared.setErrorMessage("No identifier \(ofIdentifier) in symbol table during type checking", withLine: -2)
        }
        
    }
    
    func checkArguments(_ args : QuickParameters?, types: Array<String>, methodName: String) {
        
        if args == nil && types.count == 0 {
            return // No arguments to check
        }
        
        guard args != nil else {
            QuickError.shared.setErrorMessage("Expected \(types.count) arguments when calling \(methodName), found none", withLine: -2)
            return
        }
        
        guard args!.parameters.count == types.count else {
            QuickError.shared.setErrorMessage("Expected \(types.count) arguments when calling \(methodName), found \(args!.parameters.count)", withLine: -2)
            return
        }
        
        var index = 0
        for arg in args!.parameters {
            if arg.getType() != types[index] && types[index] != "Any" {
                QuickError.shared.setErrorMessage("Expected \(types[index]) in \(methodName) arguments, found \(arg.getType())", withLine: -2)
            }
            index = index + 1
        }
    }

    func getType(ofIdentifier : String) -> String {
        
        if self.symbols[ofIdentifier] != nil {
            return self.symbols[ofIdentifier]!
        }
        
        if child != nil {
            return child!.getType(ofIdentifier: ofIdentifier)
        }

        return "Unknown Type"
        
    }

    func printSymbolTable() {
        
        print(self.symbols)
        child?.printSymbolTable()
        
    }
    
}
