//
//  PhotoPageContainerViewController.swift
//  Kontax Cam
//
//  Created by Kevin Laminto on 2/6/20.
//  Copyright © 2020 Kevin Laminto. All rights reserved.
//

import UIKit

protocol PhotoPageContainerViewControllerDelegate: class {
    func containerViewController(_ containerViewController: PhotoPageContainerViewController, indexDidUpdate currentIndex: Int)
}

class PhotoPageContainerViewController: UIViewController {
    
    private enum ScreenMode {
        case full, normal
    }
    
    // MARK: - Variables
    private var currentMode: ScreenMode = .normal
    weak var delegate: PhotoPageContainerViewControllerDelegate?
    private var pageViewController: UIPageViewController {
        return self.children[0] as! UIPageViewController
    }
    private var currentViewController: PhotoZoomViewController {
        return self.pageViewController.viewControllers![0] as! PhotoZoomViewController
    }
    var photos: [UIImage]!
    var currentIndex = 0
    var nextIndex: Int?
    
    var panGestureRecognizer: UIPanGestureRecognizer!
    var singleTapGestureRecognizer: UITapGestureRecognizer!
    
    var transitionController = ZoomTransitionController()
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let optionsDict = [UIPageViewController.OptionsKey.interPageSpacing : 20]
        let pvc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: optionsDict)
        add(pvc)
        
        self.pageViewController.delegate = self
        self.pageViewController.dataSource = self
        
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanWith))
        self.panGestureRecognizer.delegate = self
        self.pageViewController.view.addGestureRecognizer(self.panGestureRecognizer)
        
        self.singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSingleTapWith))
        self.pageViewController.view.addGestureRecognizer(self.singleTapGestureRecognizer)
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "\(PhotoZoomViewController.self)") as! PhotoZoomViewController
        vc.delegate = self
        vc.index = self.currentIndex
        vc.image = self.photos[self.currentIndex]
        self.singleTapGestureRecognizer.require(toFail: vc.doubleTapGestureRecognizer)
        let viewControllers = [vc]
        
        self.pageViewController.setViewControllers(viewControllers, direction: .forward, animated: true, completion: nil)
    }
    
}

extension PhotoPageContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == self.currentViewController.scrollView.panGestureRecognizer {
            if self.currentViewController.scrollView.contentOffset.y == 0 {
                return true
            }
        }
        return false
    }
    
    @objc func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.currentViewController.scrollView.isScrollEnabled = false
            self.transitionController.isInteractive = true
            self.navigationController?.popViewController(animated: true)
        case .ended:
            if self.transitionController.isInteractive {
                self.currentViewController.scrollView.isScrollEnabled = true
                self.transitionController.isInteractive = false
                self.transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        default:
            if self.transitionController.isInteractive {
                self.transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        }
    }
    
    @objc func didSingleTapWith(gestureRecognizer: UITapGestureRecognizer) {
        if self.currentMode == .full {
            changeScreenMode(to: .normal)
            self.currentMode = .normal
        } else {
            changeScreenMode(to: .full)
            self.currentMode = .full
        }
        
    }
    
    private func changeScreenMode(to: ScreenMode) {
        if to == .full {
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        } else {
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
}

extension PhotoPageContainerViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        if currentIndex == 0 { return nil }
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "\(PhotoZoomViewController.self)") as! PhotoZoomViewController
        vc.delegate = self
        vc.image = self.photos[currentIndex - 1]
        vc.index = currentIndex - 1
        self.singleTapGestureRecognizer.require(toFail: vc.doubleTapGestureRecognizer)
        return vc
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        if currentIndex == (self.photos.count - 1) { return nil }
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "\(PhotoZoomViewController.self)") as! PhotoZoomViewController
        vc.delegate = self
        self.singleTapGestureRecognizer.require(toFail: vc.doubleTapGestureRecognizer)
        vc.image = self.photos[currentIndex + 1]
        vc.index = currentIndex + 1
        return vc
        
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
        guard let nextVC = pendingViewControllers.first as? PhotoZoomViewController else { return }
        self.nextIndex = nextVC.index
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if (completed && self.nextIndex != nil) {
            previousViewControllers.forEach { vc in
                let zoomVC = vc as! PhotoZoomViewController
                zoomVC.scrollView.zoomScale = zoomVC.scrollView.minimumZoomScale
            }
            
            self.currentIndex = self.nextIndex!
            self.delegate?.containerViewController(self, indexDidUpdate: self.currentIndex)
        }
        
        self.nextIndex = nil
    }
    
}

extension PhotoPageContainerViewController: PhotoZoomViewControllerDelegate {
    
    func photoZoomViewController(_ photoZoomViewController: PhotoZoomViewController, scrollViewDidScroll scrollView: UIScrollView) {
        
        if scrollView.zoomScale != scrollView.minimumZoomScale && self.currentMode != .full {
            self.changeScreenMode(to: .full)
            self.currentMode = .full
        }
    }
}

extension PhotoPageContainerViewController: ZoomAnimatorDelegate {
    
    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {
    }
    
    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {
    }
    
    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        return self.currentViewController.imageView
    }
    
    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        return self.currentViewController.scrollView.convert(self.currentViewController.imageView.frame, to: self.currentViewController.view)
    }
}
