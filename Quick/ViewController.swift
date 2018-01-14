//
//  ViewController.swift
//  Quick
//
//  Created by Bob Warwick on 2018-01-10.
//  Copyright © 2018 Whole Punk Creators Ltd. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var source: UITextView!
    
    override func viewDidAppear(_ animated: Bool) {
        source.becomeFirstResponder()
    }
    
    @IBAction func runScript(_ sender: Any) {
        
        let sourceString = source.text!
        
        let parser = Parser()
        parser.symbolTable.addSymbol("external", ofType: "Integer")
        let result = parser.parse(fromSource: sourceString)
        guard result == true else {
            return
        }
        parser.root.printDebugDescription(withLevel: 0)
        print(Output.shared.string)
        parser.symbolTable.printSymbolTable()

        
    }
    

}

