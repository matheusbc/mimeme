//
//  MainViewController.swift
//  MemeMe
//
//  Created by Matheus B Campos on 17/01/18.
//  Copyright © 2018 Matheus B Campos. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class MainViewController: UIViewController, UINavigationControllerDelegate, Permissible {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var topText: UITextField!
    @IBOutlet weak var bottomText: UITextField!
    @IBOutlet weak var toolbar: UIToolbar!

    var keyboardHeight: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        let memeTextAttributes:[String:Any] = [
            NSAttributedStringKey.strokeColor.rawValue: UIColor.black,
            NSAttributedStringKey.font.rawValue: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedStringKey.strokeWidth.rawValue: 1]
        topText.defaultTextAttributes = memeTextAttributes
        bottomText.defaultTextAttributes = memeTextAttributes
        topText.textAlignment = .center
        bottomText.textAlignment = .center
        topText.textColor = UIColor.white
        bottomText.textColor = UIColor.white
        topText.delegate = self
        bottomText.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }

    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }
    
    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        if bottomText.isFirstResponder {
            self.keyboardHeight = getKeyboardHeight(notification)
            view.frame.origin.y -= self.keyboardHeight
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        if self.view.frame.origin.y != 0 {
            view.frame.origin.y += self.keyboardHeight
        }
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }


    // MARK: - Actions
    @IBAction func share(_ sender: Any) {
        // image to share
        let image = generateMemedImage()
        
        // set up activity view controller
        let imageToShare = [ image ]
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        // exclude some activity types from the list (optional)
        activityViewController.excludedActivityTypes = [ UIActivityType.airDrop, UIActivityType.postToFacebook ]
        
        // present the view controller
        self.present(activityViewController, animated: true, completion: nil)
    }

    @IBAction func cancel(_ sender: Any) {
        self.imageView.image = nil
        self.topText.text = nil
        self.bottomText.text = nil
    }

    @IBAction func openCamera(_ sender: Any) {
        cameraPermission(viewController: self) { (authorizationStatus: AVAuthorizationStatus) in
            switch authorizationStatus {
            case .authorized:
                let pickerController = UIImagePickerController()
                pickerController.delegate = self
                pickerController.sourceType = .camera
                self.present(pickerController, animated: true, completion: nil)
            default:
                print("MimeMe hasn`t camera permission.")
            }
        }
    }

    @IBAction func openAlbum(_ sender: Any) {
        photosPermission(viewController: self, completion: { (authorizationStatus: PHAuthorizationStatus) in
            switch authorizationStatus {
            case .authorized:
                let pickerController = UIImagePickerController()
                pickerController.delegate = self
                pickerController.sourceType = .photoLibrary
                self.present(pickerController, animated: true, completion: nil)
            default:
                print("MimeMe hasn`t photos permission.")
            }
        })
    }

    func generateMemedImage() -> UIImage {
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        self.toolbar.isHidden = true
        
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.toolbar.isHidden = false
        
        return memedImage
    }
}

extension MainViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imageView.contentMode = .scaleAspectFill
            self.imageView.image = image
        }
        dismiss(animated:true, completion: nil)
    }
}

extension MainViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == topText {
            bottomText.becomeFirstResponder()
            return false
        } else if textField == bottomText {
            bottomText.resignFirstResponder()
            return false
        }
        return true
    }
}

