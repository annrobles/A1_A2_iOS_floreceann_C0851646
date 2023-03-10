//
//  City.swift
//  A1_A2_iOS_floreceann_C0851646
//
//  Created by Ann Robles on 1/20/23.
//

import Foundation
import MapKit

class City: NSObject, MKAnnotation {
    var title: String?
    var subtitle: String?
    var coordinate: CLLocationCoordinate2D
    
    init(title: String?, subtitle: String?, coordinate: CLLocationCoordinate2D) {
        self.title = title
        self.subtitle = subtitle
        self.coordinate = coordinate
    }
}

