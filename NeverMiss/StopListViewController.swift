//
//  StopListViewController.swift
//  NeverMiss
//
//  Created by Zhaoxuan Wu on 16/6/17.
//  Copyright © 2017 Zhaoxuan Wu. All rights reserved.
//

import Foundation
import UIKit

class StopListViewController: UITableViewController {
    
    // Properties for table fill
    var busNumber: String!
    var stops: [String]!
    var stopsDictionary: [String:[String:String]]!
    var stopCode:String!
    var stopCodeSelected:String!
    
    // Properties for search bar
    let searchController = UISearchController(searchResultsController: nil)
    var filteredStops = [String]()
    
    @IBOutlet weak var confirmButton: UIBarButtonItem!
    @IBOutlet weak var titleBar: UINavigationItem!
    @IBOutlet weak var searchBar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Disable confirm button when no row is selected
        confirmButton.isEnabled = false
        
        // Show text for title
        titleBar.title = busNumber
        
        // Allows class to be informed as text changes within the UISearchBar
        searchController.searchResultsUpdater = self
        
        // Do not dim the view presented
        searchController.dimsBackgroundDuringPresentation = false
        
        // Ensure that search bar does not remain on screen if user navigates to another screen, when search is active
        definesPresentationContext = true
        
        // Connect searchController.searchBar to the searchBar UI item
        searchBar.addSubview(searchController.searchBar)

       // if Bundle.main.path(forResource: "\(busNumber)", ofType: "json", inDirectory: "bus-services") == nil {
    //        navigationController?.popToRootViewController(animated: true)
    //        showAlert(withTitle: "Error", message: "The bus service '\(busNumber)' is not in our database. Please kindly verify.")
     //   }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        //print(busNumber)
        stops = parseJSONToUseableArray(busNumber: busNumber)
        //print(stops)
        stopsDictionary = parseJSONBusStops()
    }
    
    
    func parseJSONToUseableArray(busNumber: String) -> [String]{
        
        /* Path for JSON file */

        guard let pathForBusNumberJSON = Bundle.main.path(forResource: "\(busNumber)", ofType: "json", inDirectory: "bus-services") else {
            
            // If could not find the respective json file
            /* Back to main page and show error alert*/
            
            navigationController?.popToRootViewController(animated: true)
            showAlert(withTitle: "Error", message: "The bus service \"\(busNumber)\" is not in our database. Please kindly verify.")
            return ["Error"]
        }
        
       // print(pathForBusNumberJSON!)
        
        /* Raw JSON data */
        let rawRoutesJSON = try? Data(contentsOf: URL(fileURLWithPath: pathForBusNumberJSON))
        
        /* Parse the data into usable form */
        let parsedRoutesJSON = try! JSONSerialization.jsonObject(with: rawRoutesJSON!, options: .allowFragments) as! NSDictionary
        
        /* Do the first direction */
        guard let firstRouteDictionary = parsedRoutesJSON["1"] as? NSDictionary else {
            print("Cannot find key '1' in \(parsedRoutesJSON)")
            return ["Error"]
        }
        
        guard var resultStops = firstRouteDictionary["stops"] as? [String] else {
            print("Cannot find key 'stops' in \(firstRouteDictionary)")
            return ["Error"]
        }
        
        /* Do the second direction, check for non-duplicate stops */
        guard let secondRouteDictionary = parsedRoutesJSON["2"] as? NSDictionary else {
            print("Cannot find key '2' in \(parsedRoutesJSON)")
            return ["Error"]
        }
        
        guard let secondRouteStops = secondRouteDictionary["stops"] as? [String] else {
            print("Cannot find key '2' in \(secondRouteDictionary)")
            return ["Error"]
        }
        
        for stop in secondRouteStops {
            if !resultStops.contains(stop) {
                resultStops.append(stop)
            }
        }
        
        return resultStops
    }
    
    
    func parseJSONBusStops() -> [String:[String:String]]{
        
        /* Path for JSON file */
        
        guard let pathForBusStopsJSON = Bundle.main.path(forResource: "bus-stops", ofType: "json") else {
            
            // If could not find the respective json file
            /* TO BE INPLEMENTED, back to main page and show error alert*/
            return ["":["":""]]
        }
        
        /* Raw JSON data */
        let rawStopsJSON = try? Data(contentsOf: URL(fileURLWithPath: pathForBusStopsJSON))
        
        /* Parse the data into usable form */
        let parsedStopsJSON = try! JSONSerialization.jsonObject(with: rawStopsJSON!, options: .allowFragments) as! [String:[String:String]]
        
        // test
        //print(parsedStopsJSON["93081"]!)
        
        return parsedStopsJSON
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        
        filteredStops = stops.filter { eachStop in
            //return eachStop.lowercased().contains(searchText.lowercased())
            let stopName: String = (stopsDictionary[eachStop]?["name"])!
            return stopName.lowercased().contains(searchText.lowercased())
        }
        
        // update and reload table presented
        tableView.reloadData()
    
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredStops.count
        }
        return stops.count
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        /*/* Index = 0, show the bus number */
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "numberCell")!
            cell.textLabel?.text = busNumber
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            return cell
        } */
        
        /* Other cells */
        let cell = tableView.dequeueReusableCell(withIdentifier: "stopCell")!
        
        let stopCode: String
        
        if searchController.isActive && searchController.searchBar.text != "" {
            stopCode = filteredStops[indexPath.row]
        } else {
            stopCode = stops[indexPath.row]
        }
        
        // Set the name and detial
        cell.textLabel?.text = stopCode
        // Get bus stop name
        cell.detailTextLabel?.text = stopsDictionary[stopCode]?["name"]
        
        return cell
    }

    /*
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        detailController.stopCode = self.stops[(indexPath as NSIndexPath).row]
        navigationController?.pushViewController(detailController, animated: true)
        print(detailController.stopCode)
    }
*/
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath){
       
        let indexPath = tableView.indexPathForSelectedRow!
        let currentCell = tableView.cellForRow(at: indexPath)! as UITableViewCell
        stopCodeSelected = currentCell.textLabel?.text
        
        if searchController.isActive && searchController.searchBar.text != "" {
            
            // If the user does perform a search, directly show next map view controller when a row is tapped
            let mapController = self.storyboard!.instantiateViewController(withIdentifier: "MapViewController") as! MapViewController
            mapController.stopCode = self.stopCodeSelected
            mapController.stopsDictionary = self.stopsDictionary
            navigationController?.pushViewController(mapController, animated: true)
            
        }
        else{
            // If the user does not perform a search, confirm button will be enabled when a row is selected
            confirmButton.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // Communicate data to the next ViewController

        let mapController = segue.destination as? MapViewController
        guard segue.identifier == "mapViewSegue" else {
            print("Wrong Segue triggered")
            return
        }
        //print(self.stopCodeSelected)
        //print(self.stopsDictionary["84009"]!)
        mapController?.stopCode = self.stopCodeSelected
        mapController?.stopsDictionary = self.stopsDictionary
    }
 

}

extension StopListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }

}
