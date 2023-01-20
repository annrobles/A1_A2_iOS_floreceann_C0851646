//
//  ViewController.swift
//  A1_A2_iOS_floreceann_C0851646
//
//  Created by Ann Robles on 1/20/23.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate  {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var routeButton: UIButton!
    
    var routeLine: MKPolyline?
    var locationManager = CLLocationManager()
    var destination: CLLocationCoordinate2D!
    var markerText: [String] = ["A", "B", "C"]
    var cities = [City]()
    var distanceLabels: [UILabel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        routeButton.isHidden = true
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        map.isZoomEnabled = false
        map.showsUserLocation = true
        map.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        tap.numberOfTapsRequired = 1
        map.addGestureRecognizer(tap)
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(dropPin))
        longPress.delaysTouchesBegan = true
        map.addGestureRecognizer(longPress)
        map.delegate = self
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        displayLocation(latitude: latitude, longitude: longitude)
    }
    
    func displayLocation(latitude: CLLocationDegrees,
                         longitude: CLLocationDegrees)
    {
        let latDelta: CLLocationDegrees = 0.7
        let lngDelta: CLLocationDegrees =  0.7
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let region = MKCoordinateRegion(center: location, span: span)
        
        map.setRegion(region, animated: true)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        
        let touchpoint = sender.location(in: map)
        let coordinate = map.convert(touchpoint, toCoordinateFrom: map)
        let annotation = MKPointAnnotation()
        
        if self.cities.count > 1 {
            routeButton.isHidden = false
        }
        
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: {(placemarks, error) in
            
            if error != nil {
                print(error!)
            } else {
                DispatchQueue.main.async {
                    if let placeMark = placemarks?[0] {
                        
                        if placeMark.locality != nil {
                            
                            if self.cities.count <= 3 {
                                let place = City(title: self.markerText[self.cities.count], subtitle: placeMark.locality!, coordinate: coordinate)

                                self.cities.append(place)
                                self.map.addAnnotation(place)
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
    
    func addPolyline() {
        let coordinates = cities.map {$0.coordinate}
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polyline, level: .aboveRoads)
    }
    
    func addPolygon() {
        let coordinates = cities.map {$0.coordinate}
        let polygon = MKPolygon(coordinates: coordinates, count: coordinates.count)
        map.addOverlay(polygon)
    }

}

extension ViewController: MKMapViewDelegate {
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
