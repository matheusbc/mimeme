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
    @IBOutlet weak var cameraButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.configure(textField: topText)
        self.configure(textField: bottomText)
        self.configureCamera()
    }

    private func configure(textField: UITextField) {
        let memeTextAttributes:[String:Any] = [
            NSAttributedStringKey.strokeColor.rawValue: UIColor.black,
            NSAttributedStringKey.font.rawValue: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedStringKey.strokeWidth.rawValue: -3.0]
        textField.defaultTextAttributes = memeTextAttributes
        textField.textAlignment = .center
        textField.textColor = UIColor.white
        textField.delegate = self
    }

    private func configureCamera() {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            self.cameraButton.isEnabled = false
        }
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
        NotificationCenter.default.removeObserver(self)
    }

    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: .UIKeyboardWillHide, object: nil)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        if bottomText.isFirstResponder {
            let keyboardHeight = getKeyboardHeight(notification)
            view.frame.origin.y = -keyboardHeight
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        if self.view.frame.origin.y != 0 {
            view.frame.origin.y = 0
        }
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }

    func presentImagePickerWith(sourceType: UIImagePickerControllerSourceType) {
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.sourceType = sourceType
        self.present(pickerController, animated: true, completion: nil)
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

        activityViewController.completionWithItemsHandler = { (activityType: UIActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) -> Void in
            if completed {
                // Save image
                _ = Meme(topText: self.topText.text!, bottomText: self.bottomText.text!, originalImage: self.imageView.image!, memedImage: image)
            }
        }
        
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
                self.presentImagePickerWith(sourceType: .camera)
            default:
                print("MimeMe hasn`t camera permission.")
            }
        }
    }

    @IBAction func openAlbum(_ sender: Any) {
        photosPermission(viewController: self, completion: { (authorizationStatus: PHAuthorizationStatus) in
            switch authorizationStatus {
            case .authorized:
                self.presentImagePickerWith(sourceType: .photoLibrary)
            default:
                print("MimeMe hasn`t photos permission.")
            }
        })
    }

    func hideTopAndBottomBars(_ hide: Bool) {
        self.navigationController?.setNavigationBarHidden(hide, animated: false)
        self.toolbar.isHidden = hide
    }

    func generateMemedImage() -> UIImage {
        hideTopAndBottomBars(true)

        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        hideTopAndBottomBars(false)

        return memedImage
    }
}

extension MainViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imageView.contentMode = .scaleAspectFit
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

