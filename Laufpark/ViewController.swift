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
    
    var selection: MKPolygon? {
        didSet {
            trackPosition = nil
        }
    }
 
    var trackPosition: CGFloat? // 0...1
    
    var hasSelection: Bool { return selection != nil }
    
    init(tracks: [Track]) {
        selection = nil
        trackPosition = nil
        self.tracks = tracks
    }
    
    static func ==(lhs: State, rhs: State) -> Bool {
        return lhs.selection == rhs.selection && lhs.trackPosition == rhs.trackPosition && lhs.tracks == rhs.tracks
    }
}

class ViewController: UIViewController, MKMapViewDelegate, TrackInfoViewDelegate {
    let mapView: MKMapView = buildMapView()
    var polygons: [MKPolygon: Track] = [:]
    var loadingIndicator: UIActivityIndicatorView!
    
    var state: State {
        didSet {
            update(old: oldValue)
        }
    }

    var locationManager: CLLocationManager?
    var trackInfoView: TrackInfoView = TrackInfoView()
    var trackInfoConstraint: NSLayoutConstraint!

    func update(old: State) {
        if state.loading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }
        if state.tracks != old.tracks {
            mapView.removeOverlays(mapView.overlays)
            for track in state.tracks {
                let polygon = track.polygon
                polygons[polygon] = track
                mapView.add(polygon)
            }
        }
        if state.selection != old.selection {
            self.trackInfoConstraint.isActive = self.state.selection != nil
            UIView.animate(withDuration: 0.2) {
                self.view.layoutIfNeeded()
            }
            for polygon in polygons.keys {
                guard let renderer = mapView.renderer(for: polygon) as? MKPolygonRenderer else { continue }
                renderer.configure(color: polygons[polygon]!.color.uiColor, selected: false)
            }
            if let selectedPolygon = state.selection, let renderer = mapView.renderer(for: selectedPolygon) as? MKPolygonRenderer {
                renderer.configure(color: polygons[selectedPolygon]!.color.uiColor, selected: true)
            }
            trackInfoView.track = state.selection.flatMap { polygons[$0] }
        }
        if state.trackPosition != old.trackPosition {
            trackInfoView.position = state.trackPosition
        }
    }
    
    init() {
        state = State(tracks: [])

        super.init(nibName: nil, bundle: nil)
    }
    
    func setTracks(_ t: [Track]) {
        state.tracks = t
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .white
        
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addConstraintsToSizeToParent()
        mapView.delegate = self

        trackInfoView.delegate = self
        view.addSubview(trackInfoView)
        trackInfoView.translatesAutoresizingMaskIntoConstraints = false
        trackInfoConstraint = trackInfoView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        trackInfoConstraint.priority = .required
        let hideTrackInfoConstraint = trackInfoView.topAnchor.constraint(equalTo: view.bottomAnchor)
        hideTrackInfoConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            hideTrackInfoConstraint,
            trackInfoView.leftAnchor.constraint(equalTo: view.leftAnchor),
            trackInfoView.rightAnchor.constraint(equalTo: view.rightAnchor),
            trackInfoView.heightAnchor.constraint(equalToConstant: 120)
        ])


        loadingIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.startAnimating()
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
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
        let possibilities = polygons.keys.filter { polygon in
            guard let renderer = mapView.renderer(for: polygon) as? MKPolygonRenderer else { return false }
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
        guard let polygon = overlay as? MKPolygon else { return MKOverlayRenderer() }
        if let renderer = mapView.renderer(for: overlay) { return renderer }
        let renderer = MKPolygonRenderer(polygon: polygon)
        let isSelected = state.selection == polygon
        renderer.configure(color: polygons[polygon]!.color.uiColor, selected: isSelected || !state.hasSelection)
        return renderer
    }
        
    func changedPosition(to position: CGFloat?) {
        state.trackPosition = position
    }
}




extension MKPolygonRenderer {
    func configure(color: UIColor, selected: Bool) {
        strokeColor = color
        fillColor = selected ? color.withAlphaComponent(0.2) : color.withAlphaComponent(0.1)
        lineWidth = selected ? 3 : 1
    }
}


