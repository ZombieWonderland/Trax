//
//  ImageViewController.swift
//  Cassini
//
//  Created by Dan Livingston  on 2/29/16.
//  Copyright © 2016 Some Peril. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate
{
    var imageURL: NSURL? {
        didSet {
            image = nil // set existing (old) image to nil
            if view.window != nil {
               fetchImage()
            }
            
        }
    }// this is the model, ie, the data
    
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    
    private func fetchImage()
    {
        if let url = imageURL {
            spinner?.startAnimating()
            let qos = QOS_CLASS_USER_INITIATED
            dispatch_async(dispatch_get_global_queue(qos, 0)) { () -> Void in
                let imageData = NSData(contentsOfURL: url)
                dispatch_async(dispatch_get_main_queue()) {
                    if url == self.imageURL {
                        if imageData != nil {
                            self.image = UIImage(data: imageData!)
                        } else {
                            self.image = nil
                        }
                    }
                }
            }
        }
    }
    
    
    @IBOutlet weak var scrollView: UIScrollView!
    {
        didSet {
            scrollView.contentSize = imageView.frame.size
            scrollView.delegate = self
            scrollView.minimumZoomScale = 0.03
            scrollView.maximumZoomScale = 1.0
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    private var imageView = UIImageView()   // creating it in code instead of via storyboard
    
    private var image: UIImage? {
        get { return imageView.image }
        set {
            imageView.image = newValue
            imageView.sizeToFit()   // changes bounds/frame to fit the new image
            
            // The "?" allows you to set image internally even if outlets
            // haven't been set yet
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating() 
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(imageView) // adding imageView to the main view of the app
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage()
        }
    }

}
