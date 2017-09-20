//
//  Incremental+NSObject.swift
//  Incremental
//
//  Created by Chris Eidhof on 18.09.17.
//  Copyright © 2017 objc.io. All rights reserved.
//

import Foundation


// Could this be in a conditional block? Only works for Foundation w/ ObjC runtime
extension NSObjectProtocol where Self: NSObject {
    public subscript<Value>(_ keyPath: KeyPath<Self, Value>) -> I<Value> where Value: Equatable {
        let i: I<Value> = I(value: self[keyPath: keyPath])
        let observation = observe(keyPath) { (obj, change) in
            i.write(obj[keyPath: keyPath])
        }
        i.strongReferences.add(observation)
        return i
    }
}

public final class IBox<V> {
    public private(set) var unbox: V
    var disposables: [Any] = []
    
    public init(_ object: V) {
        self.unbox = object
    }
    
    public func bind<A>(_ value: I<A>, to: WritableKeyPath<V,A>) {
        disposables.append(value.observe { [unowned self] in
            self.unbox[keyPath: to] = $0
        })
    }
    
    public func bind<A>(_ value: I<A>, to: WritableKeyPath<V,A?>) where A: Equatable {
        disposables.append(value.observe { [unowned self] in
            self.unbox[keyPath: to] = $0
        })
    }
    
    public func observe<A>(value: I<A>, onChange: @escaping (V,A) -> ()) {
        disposables.append(value.observe { newValue in
            onChange(self.unbox,newValue) // ownership?
        })
    }
}
extension IBox where V: NSObject {
    public subscript<A>(keyPath: KeyPath<V,A>) -> I<A> where A: Equatable {
        get {
            return unbox[keyPath]
        }
    }
}

extension NSObjectProtocol where Self: NSObject {
    /// One-way binding
    public func bind<Value>(keyPath: ReferenceWritableKeyPath<Self, Value>, _ i: I<Value>) -> Disposable {
        return i.observe {
            self[keyPath: keyPath] = $0
        }
    }
}

extension IBox where V: UIView {
    public func addSubview<S>(_ subview: IBox<S>) where S: UIView {
        disposables.append(subview)
        unbox.addSubview(subview.unbox)
    }
}

extension IBox where V == UIStackView {
    public convenience init<S>(arrangedSubviews: [IBox<S>]) where S: UIView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews.map { $0.unbox })
        self.init(stackView)
        disposables.append(arrangedSubviews)
    }
}
