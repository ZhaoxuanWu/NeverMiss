//
//  AppDelegate.swift
//  NeverMiss
//
//  Created by Zhaoxuan Wu on 15/6/17.
//  Copyright © 2017 Zhaoxuan Wu. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import AVFoundation
import MapKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let locationManager = CLLocationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        //application.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
        //UIApplication.shared.cancelAllLocalNotifications()
        
        let center = UNUserNotificationCenter.current()
        // Enable notification
        center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        // Clears all existing notifications
        center.removeAllPendingNotificationRequests()
        
        // Navigation bar set to light color
        UINavigationBar.appearance().barStyle = .blackOpaque
        //UINavigationBar.appearance().barTintColor = UIColor.christmasGreen()
        UINavigationBar.appearance().tintColor = UIColor.white
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func handleEvent(forRegion region: CLRegion!) {

        // Unwrap and create message string
        guard let message = note(fromRegionIdentifier: region.identifier) else {
            return
        }
        let messageString = message + " is within 200m of your location. Please prepare to alight at the next stop."
        
        if UIApplication.shared.applicationState == .active {
            
            // Objective : Show an alert is the application is active
            
            // Get reference to mapViewController and NavigationController
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            
            let mapController = mainStoryboard.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
            
            let navigationController = self.window?.rootViewController as! UINavigationController

            
            let alert = UIAlertController(title: "You have arrived!", message: messageString, preferredStyle: .alert)
            let endAction = UIAlertAction(title: "End Trip", style: .destructive, handler: { (action) -> Void in
                
                // Get geotification reference of the triggered geofence region
                let geotification = self.getGeo(fromRegionIdentifier: region.identifier)

                // Remove the target from saved items
                mapController.removePin(targetGeotification: geotification)
                
                // Upon completion of the removal, pop to the first view
                navigationController.popToRootViewController(animated: true)
                
            })
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in })
            
            alert.addAction(endAction)
            alert.addAction(cancel)
            
            // Show alert constructed
            window?.rootViewController?.present(alert, animated: true, completion: nil)
            
            // Play system default sound with the alert
            AudioServicesPlayAlertSound(1315)
        }
        else {
            // Otherwise present a local notification
        
            // Create notification content
            let content = UNMutableNotificationContent()
            content.title = "Alight Notification"
            content.body = messageString
            content.sound = UNNotificationSound.default()
            
            // Create trigger
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            
            // Create request identifier
            let requestIdentifier = "lockScreenNotification"
            
            // Create notification request
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)
            
            // Add request to notification center
            UNUserNotificationCenter.current().add(request) { error in
                if error == nil {
                    print("Time Interval Notification scheduled: \(requestIdentifier)")
                }
            }
            
        }
    }
    
    /* To retrieve the geotification note from the persistent store, based on its identifier, and returns the note for that geotification */
    func note(fromRegionIdentifier identifier: String) -> String? {
        let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) as? [NSData]
        let geotifications = savedItems?.map { NSKeyedUnarchiver.unarchiveObject(with: $0 as Data) as? Geotification }
        let index = geotifications?.index { $0?.identifier == identifier }
        // Return Note required, which is the stop name
        return index != nil ? geotifications?[index!]?.note : nil
    }
    
    func getGeo(fromRegionIdentifier identifier: String) -> Geotification {
        let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) as? [NSData]
        let geotifications = savedItems?.map { NSKeyedUnarchiver.unarchiveObject(with: $0 as Data) as? Geotification }
        let index = geotifications?.index { $0?.identifier == identifier }
        // Return Note required, which is the stop name
        return (index != nil ? geotifications?[index!]: nil)!
    }

}

extension AppDelegate: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region)
        }

    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleEvent(forRegion: region)
        }

    }
}

extension UIColor {
    static func christmasGreen() -> UIColor {
        return UIColor(red: 31.0/255.0, green: 138.0/255.0, blue: 112.0/255.0, alpha: 1.0)
    }
    
    static func candyGreen() -> UIColor {
        return UIColor(red: 67.0/255.0, green: 205.0/255.0, blue: 135.0/255.0, alpha: 1.0)
    }
}
