//
//  WalkthroughViewController.swift
//  NeverMiss
//
//  Created by 吴 on 2017/7/18.
//  Copyright © 2017年 Zhaoxuan Wu. All rights reserved.
//

import Foundation
import UIKit

class WalkthroughViewController: UIViewController {

    // MARK: Outlets

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    // MARK: Variables for each screen
    var index = 0
    var headerText = ""
    var imageName = ""
    var descriptionText = ""
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        headerLabel.text = headerText
        descriptionLabel.text = descriptionText
        imageView.image = UIImage(named: imageName)
        pageControl.currentPage = index
        
        // customise next and get started button
        startButton.isHidden = (index == 3) ? false : true
        nextButton.isHidden = (index == 3) ? true : false
        nextButton.layer.cornerRadius = 5.0
        nextButton.layer.masksToBounds = true
        startButton.layer.cornerRadius = 5.0
        startButton.layer.masksToBounds = true
        
    }
    
    @IBAction func startClicked(_ sender: Any) {
        
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "DisplayedWalkthrough")
        
        self.dismiss(animated: true, completion: nil)
    }
    

    @IBAction func nextClicked(_ sender: Any) {
        
        let pageViewController = self.parent as! PageViewController
        pageViewController.nextPageWithIndex(index: index)
        
    }
    
    
}
