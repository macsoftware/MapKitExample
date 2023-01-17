//
//  ViewController.swift
//  MapKitExample
//
//  Created by Ian MacKinnon on 12/01/2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var commentTextField: UITextField!
    
    var locationManager = CLLocationManager()
    
    var chosenLat = Double()
    var chosenLong = Double()
    
    var selectedTitle = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        let gestureRecogniser = UILongPressGestureRecognizer(target: self, action: #selector(dropPin(gestureRecogniser:)))
        gestureRecogniser.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecogniser)
        
        if (selectedTitle != ""){
            //CoreData
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let idString = selectedId!.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try context.fetch(fetchRequest)
                
                for result in results as! [NSManagedObject]{
                    if let title = result.value(forKey: "title") as? String{
                        annotationTitle = title
                        if let subtitle = result.value(forKey: "subtitle") as? String{
                            annotationSubtitle = subtitle
                            if let latitude = result.value(forKey: "latitude") as? Double{
                                annotationLatitude = latitude
                                if let longitude = result.value(forKey: "longitude") as? Double{
                                    annotationLongitude = longitude
                                                                        
                                    let annotation = MKPointAnnotation()
                                    annotation.title = annotationTitle
                                    annotation.subtitle = annotationSubtitle
                                    let coordination = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                    annotation.coordinate = coordination
                                    
                                    mapView.addAnnotation(annotation)
                                    nameTextField.text = annotationTitle
                                    commentTextField.text = annotationSubtitle
                                    
                                    locationManager.stopUpdatingLocation()
                                    
                                    let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                    let region = MKCoordinateRegion(center: coordination, span: span)
                                    mapView.setRegion(region, animated: true)
                                }
                            }
                        }
                    }
                }
            }catch{
                
            }
            
        }else{
            //Add new data
        }
    }
    
    @objc func dropPin(gestureRecogniser: UILongPressGestureRecognizer){
        
        if gestureRecogniser.state == .began{
            let touchPoint = gestureRecogniser.location(in: self.mapView)
            let touchCoords = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            chosenLat = touchCoords.latitude
            chosenLong = touchCoords.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchCoords
            annotation.title = nameTextField.text
            annotation.subtitle = commentTextField.text
            mapView.addAnnotation(annotation)
            
        }
            
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if(selectedTitle == ""){
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            //Zoom level
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation{
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if(pinView == nil){
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = UIColor.black
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if (selectedTitle != ""){
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarks, error) in
                
                if let placemark = placemarks{
                    if placemark.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
            }
        }
    }
    
    @IBAction func saveButtonClicked(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameTextField.text, forKey: "title")
        newPlace.setValue(commentTextField.text, forKey: "subtitle")
        newPlace.setValue(chosenLat, forKey: "latitude")
        newPlace.setValue(chosenLong, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        
        do{
            try context.save()
            print("success saving pin data")
        }catch{
            print("error saving pin data")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    
}

