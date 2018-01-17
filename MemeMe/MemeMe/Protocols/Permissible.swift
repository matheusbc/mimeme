//
//  Permissible.swift
//  MemeMe
//
//  Created by Matheus B Campos on 17/01/18.
//  Copyright © 2018 Matheus B Campos. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

// Defines classes that needs system permission.
protocol Permissible {}

extension Permissible {
    /**
     Checks photos permission.
     Requests photos gallery permission and shows dialog if is not granted.
     
     - Parameter completion: the fuction called when the request response arrives
     */
    func photosPermission(viewController: UIViewController,
                          completion: @escaping (_ authorizationStatus: PHAuthorizationStatus) -> Void) {
        if PHPhotoLibrary.authorizationStatus() ==  .authorized {
            completion(.authorized)
        } else {
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                if newStatus == .authorized {
                    print("Photos permission granted.")
                    completion(.authorized)
                } else {
                    print("Photos permission denied.")
                    let message = "The permission to access your photos is required."
                    self.openPermissionAlert(viewController: viewController, message: message)
                    completion(.denied)
                }
            })
        }
    }
    
    /**
     Checks camera permission.
     Requests camera permission and shows dialog if is not granted.
     
     - Parameter completion: the fuction called when the request response arrives
     */
    func cameraPermission(viewController: UIViewController,
                          completion: @escaping (_ authorizationStatus: AVAuthorizationStatus) -> Void) {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  .authorized {
            completion(.authorized)
        } else {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) in
                if granted {
                    print("Camera permission granted.")
                    completion(.authorized)
                } else {
                    print("Camera permission denied.")
                    let message = "The permission to access your camera is required."
                    self.openPermissionAlert(viewController: viewController, message: message)
                    completion(.denied)
                }
            })
        }
    }
    
    // MARK: Private functions
    /// Opens system settings menu.
    private func openSettingsMenu() {
        if let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /**
     Opens dialog alert when permission is denied
     */
    private func openPermissionAlert(viewController: UIViewController, message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            self.openSettingsMenu()
        }))
        
        DispatchQueue.main.async {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
}
