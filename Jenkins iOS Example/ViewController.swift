//
//  ViewController.swift
//  Jenkins iOS Example
//
//  Created by Kent Sutherland on 4/16/17.
//  Copyright © 2017 Kent Sutherland. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func buttonTapped(sender: UIButton) {
        let alert = UIAlertController.init(title: "Test", message: "Test alert", preferredStyle: .alert)

        alert.addAction(UIAlertAction.init(title: "Done", style: .default, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))

        self.present(alert, animated: true, completion: nil)
    }
}

