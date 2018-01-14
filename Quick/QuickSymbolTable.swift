//
//  QuickSymbolTable.swift
//  Quick
//
//  Created by Bob Warwick on 2018-01-10.
//  Copyright © 2018 Whole Punk Creators Ltd. All rights reserved.
//

class QuickSymbolTable {
    
    static var sharedRoot : QuickSymbolTable?
    private var symbols : Dictionary<String, String> = [:] // Keys are symbol identifiers, objects are symbol types
    private var parent : QuickSymbolTable?
    private var child : QuickSymbolTable?

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
        
        print("ERROR: Symbol \"\(identifier)\" used before it was declared")
        
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
            print("ERROR: type \(type) for \(ofIdentifier) does not match existing type of \(self.symbols[ofIdentifier]!)")
            return
        }
        
        if child != nil {
            child?.checkType(type, ofIdentifier: ofIdentifier)
            return
        } else {
            print("ERROR: No identifier \(ofIdentifier) in symbol table during type checking") // Should never happen
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
