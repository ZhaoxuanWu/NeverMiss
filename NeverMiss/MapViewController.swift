//
//  MapViewController.swift
//  NeverMiss
//
//  Created by Zhaoxuan Wu on 16/6/17.
//  Copyright © 2017 Zhaoxuan Wu. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreLocation

struct PreferencesKeys {
    static let savedItems = "savedItems"
}

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var geotifications: [Geotification] = []
    let locationManager = CLLocationManager()
    
    var stopsDictionary: [String:[String:String]]!
    var stopCode:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        loadAllGeotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        let lat = Double((stopsDictionary[stopCode]?["lat"])!)
        let lng = Double((stopsDictionary[stopCode]?["lng"])!)
        let coordinate = CLLocationCoordinate2D(latitude: lat!, longitude: lng!)
        let radius = Double(200)
        let identifier = NSUUID().uuidString
        let note = stopsDictionary[stopCode]?["name"]
        let eventType: EventType = .onEntry
        addGeotification(didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note!, eventType: eventType)
        //self.label.text = self.villain.name
        //self.imageView!.image = UIImage(named: villain.imageName)
    }

    // MARK: Loading and saving functions
    func loadAllGeotifications() {
        geotifications = []
        guard let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) else { return }
        for savedItem in savedItems {
            guard let geotification = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? Geotification else { continue }
            add(geotification: geotification)
            let region = self.region(withGeotification: geotification)
            locationManager.startMonitoring(for: region)
        }
    }

    func saveAllGeotifications() {
        var items: [Data] = []
        for geotification in geotifications {
            let item = NSKeyedArchiver.archivedData(withRootObject: geotification)
            items.append(item)
        }
        UserDefaults.standard.set(items, forKey: PreferencesKeys.savedItems)
    }
    
    // Mark: Helper function tat removes the target geotification from saved items
    func removePin(targetGeotification: Geotification) {
        // First retrive saved items and append to array of geotifications
        geotifications = []
        guard let savedItems = UserDefaults.standard.array(forKey: PreferencesKeys.savedItems) else { return }
        for savedItem in savedItems {
            guard let geotification = NSKeyedUnarchiver.unarchiveObject(with: savedItem as! Data) as? Geotification else { continue }
            geotifications.append(geotification)
        }

        // Only remove the target geotification from the array of geotifications
        var items: [Data] = []
        for geotification in geotifications {
            if geotification.note != targetGeotification.note {
                let item = NSKeyedArchiver.archivedData(withRootObject: geotification)
                items.append(item)
            }
        }
        UserDefaults.standard.set(items, forKey: PreferencesKeys.savedItems)
        
    }
    
    // MARK: Functions that update the model/associated views with geotification changes
    func add(geotification: Geotification) {
        geotifications.append(geotification)
        mapView.addAnnotation(geotification)
        addRadiusOverlay(forGeotification: geotification)
        updateGeotificationsCount()
    }
    
    func remove(geotification: Geotification) {
        if let indexInArray = geotifications.index(of: geotification) {
            geotifications.remove(at: indexInArray)
        }
        mapView.removeAnnotation(geotification)
        removeRadiusOverlay(forGeotification: geotification)
        updateGeotificationsCount()
    }
    
    func updateGeotificationsCount() {
        if geotifications.count == 17 {
            showAlert(withTitle: "Warning", message: "You have reached the limit number of station alerts you could save. Please remove some of them, or your saved station alerts will be cleared automatically.")
        }

        if geotifications.count >= 19 {
            // showAlert(withTitle: "Warning", message: "Your saved station alerts are cleared as you have exceeded the limit number of station alerts.")
            // clear all saved geotifications
            while !geotifications.isEmpty{
                stopMonitoring(geotification: geotifications[0])
                remove(geotification: geotifications[0])
                saveAllGeotifications()
            }
        }
    }
    

    @IBAction func startOver(_ sender: UIBarButtonItem) {
        // Go back to the first page and delete all current geotifications
        while !geotifications.isEmpty{
            stopMonitoring(geotification: geotifications[0])
            remove(geotification: geotifications[0])
            saveAllGeotifications()
        }
        //let controller = self.storyboard!.instantiateViewController(withIdentifier: "rootController") as! ViewController
        //navigationController?.pushViewController(controller, animated: true)
        // Go back to root view controller
        navigationController?.popToRootViewController(animated: true)
    }
    
    // MARK: Map overlay functions
    func addRadiusOverlay(forGeotification geotification: Geotification) {
        mapView?.add(MKCircle(center: geotification.coordinate, radius: geotification.radius))
    }
    
    func removeRadiusOverlay(forGeotification geotification: Geotification) {
        // Find exactly one overlay which has the same coordinates & radius to remove
        guard let overlays = mapView?.overlays else { return }
        for overlay in overlays {
            guard let circleOverlay = overlay as? MKCircle else { continue }
            let coord = circleOverlay.coordinate
            if coord.latitude == geotification.coordinate.latitude && coord.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius {
                mapView?.remove(circleOverlay)
                break
            }
        }
    }
    
    /*  Core Location requires each geofence to be represented as a CLCircularRegion instance before it can be registered for monitoring. To handle this requirement, to create a helper method that returns a CLCircularRegion from a given Geotification object. */
    func region(withGeotification geotification: Geotification) -> CLCircularRegion {
    
        // initialise a CLCircularRegion object
        let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
        
        // If the user is not in the fence at the time, set true to notifyOnEntry
        // If the user is in the fence at the time, notify on exit
        region.notifyOnEntry = (geotification.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    
    /* Start monitoring whenever the user adds a fence */
    func startMonitoring(geotification: Geotification) {
        
        // Check if the device has the required hardware to monitor
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            showAlert(withTitle: "Error", message: "Sorry! Geofencing, the technology used in this App is not supported on this device!")
            return
        }
        
        // Check authorisation status again
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            showAlert(withTitle: "Warning", message: "Your bus alert is saved but will only be activated once your grant NeverMiss permission to access your device's location.")
        }
        
        let region = self.region(withGeotification: geotification)
        
        // Last step to register!
        locationManager.startMonitoring(for: region)
    
    }
    
    /* Stop monitoring when the user cancels */
    func stopMonitoring(geotification: Geotification) {
        for region in locationManager.monitoredRegions {
            guard let circularRegion = region as? CLCircularRegion, circularRegion.identifier == geotification.identifier else {
                //until finds the correct one to remove
                continue
            }
            locationManager.stopMonitoring(for: circularRegion)
        }
    }
    
    //
    func addGeotification(didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        
        // Make sure the radius is at most the maxmimum monitoring distance
        let clampedRadius = min(radius, locationManager.maximumRegionMonitoringDistance)
        let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
        add(geotification: geotification)
        
        // Register the new fence
        startMonitoring(geotification: geotification)
        saveAllGeotifications()
    }
    
    // MARK: Other mapview functions
    @IBAction func zoomToCurrentLocation(_ sender: Any) {
        mapView.zoomToUserLocation()
    }
    
}


// MARK: - Location Manager Delegate
extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        mapView.showsUserLocation = (status == .authorizedAlways)
        mapView.showsUserLocation = (status == .authorizedWhenInUse)
    }
    
    // In case of failure, to facilitate debugging
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager failed with following error: \(error)")
    }
}

// MARK: - MapView Delegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "myGeotification"
        if annotation is Geotification {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "DeleteGeotification")!, for: .normal)
                annotationView?.leftCalloutAccessoryView = removeButton
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
    
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 0.5
            circleRenderer.strokeColor = UIColor.blue.withAlphaComponent(0.5)
            circleRenderer.fillColor = UIColor.blue.withAlphaComponent(0.2)
            return circleRenderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Delete geotification
        let geotification = view.annotation as! Geotification
        // Stop monitoring
        stopMonitoring(geotification: geotification)
        remove(geotification: geotification)
        saveAllGeotifications()
    }
    
}
