//
//  Views.swift
//  Laufpark
//
//  Created by Chris Eidhof on 17.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import UIKit
import Incremental
import MapKit

final class TrackInfoView {
    private var lineView: ViewBox<LineView>
    var view: UIView! = nil
    let totalAscent = UILabel()
    let totalDistance = UILabel()
    let name = UILabel()
    var disposables: [Any] = []
    
    // 0...1.0
    var pannedLocation: I<CGFloat> {
        return _pannedLocation.i
    }
    private var _pannedLocation: Var<CGFloat> = Var(0)
    
    init(position: I<CGFloat?>, points: I<[CGPoint]>, pointsRect: I<CGRect>, track: I<Track?>, darkMode: I<Bool>) {
        let blurredViewForeground: I<UIColor> = if_(darkMode, then: I(constant: .white), else: I(constant: .black))
        self.lineView = buildLineView(position: position, points: points, pointsRect: pointsRect, strokeColor: blurredViewForeground)

        
        // Lineview
        lineView.view.heightAnchor.constraint(equalToConstant: 100).isActive = true
        lineView.view.backgroundColor = .clear
        lineView.view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(linePanned(sender:))))
        
        // Track information
        let trackInfoLabels = [
            name,
            totalDistance,
            totalAscent
        ]
        let trackInfo = UIStackView(arrangedSubviews: trackInfoLabels)
        trackInfo.axis = .horizontal
        trackInfo.distribution = .equalCentering
        trackInfo.heightAnchor.constraint(equalToConstant: 20)
        trackInfo.spacing = 10
        for s in trackInfoLabels {
            s.backgroundColor = .clear
        }
        disposables.append(blurredViewForeground.observe { color in
            trackInfoLabels.forEach { l in
                l.textColor = color
            }
        })
        
        let blurEffect = if_(darkMode, then: UIBlurEffect(style: .dark), else: UIBlurEffect(style: .light))
        let blurredView = UIVisualEffectView(effect: nil)
        disposables.append(blurEffect.observe { effect in
            UIView.animate(withDuration: 0.2) {
                blurredView.effect = effect
            }
        })
        blurredView.translatesAutoresizingMaskIntoConstraints = false
        
        let stackView = UIStackView(arrangedSubviews: [trackInfo, lineView.view])
        blurredView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.addConstraintsToSizeToParent(spacing: 10)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        disposables.append(name.bind(keyPath: \UILabel.text, track.map { $0?.name }))
        
        let formatter = MKDistanceFormatter()
        disposables.append(totalDistance.bind(keyPath: \.text, track.map { track in
            track.map { formatter.string(fromDistance: $0.distance) }
        }))
        disposables.append(totalAscent.bind(keyPath: \.text, track.map { track in
            track.map { "↗ \(formatter.string(fromDistance: $0.ascent))" }
        }))
        
        view = blurredView
    }
    
    @objc func linePanned(sender: UIPanGestureRecognizer) {
        let normalizedLocation = (sender.location(in: lineView.view).x /
            lineView.view.bounds.size.width).clamped(to: 0.0...1.0)
        _pannedLocation.set(normalizedLocation)
    }
}

final class ViewBox<V: UIView> {
    let view: V
    var disposables: [Any] = []
    init(_ view: V = V()) {
        self.view = view
    }
    
    func bind<A>(_ value: I<A>, to: ReferenceWritableKeyPath<V,A>) {
        disposables.append(view.bind(keyPath: to, value))
    }
    
    func bind<A>(_ value: I<A>, to: ReferenceWritableKeyPath<V,A?>) where A: Equatable {
        disposables.append(view.bind(keyPath: to, value.map { $0 }))
    }
    
    func observe<A>(value: I<A>, onChange: @escaping (V,A) -> ()) {
        disposables.append(value.observe { newValue in
            onChange(self.view,newValue) // ownership?
        })
    }
    
    subscript<A>(keyPath: KeyPath<V,A>) -> I<A> where A: Equatable {
        let t = Var<A>(view[keyPath: keyPath]) // todo lifetime should be tied to I's lifetime
        disposables.append(view.observe(keyPath, options: .new, changeHandler: { m, _ in
            t.set(m[keyPath: keyPath])
        }))
        return t.i
        
    }
}

func button(type: UIButtonType = .custom, title: I<String>, backgroundColor: I<UIColor>, titleColor: I<UIColor>) -> ViewBox<UIButton> {
    let result = ViewBox<UIButton>(UIButton(type: type))
    result.bind(backgroundColor, to: \.backgroundColor)
    result.observe(value: title, onChange: { $0.setTitle($1, for: .normal) })
    result.observe(value: titleColor, onChange: { $0.setTitleColor($1, for: .normal)})
    result.view.layer.cornerRadius = 5
    return result
}

func buildMapView() -> ViewBox<MKMapView> {
    let box = ViewBox<MKMapView>()
    let view = box.view
    view.showsCompass = true
    view.showsScale = true
    view.showsUserLocation = true
    view.mapType = .standard
    return box
}

final class PolygonRenderer {
    let renderer: MKPolygonRenderer
    var disposables: [Disposable] = []
    
    init(polygon: MKPolygon, strokeColor: I<UIColor>, alpha: I<CGFloat>, lineWidth: I<CGFloat>) {
        renderer = MKPolygonRenderer(polygon: polygon)
        disposables.append(renderer.bind(keyPath: \.strokeColor, strokeColor.map { $0 }))
        disposables.append(renderer.bind(keyPath: \.alpha, alpha))
        disposables.append(renderer.bind(keyPath: \.lineWidth, lineWidth))
    }
}

final class PointAnnotation {
    let annotation: MKPointAnnotation
    let disposable: Any
    init(_ location: I<CLLocationCoordinate2D>) {
        let annotation = MKPointAnnotation()
        self.annotation = annotation
        disposable = location.observe {
            annotation.coordinate = $0
        }
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

func buildLineView(position: I<CGFloat?>, points: I<[CGPoint]>, pointsRect: I<CGRect>, strokeColor: I<UIColor>) -> ViewBox<LineView> {
    let box = ViewBox<LineView>()
    box.bind(position, to: \LineView.position)
    box.bind(points, to: \.points)
    box.bind(pointsRect, to: \.pointsRect)
    box.bind(strokeColor, to: \.strokeColor)
    return box
}
