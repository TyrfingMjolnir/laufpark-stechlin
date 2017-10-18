//
//  MapView.swift
//  Incremental
//
//  Created by Chris Eidhof on 18.10.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import UIKit
import MapKit

extension IBox where V: MKMapView {
    public func bind(annotations: [MKPointAnnotation], visible: I<Bool>) {
        disposables.append(visible.observe { [unowned self] value in
            if value {
                self.unbox.addAnnotations(annotations)
            } else {
                self.unbox.removeAnnotations(annotations)
            }
        })

    }
}
