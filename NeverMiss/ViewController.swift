//
//  ViewController.swift
//  NeverMiss
//
//  Created by Zhaoxuan Wu on 15/6/17.
//  Copyright © 2017 Zhaoxuan Wu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var numberTextField: UITextField!
    @IBOutlet weak var showButton: UIButton!
    @IBOutlet weak var routeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        routeButton.layer.cornerRadius = 7.0
        routeButton.layer.masksToBounds = true
        numberTextField.layer.cornerRadius = 5.0
        numberTextField.layer.masksToBounds = true
        numberTextField.delegate = self
        
        // display walkthrough if it is the first time the user launched the app
        displayWalkthroughs()
        
        
        // Looks for single or multiple taps
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Communicate data to the next ViewController
        let controller = segue.destination as? StopListViewController
        guard segue.identifier == "showListOfStopsSegue" else {
            //print("Wrong Segue triggered")
            return
        }
        let busNumber = numberTextField.text
        controller?.busNumber = busNumber

    }
    
    func dismissKeyboard() {
            view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == numberTextField {
            textField.resignFirstResponder()
            return false
        }
        return true
    }
    
    func displayWalkthroughs() {
        
        let userDefaults = UserDefaults.standard
        let displayedWalkthrough = userDefaults.bool(forKey: "DisplayedWalkthrough")
        
        if !displayedWalkthrough {
            if let pageViewConroller = storyboard?.instantiateViewController(withIdentifier: "PageViewController") {
                self.present(pageViewConroller, animated: true, completion: nil)
            }
        }
    }
}





