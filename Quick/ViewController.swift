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
    @IBOutlet weak var output: UITextView!
    
    override func viewDidAppear(_ animated: Bool) {
        source.becomeFirstResponder()
    }
    
    @IBAction func runScript(_ sender: Any) {
        
        let sourceString = source.text!
        
        QuickError.shared.resetError()
        QuickError.shared.setCallback { (message) in
            UIAlertView(title: "Error", message: message, delegate: nil, cancelButtonTitle: "Ok").show()
        }
        
        let parser = Parser()
        parser.symbolTable.addSymbol("external", ofType: "Integer")
        let result = parser.parse(fromSource: sourceString)
        guard result == true else {
            return
        }
        parser.root.printDebugDescription(withLevel: 0)
        print(Output.shared.string)
        parser.symbolTable.printSymbolTable()

        parser.root.execute()
        print("Heap: \(QuickMemory.shared.heap)")
        
        output.text = Output.shared.userVisible
        
        source.resignFirstResponder()
        
    }
    

}

