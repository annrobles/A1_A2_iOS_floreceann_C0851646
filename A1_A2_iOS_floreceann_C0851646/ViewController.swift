//
//  ViewController.swift
//  A1_A2_iOS_floreceann_C0851646
//
//  Created by Ann Robles on 1/20/23.
//

import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController, CLLocationManagerDelegate  {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var routeButton: UIButton!
    
    var routeLine: MKPolyline?
    var locationManager = CLLocationManager()
    
    var userLocation: CLLocationCoordinate2D!
    var citiesInAnnotation: [String] = [String]()
    var distancesBetweenCityUser: [String] = [String]()
    var cities = [City]()
    var cityCnt: Int = 0
    var distanceLabels: [UILabel] = []
    
    var resultSearchController:UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        map.isZoomEnabled = false
        map.showsUserLocation = true
        map.delegate = self
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        doubleTap.numberOfTapsRequired = 2
        map.addGestureRecognizer(doubleTap)
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable as? any UISearchResultsUpdating
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable.mapView = map
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.searchController = resultSearchController
        
        locationSearchTable.handleMapSearchDelegate = self
        
    }
    
    @IBAction func drawRoute(_ sender: UIButton) {
        map.removeOverlays(map.overlays)
        removeDistanceLabel()
        
        var nextIndex = 0
        for index in 0...2 {
            if index == 2 {
                nextIndex = 0
            } else {
                nextIndex = index + 1
            }
            
            let sourcePlaceMark = MKPlacemark(coordinate: cities[index].coordinate)
            let destinationPlaceMark = MKPlacemark(coordinate: cities[nextIndex].coordinate)
            let directionRequest = MKDirections.Request()
            
            directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
            directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
            directionRequest.transportType = .automobile
            let directions = MKDirections(request: directionRequest)
            directions.calculate { (response, error) in
                guard let directionResponse = response else {return}
                
                let route = directionResponse.routes[0]
                
                self.routeLine = route.polyline
                self.map.addOverlay(self.routeLine!, level: .aboveRoads)
                
                let rect = route.polyline.boundingMapRect
                self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
            }
        }
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        
        let touchpoint = sender.location(in: map)
        let coordinate = map.convert(touchpoint, toCoordinateFrom: map)
        let annotation = MKPointAnnotation()
        let marker: String
        
        cityCnt = cities.count
        
        if cityCnt == 0 {
            marker = "A"
        }
        else if cityCnt == 1 {
            marker = "B"
        }
        else {
            marker = "C"
        }

        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: {(placemarks, error) in
            
            if error != nil {
                print(error!)
            } else {
                DispatchQueue.main.async {
                    if let placeMark = placemarks?[0] {
                        
                        if placeMark.locality != nil {
                            
                            let distance: Double = self.getDistance(from: self.userLocation, to:  coordinate)
                            let place = City(title: marker,
                                             subtitle: placeMark.locality!,
                                             coordinate: coordinate)

                            if self.cityCnt < 3 {
                                if self.citiesInAnnotation.contains(placeMark.locality!) {
                                    for (index, myAnnotation) in self.map.annotations.enumerated() {
                                        
                                        if myAnnotation.subtitle == placeMark.locality {
                                            let citiesInAnnotationIndex = self.citiesInAnnotation.firstIndex(of: myAnnotation.subtitle! ?? "")
                                            self.removeOverlays()
                                            self.map.removeAnnotation(myAnnotation)
                                            place.title = self.cities[citiesInAnnotationIndex!].title
                                            self.cities.remove(at: citiesInAnnotationIndex!)
                                            self.cities.append(place)
                                            self.map.addAnnotation(place)
                                            self.distancesBetweenCityUser[citiesInAnnotationIndex!] = "\(String.init(format: "%2.f",  round(distance * 0.001)))km"
                                        }
                                    }
                                }
                                else {
                                    self.citiesInAnnotation.append(placeMark.locality!)
                                    self.cities.append(place)
                                    self.map.addAnnotation(place)
                                    self.distancesBetweenCityUser.append("\(String.init(format: "%2.f",  round(distance * 0.001)))km")
                                }

                            }
                            else {
                                if self.citiesInAnnotation.contains(placeMark.locality!) {
                                    for (index, myAnnotation) in self.map.annotations.enumerated() {
                                        
                                        if myAnnotation.subtitle == placeMark.locality {
                                            let citiesInAnnotationIndex = self.citiesInAnnotation.firstIndex(of: myAnnotation.subtitle! ?? "")
                                            self.removeOverlays()
                                            self.map.removeAnnotation(myAnnotation)
                                            place.title = self.cities[citiesInAnnotationIndex!].title
                                            self.cities.remove(at: citiesInAnnotationIndex!)
                                            self.cities.append(place)
                                            self.map.addAnnotation(place)
                                            self.distancesBetweenCityUser[citiesInAnnotationIndex!] = "\(String.init(format: "%2.f",  round(distance * 0.001)))km"
                                        }
                                    }
                                } else {
                                    self.removeOverlays()
                                    self.map.removeAnnotations(self.map.annotations)
                                    self.cityCnt = 1
                                    self.cities = []
                                    self.citiesInAnnotation = []
                                    self.distancesBetweenCityUser = []
                                    place.title = "A"
                                    self.cities.append(place)
                                    self.map.addAnnotation(place)
                                    self.citiesInAnnotation.append(placeMark.locality!)
                                    self.distancesBetweenCityUser.append("\(String.init(format: "%2.f",  round(distance * 0.001)))km")
                                }
                            }

                            if self.cities.count == 3 {
                                self.addPolyline()
                                self.addPolygon()
                            }
                        }
                    }
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        displayLocation(latitude: latitude, longitude: longitude, title: "My location")
        self.userLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func displayLocation(latitude: CLLocationDegrees,
                         longitude: CLLocationDegrees,
                         title: String)
    {
        let latDelta: CLLocationDegrees = 0.7
        let lngDelta: CLLocationDegrees =  0.7
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        map.setRegion(region, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.coordinate = location
        map.addAnnotation(annotation)
    }
    
    func addPolyline() {
        let coordinates = cities.map {$0.coordinate}
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polyline, level: .aboveRoads)
        
        showDistanceBetweenTwoPoint()
    }
    
    func addPolygon() {
        let coordinates = cities.map {$0.coordinate}
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polygon)
    }
    
    private func showDistanceBetweenTwoPoint() {
        var nextIndex = 0
        
        for index in 0...2{
            if index == 2 {
                nextIndex = 0
            } else {
                nextIndex = index + 1
            }

            let distance: Double = getDistance(from: cities[index].coordinate, to:  cities[nextIndex].coordinate)
            
            let pointA: CGPoint = map.convert(cities[index].coordinate, toPointTo: map)
            let pointB: CGPoint = map.convert(cities[nextIndex].coordinate, toPointTo: map)
        
            let labelDistance = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 18))

            labelDistance.textAlignment = NSTextAlignment.center
            labelDistance.text = "\(String.init(format: "%2.f",  round(distance * 0.001)))km"
            labelDistance.textColor = .black
            labelDistance.font = UIFont(name: "Thonburi-Bold", size: 10.0)
            labelDistance.center = CGPoint(x: (pointA.x + pointB.x) / 2, y: (pointA.y + pointB.y) / 2)
            
            distanceLabels.append(labelDistance)
        }
        for label in distanceLabels {
            map.addSubview(label)
        }
    }
    
    func getDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        
        return from.distance(from: to)
    }
    
    private func removeDistanceLabel() {
        for label in distanceLabels {
            label.removeFromSuperview()
        }
        
        distanceLabels = []
    }
    
    func removePin() {
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
    }
    
    func removeOverlays() {
        removeDistanceLabel()
        
        for polygon in map.overlays {
            map.removeOverlay(polygon)
        }
    }

}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "MyMarker")
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        
        let citiesInAnnotationIndex = self.citiesInAnnotation.firstIndex(of: annotation.subtitle! ?? "")
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        label.font = UIFont.italicSystemFont(ofSize: 14.0)
        
        if citiesInAnnotationIndex != nil {
            label.text = self.distancesBetweenCityUser[citiesInAnnotationIndex!]
        }
        
        annotationView.detailCalloutAccessoryView = label
        
        label.widthAnchor.constraint(lessThanOrEqualToConstant: label.frame.width).isActive = true
        label.heightAnchor.constraint(lessThanOrEqualToConstant: 90.0).isActive = true
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.systemGreen
            rendrer.lineWidth = 3
            
            if routeLine != nil {
                rendrer.strokeColor = UIColor.systemBlue
                rendrer.lineWidth = 5
            }
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.5)
            rendrer.strokeColor = UIColor.systemGreen
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }
}

extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        var marker: String?
        
        cityCnt = cities.count
        
        if cityCnt == 0 {
            marker = "A"
        }
        else if cityCnt == 1 {
            marker = "B"
        }
        else {
            marker = "C"
        }
        
        let distance: Double = self.getDistance(from: self.userLocation, to:  placemark.coordinate)
        let place = City(title: marker,
                         subtitle: placemark.locality!,
                         coordinate: placemark.coordinate)
        
        self.citiesInAnnotation.append(placemark.locality!)
        self.cities.append(place)
        self.map.addAnnotation(place)
        self.distancesBetweenCityUser.append("\(String.init(format: "%2.f",  round(distance * 0.001)))km")
        
        if self.cities.count == 3 {
            self.addPolyline()
            self.addPolygon()
        }
    }
}
