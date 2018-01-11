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
    
    @IBAction func runScript(_ sender: Any) {
        
        let sourceString = source.text!
        
        let parser = Parser()
        let result = parser.parse(fromSource: sourceString)
        assert(result == true)
        parser.root.printDebugDescription(withLevel: 0)
        print(Output.shared.string)

        
    }
    

}

