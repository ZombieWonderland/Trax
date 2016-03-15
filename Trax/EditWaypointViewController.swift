//
//  EditWaypointViewController.swift
//  Trax
//
//  Created by Dan Livingston  on 3/11/16.
//  Copyright © 2016 Some Peril. All rights reserved.
//

import UIKit
import MobileCoreServices

class EditWaypointViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{

    // this is the model
    var waypointToEdit: EditableWaypoint? { didSet { updateUI() } }
    
    @IBOutlet weak var nameTextField: UITextField! { didSet { nameTextField.delegate = self } }
    @IBOutlet weak var infoTextField: UITextField! { didSet { infoTextField.delegate = self } }
    
    func updateUI() {
        // Update text fields (UI) with data from the waypoint (model)
        nameTextField?.text = waypointToEdit?.name
        infoTextField?.text = waypointToEdit?.info
        updateImage()
    }
    
    
    @IBAction func done(sender: UIBarButtonItem) {
        presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        observeTextFields()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameTextField.becomeFirstResponder()
        updateUI()
    }
    
    // get rid of text field observers
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        if let observer = nameTextFieldObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
        if let observer = infoTextFieldObserver {
            NSNotificationCenter.defaultCenter().removeObserver(observer)
        }
        
    }
    
    // MARK: - Images
    
    var imageView = UIImageView()
    
    
    @IBOutlet weak var imageViewContainer: UIView! {
        didSet {
            imageViewContainer.addSubview(imageView)
        }
    }
    
    @IBAction func takePhoto()
    {
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .Camera
            picker.mediaTypes = [kUTTypeImage as String]
            picker.delegate = self
            picker.allowsEditing = true
            presentViewController(picker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        var image = info[UIImagePickerControllerEditedImage] as? UIImage
        if image == nil {
            image = info[UIImagePickerControllerOriginalImage] as? UIImage
        }
        
        imageView.image = image
        makeRoomForImage()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    // MARK: - Text fields
    
    // these are just cookies
    var nameTextFieldObserver: NSObjectProtocol?
    var infoTextFieldObserver: NSObjectProtocol?
    
    func observeTextFields() {
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        nameTextFieldObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: nameTextField, queue: queue) { notification in
            if let waypoint = self.waypointToEdit {
                waypoint.name = self.nameTextField.text
            }
        }
        infoTextFieldObserver = center.addObserverForName(UITextFieldTextDidChangeNotification, object: infoTextField, queue: queue) { notification in
            if let waypoint = self.waypointToEdit {
                waypoint.info = self.infoTextField.text
            }
        }
    }
    

    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

}

extension EditWaypointViewController
{
    func updateImage() {
        if let url = waypointToEdit?.imageURL {
            let qos = QOS_CLASS_USER_INITIATED
            dispatch_async(dispatch_get_global_queue(qos, 0)) { [weak self] in
                if let imageData = NSData(contentsOfURL: url) {
                    //if url == self?.waypointToEdit?.imageURL {
                        if let image = UIImage(data: imageData) {
                            dispatch_async(dispatch_get_main_queue()) {
                                self?.imageView.image = image
                                self?.makeRoomForImage()
                            }
                        }
                    //}
                }
            }
        }
    }
    
    func makeRoomForImage() {
        var extraHeight: CGFloat = 0
        if imageView.image?.aspectRatio > 0 {
            if let width = imageView.superview?.frame.size.width {
                let height = width / imageView.image!.aspectRatio
                extraHeight = height - imageView.frame.height
                imageView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            }
        } else {
            extraHeight = -imageView.frame.height
            imageView.frame = CGRectZero
        }
        preferredContentSize = CGSize(width: preferredContentSize.width, height: preferredContentSize.height + extraHeight)
    }
}

extension UIImage {
    var aspectRatio: CGFloat {
        return size.height != 0 ? size.width / size.height: 0
    }
}




