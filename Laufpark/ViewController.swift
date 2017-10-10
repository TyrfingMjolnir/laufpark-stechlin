//
//  ViewController.swift
//  Laufpark
//
//  Created by Chris Eidhof on 07.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import UIKit
import MapKit

struct State: Equatable {
    var tracks: [Track]
    var loading: Bool { return tracks.isEmpty }
    var annotationsVisible: Bool = false
    
    var selection: MKPolygon? {
        didSet {
            trackPosition = nil
        }
    }
    var trackPosition: CGFloat? // 0...1
    
    init(tracks: [Track]) {
        selection = nil
        trackPosition = nil
        self.tracks = tracks
    }
    
    static func ==(lhs: State, rhs: State) -> Bool {
        return lhs.selection == rhs.selection && lhs.trackPosition == rhs.trackPosition && lhs.tracks == rhs.tracks && lhs.annotationsVisible == rhs.annotationsVisible
    }
}

class ViewController: UIViewController, MKMapViewDelegate {
    let mapView: MKMapView = buildMapView()
    var lines: [MKPolygon: Color] = [:]
    var renderers: [MKPolygon: MKPolygonRenderer] = [:]
    var trackForPolygon: [MKPolygon: Track] = [:]
//    var draggedPointAnnotation: IBox<MKPointAnnotation>!
//    var draggedLocation: I<(distance: Double, location: CLLocation)?>!
    var loadingIndicator: UIActivityIndicatorView!
    
    var state: State {
        didSet {
            if state.loading {
                loadingIndicator.startAnimating()
            } else {
                loadingIndicator.stopAnimating()
            }
            if state.tracks != oldValue.tracks {
                mapView.removeOverlays(mapView.overlays)
                for track in state.tracks {
                    let line = track.line
                    lines[line] = track.color
                    trackForPolygon[line] = track
                    mapView.add(line)
                }
            }
            if state.selection != oldValue.selection {
                for (line, renderer) in renderers {
                    configureRenderer(renderer, with: line, selected: false)
                }
                if let newSelection = state.selection, let renderer = renderers[newSelection] {
                    configureRenderer(renderer, with: newSelection, selected: true)
                }
            }
        }
    }

//    var disposables: [Any] = []
    var locationManager: CLLocationManager?
//    var trackInfoView: TrackInfoView!
//    let darkMode: I<Bool>
//    var timer: Disposable?

//    var selectedTrack: I<Track?> {
//        return selection.map {
//            guard let p = $0 else { return nil }
//            return self.trackForPolygon[p]
//        }
//    }
    
    init() {
        state = State(tracks: [])
//        selection = state.i.map { $0.selection }
//        hasSelection = state.i.map { $0.selection != nil }
//        darkMode = mapView[\.mapType] == .standard

        super.init(nibName: nil, bundle: nil)

//        draggedLocation = state.i.map(eq: lift(==), { [weak self] state in
//            guard let s = state.selection,
//                let track = self?.trackForPolygon[s],
//                let location = state.trackPosition else { return nil }
//            let distance = Double(location) * track.distance
//            guard let point = track.point(at: distance) else { return nil }
//            return (distance: distance, location: point)
//        })

//        let draggedPoint: I<CLLocationCoordinate2D> = draggedLocation.map {
//            $0?.location.coordinate ?? CLLocationCoordinate2D()
//        }
        
//        draggedPointAnnotation = annotation(location: draggedPoint)
        
//        let position: I<CGFloat?> = draggedLocation.map {
//            ($0?.distance).map { CGFloat($0) }
//        }
        
//        let elevations = selectedTrack.map(eq: { _, _ in false }) { track in
//            track?.elevationProfile
//        }
        
//        let points: I<[CGPoint]> = elevations.map(eq: ==) { ele in
//            ele.map { profile in
//                profile.map { CGPoint(x: $0.distance, y: $0.elevation) }
//            } ?? []
//        }
        
//        let rect: I<CGRect> = elevations.map { profile in
//            guard let profile = profile else { return .zero }
//            let elevations = profile.map { $0.elevation }
//            return CGRect(x: 0, y: elevations.min()!, width: profile.last!.distance.rounded(.up), height: elevations.max()!-elevations.min()!)
//        }
        
//        trackInfoView = TrackInfoView(position: position, points: points, pointsRect: rect, track: selectedTrack, darkMode: darkMode)
    }
    
