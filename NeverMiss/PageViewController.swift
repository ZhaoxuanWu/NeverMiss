//
//  PageViewController.swift
//  NeverMiss
//
//  Created by 吴 on 2017/7/18.
//  Copyright © 2017年 Zhaoxuan Wu. All rights reserved.
//

import Foundation
import UIKit

class PageViewController: UIPageViewController {

    
    var pageHeaders = ["Welcome to NeverMiss", "Select or Search", "Which Bus Should I Take?", "That's All"]
    var pageImages = ["Step 1","Step 2","Step 3", "Step 4"]
    var pageDescriptions = ["NeverMiss helps you track your route and notify you when you need to alight.", "Your stop notification will start once you confirm your destination.", "In case you don't know which bus to take, you can search your route like this!",  "We ensure you will never miss your stop again!"]

    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.dataSource = self
        
        // create the first view controller
        if let startWalkthroughVC = self.viewControllerAtIndex(index: 0) {
            setViewControllers([startWalkthroughVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    // MARK: Navigate
    
    func nextPageWithIndex(index: Int) {
        
        if let nextWalkthroughVC = self.viewControllerAtIndex(index: index + 1) {
            setViewControllers([nextWalkthroughVC], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func viewControllerAtIndex(index: Int) -> WalkthroughViewController? {
        
        if index == NSNotFound || index < 0 || index >= self.pageDescriptions.count {
            return nil
        }
        
        if let walkthroughViewController = storyboard?.instantiateViewController(withIdentifier: "WalkthroughViewController") as? WalkthroughViewController {
            walkthroughViewController.imageName = pageImages[index]
            walkthroughViewController.headerText = pageHeaders[index]
            walkthroughViewController.descriptionText = pageDescriptions[index]
            walkthroughViewController.index = index
            
            return walkthroughViewController
        }
        
        return nil
    }
    
}

// MARK: DataSource
extension PageViewController: UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! WalkthroughViewController).index
        index -= 1
        return self.viewControllerAtIndex(index: index)
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! WalkthroughViewController).index
        index += 1
        return self.viewControllerAtIndex(index: index)
    }
}
