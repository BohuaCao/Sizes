//
//  SizesWindow.swift
//  Pods-Sizes_Example
//
//  Created by Bahadir Oncel on 14.10.2018.
//

import UIKit

open class SizesWindow: UIWindow {
    
    /// SizesViewController that will update the contained view
    public let sizesViewController = SizesViewController()
    
    /// Window to display the configuration UI
    private let configurationWindow: UIWindow
    
    private var panGesture: UIPanGestureRecognizer!
    
    /// Public API
    open var shakeGestureEnabled: Bool = true
    
    override open var rootViewController: UIViewController? {
        get {
            return sizesViewController.containedController
        }
        set {
            guard let root = newValue, !root.isKind(of: SizesViewController.self) else {
                return
            }
            super.rootViewController = sizesViewController
            sizesViewController.contain(viewController: root)
        }
    }
    
    public init() {
        let configurationController = ConfigurationViewController()
        let screenBounds = UIScreen.main.bounds
        let configurationViewHeight = configurationController.view.bounds.height
        configurationWindow = UIWindow(frame: CGRect(x: 0, y: screenBounds.height, width: 375, height: configurationViewHeight))
        configurationWindow.backgroundColor = .clear
        configurationWindow.windowLevel = .alert
        configurationWindow.rootViewController = configurationController
        configurationWindow.makeKeyAndVisible()
        
        super.init(frame: UIScreen.main.bounds)
        clipsToBounds = true
        configurationController.update = { [unowned self] orientation, device, textSize in
            self.sizesViewController.debug(device: device, orientation: orientation, contentSize: textSize)
        }
        configurationController.takeScreenshot = { [unowned self] in
            if let screenshot = self.sizesViewController.generateScreenshot() {
                self.shareImage(screenshot)
            }
        }
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(dragged(_:)))
        configurationWindow.addGestureRecognizer(panGesture)
        panGesture.cancelsTouchesInView = false
        panGesture.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Enable detection of shake motion
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            if shakeGestureEnabled {
                presentConfiguration()
            }
        }
    }

    /// Manually present the configuration view
    public func presentConfiguration() {
        let frame = configurationWindow.frame
        DispatchQueue.main.async { [unowned self] in
            UIView.animate(withDuration: 1, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0, options: .curveEaseOut, animations: {
                self.configurationWindow.frame.origin.y = UIScreen.main.bounds.height - frame.height
            }, completion: nil)
        }
    }
    
    @objc func dragged(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: sender.view)
        let velocity = sender.velocity(in: sender.view)
        switch sender.state {
        case .changed:
            if translation.y > 0 {
                let initialOriginY = UIScreen.main.bounds.height - configurationWindow.frame.height
                configurationWindow.frame.origin.y = initialOriginY + translation.y
            }
        case .cancelled, .ended:
            let percentageComplete = translation.y / configurationWindow.frame.height
            let shouldDismiss = percentageComplete > 0.5 || velocity.y > 10
            let yMovement = shouldDismiss ? UIScreen.main.bounds.height : UIScreen.main.bounds.height - configurationWindow.frame.height
            UIView.animate(withDuration: 0.3, animations: {
                self.configurationWindow.frame.origin.y = yMovement
            }, completion: nil)
        default: break
        }
    }
    
    private func shareImage(_ image: UIImage) {
        // set up activity view controller
        let imageToShare = [image]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)

        //If info.plist does not have declared that it supports adding to Photo Library, remove the share option
        if Bundle.main.object(forInfoDictionaryKey: "NSPhotoLibraryAddUsageDescription") == nil {
            print("To enable save to Camera Roll add NSPhotoLibraryAddUsageDescription in your info.plist")
            activityViewController.excludedActivityTypes = [UIActivity.ActivityType.saveToCameraRoll]
        }
        
        let containerController = UIViewController()
        containerController.view.backgroundColor = .clear

        activityViewController.popoverPresentationController?.sourceView = containerController.view // so that iPads won't crash

        let shareWindow = UIWindow(frame: UIScreen.main.bounds)
        shareWindow.backgroundColor = .clear
        shareWindow.windowLevel = .alert
        shareWindow.makeKeyAndVisible()
        shareWindow.rootViewController = containerController
        
        activityViewController.completionWithItemsHandler = { _, _, _, _ in
            shareWindow.removeFromSuperview()
        }
        // present the view controller
//        sizesViewController.present(activityViewController, animated: true, completion: nil)
        containerController.present(activityViewController, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension SizesWindow: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let view = touch.view else {
            return true
        }
        
        return !view.isKind(of: UIButton.self)
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