    func setTracks(_ t: [Track]) {
        state.tracks = t
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addConstraintsToSizeToParent()
        
        // MapView
        mapView.delegate = self
//        disposables.append(state.i.map { $0.tracks }.observe {
//            $0.forEach { track in
//                let line = track.line
//                self.lines[line] = track.color
//                self.trackForPolygon[line] = track
//                self.mapView.unbox.add(line)
//            }
//        })
        
//        let blurredView = trackInfoView.view!
//        view.addSubview(blurredView)
//        let height: CGFloat = 120
//        blurredView.heightAnchor.constraint(greaterThanOrEqualToConstant: height)
//        let bottomConstraint = blurredView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        disposables.append(if_(hasSelection, then: 0, else: height).observe { newOffset in
//            bottomConstraint.constant = newOffset
//            UIView.animate(withDuration: 0.2) {
//                self.view.layoutIfNeeded()
//            }
//        })
//        bottomConstraint.isActive = true
//        blurredView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//        blurredView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        view.backgroundColor = .white
        

//        mapView.unbox.addAnnotation(draggedPointAnnotation.unbox)
        
//        disposables.append(trackInfoView.pannedLocation.observe { loc in
//            self.state.change { $0.trackPosition = loc }
//        })


//        self.disposables.append(draggedLocation.observe { x in
//            guard let (_, location) = x else { return }
//            // todo subtract the height of the trackInfo box (if selected)
//            if !self.mapView.unbox.annotations(in: self.mapView.unbox.visibleMapRect).contains(self.draggedPointAnnotation.unbox) {
//                self.mapView.unbox.setCenter(location.coordinate, animated: true)
//            }
//        })

//        let isLoading = state[\.loading]
//        let loadingIndicator = activityIndicator(style: darkMode.map { $0 ? .gray : .white }, animating: isLoading)
        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])

//        let toggleMapButton = button(type: .custom, titleImage: I(constant: UIImage(named: "map")!), backgroundColor: I(constant: UIColor(white: 1, alpha: 0.8)), titleColor: I(constant: .black), onTap: { [unowned self] in
//            self.mapView.unbox.mapType = self.mapView.unbox.mapType == .standard ? .hybrid : .standard
//        })
//        rootView.addSubview(toggleMapButton, constraints: [equalTop(offset: -25), equalRight(offset: 10)])
        
//        let toggleAnnotation = button(type: .custom, title: I(constant: "i"), backgroundColor: I(constant: UIColor(white: 1, alpha: 0.8)), titleColor: I(constant: .black), onTap: { [unowned self] in
//            self.state.change { $0.annotationsVisible = !$0.annotationsVisible }
//        })
//        rootView.addSubview(toggleAnnotation, constraints: [equalTop(offset: -55), equalRight(offset: 10)])
//        let annotations: [MKPointAnnotation] = POI.all.map { poi in
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = poi.location
//            annotation.title = poi.name
//            return annotation
//        }

//        disposables.append(state[\.annotationsVisible].observe { [unowned self] visible in
//            if visible {
//                self.mapView.unbox.addAnnotations(annotations)
//            } else {
//                self.mapView.unbox.removeAnnotations(annotations)
//            }
//        })
    }
    
    func resetMapRect() {
        mapView.setVisibleMapRect(MKMapRect(origin: MKMapPoint(x: 143758507.60971117, y: 86968700.835495561), size: MKMapSize(width: 437860.61378830671, height: 749836.27541357279)), edgePadding: UIEdgeInsetsMake(10, 10, 10, 10), animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        resetMapRect()
        mapView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(mapTapped(sender:))))
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager = CLLocationManager()
            locationManager!.requestWhenInUseAuthorization()
        }
    }
    
    
    @objc func mapTapped(sender: UITapGestureRecognizer) {
        let point = sender.location(ofTouch: 0, in: mapView)
        let mapPoint = MKMapPointForCoordinate(mapView.convert(point, toCoordinateFrom: mapView))
        let possibilities = lines.keys.filter { line in
            let renderer = renderers[line]!
            let point = renderer.point(for: mapPoint)
            return renderer.path.contains(point)
        }

        // in case of multiple matches, toggle between the selections, and start out with the smallest route
        if let s = state.selection, possibilities.count > 1 && possibilities.contains(s) {
            state.selection = possibilities.lazy.sorted { $0.pointCount < $1.pointCount }.first(where: { $0 != s })
        } else {
            state.selection = possibilities.first
        }
    }

    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        resetMapRect()
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let line = overlay as? MKPolygon else { return MKOverlayRenderer() }
        if let renderer = renderers[line] { return renderer }
        let renderer = buildRenderer(line)
        renderers[line] = renderer
        return renderer
    }
    
//    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
//        guard annotation is MKPointAnnotation else { return nil }
////        if annotation === self.draggedPointAnnotation.unbox {
////            let result = MKPinAnnotationView(annotation: annotation, reuseIdentifier: nil)
////            result.pinTintColor = .red
////            return result
////        } else {
//            let result = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
//            result.image = UIImage(named: "partner")!
//            result.frame.size = CGSize(width: 32, height: 32)
////            result.pinTintColor = .blue
//            result.canShowCallout = true
//            return result
////        }
//    }
    
    func buildRenderer(_ line: MKPolygon) -> MKPolygonRenderer {
        let isSelected = state.selection == line
        let renderer = MKPolygonRenderer(polygon: line)
        configureRenderer(renderer, with: line, selected: isSelected)
        return renderer
    }
    
    func configureRenderer(_ renderer: MKPolygonRenderer, with line: MKPolygon, selected: Bool) {
        let lineColor = lines[line]!.uiColor
        let fillColor = selected ? lineColor.withAlphaComponent(0.2) : lineColor.withAlphaComponent(0.1)
        renderer.strokeColor = lineColor
        renderer.fillColor = fillColor
        let highlighted = state.selection == nil || selected
        renderer.lineWidth = highlighted ? 3 : 1
        renderer.alpha = 1
    }
}

