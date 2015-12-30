//
//  SmartRefresher.swift
//  Demo
//
//  Created by MORITANAOKI on 2015/12/30.
//  Copyright © 2015年 molabo. All rights reserved.
//

import UIKit

public extension UIScrollView {
    public func smr_addSmartRefresher(refresher: SmartRefresher) {
        insertSubview(refresher, atIndex: 0)
        
        refresher.setup(self)
    }
    
    public func smr_removeSmatrRefresher() {
        guard let refreshers = findRefreshers() where refreshers.count > 0 else { return }
        refreshers.forEach {
                $0.removeFromSuperview()
        }
    }
    
    public func smr_endRefreshing() {
        findRefreshers()?.forEach {
            $0.endRefresh()
        }
    }
    
    private func findRefreshers() -> [SmartRefresher]? {
        return subviews.filter { $0 is SmartRefresher }.flatMap { $0 as? SmartRefresher }
    }
}

public enum SmartRefresherState {
    case None
    case Loading
}

public typealias SmartRefresherRefreshHandler = ((refresher: SmartRefresher) -> Void)

private let DEFAULT_HEIGHT: CGFloat = 44.0

public class SmartRefresher: UIView {
    private weak var scrollView: UIScrollView?
    public var state = SmartRefresherState.None
    private var refreshedHandler: SmartRefresherRefreshHandler?
    private var contentInset = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: 0.0)
    private var contentOffset = CGPoint.zero
    private var distanceOffset: CGPoint {
        return CGPoint(x: contentInset.left + contentOffset.x, y: contentInset.top + contentOffset.y)
    }
    
    public var height: CGFloat = DEFAULT_HEIGHT
    
    deinit {
        guard let scrollView = scrollView else { return }
        scrollView.removeObserver(self, forKeyPath: "contentOffset")
        scrollView.removeObserver(self, forKeyPath: "contentInset")
    }
    
    public func setup(scrollView: UIScrollView?) {
        guard let scrollView = scrollView else { return }
        self.scrollView = scrollView
        let options: NSKeyValueObservingOptions = [.Initial, .New]
        scrollView.addObserver(self, forKeyPath: "contentOffset", options: options, context: nil)
        scrollView.addObserver(self, forKeyPath: "contentInset", options: options, context: nil)
        
        let origin = CGPoint.zero
        let size = CGSize(width: UIScreen.mainScreen().bounds.width, height: height)
        frame = CGRect(origin: origin, size: size)
        backgroundColor = .redColor()
    }
    
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        guard let scrollView = scrollView else { return }
        guard let keyPath = keyPath else { return }
        guard let change = change else { return }
        guard let _ = object else { return }
        
        if keyPath == "contentInset" {
            if let value = change["new"] as? NSValue {
                contentInset = value.UIEdgeInsetsValue()
                print("change contentInset: \(contentInset)")
            }
        }
        
        if keyPath == "contentOffset" {
            if let value = change["new"] as? NSValue {
                contentOffset = value.CGPointValue()
                print("change contentOffset: \(contentOffset)")
            }
        }
        
        frame.origin.y = distanceOffset.y
        
        print("distanceOffset: \(distanceOffset)")
        if scrollView.dragging && distanceOffset.y < -height {
            startRefresh()
        }
        
        print("keyPath: \(keyPath)")
        print("object: \(object)")
        print("change: \(change)")
        print("distanceOffset: \(distanceOffset)")
        print("y: \(frame.origin.y)")
        print("END-------")
    }
    
    private func startRefresh() {
        if state == .Loading { return }
        state = .Loading
        guard let scrollView = scrollView else { return }
        print("before: \(scrollView.contentOffset.y)")
        scrollView.contentInset.top = scrollView.contentInset.top + height
        print("after: \(scrollView.contentOffset.y)")
        refreshedHandler?(refresher: self)
    }
    
    private func endRefresh() {
        if state == .None { return }
        state = .None
        guard let scrollView = scrollView else { return }
        scrollView.contentInset.top = scrollView.contentInset.top - height
        refreshedHandler?(refresher: self)
    }
    
    public func addRefreshHandler(handler: SmartRefresherRefreshHandler) {
        refreshedHandler = handler
    }
}
