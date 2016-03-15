//
//  ViewController.swift
//  Trax
//
//  Created by Dan Livingston  on 3/9/16.
//  Copyright © 2016 Some Peril. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.mapType = .Satellite
            mapView.delegate = self
        }
        
    }
    
    // Public API. Someone hands off a URL, and this app displays waypoints and tracks.
    var gpxURL: NSURL? {
        didSet {
            clearWaypoints()
            if let url = gpxURL {
                GPX.parse(url) {
                    if let gpx = $0 {
                        self.handleWaypoints(gpx.waypoints)
                    }
                }
            }
        }
    }
    
    private func clearWaypoints () {
        if mapView?.annotations != nil {
            mapView.removeAnnotations(mapView.annotations as [MKAnnotation])
        }
    }
    
    private func handleWaypoints(waypoints: [GPX.Waypoint]) {
        mapView.addAnnotations(waypoints)
        mapView.showAnnotations(waypoints, animated: true)
    }
    

    @IBAction func addWaypoint(sender: UILongPressGestureRecognizer)
    {
        if sender.state == UIGestureRecognizerState.Began {
            // convertPoint() translates a CGPoint to a CLLocationCoordinate2D
            // We do this becasue the map uses CLLocationCoordinate2D
            // but the gestureRecognizer sends us a CGPoint
            let coordinate = mapView.convertPoint(sender.locationInView(mapView), toCoordinateFromView: mapView)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "Dropped"
            //waypoint.links.append(GPX.Link(href: "http://cs193p.stanford.edu/Images/Panorama.jpg"))
            mapView.addAnnotation(waypoint)
        }
    }
    
    
    // MARK: - Constants
    
    private struct Constants {
        static let PartialTrackColor = UIColor.greenColor()
        static let FullTrackcolor = UIColor.blueColor().colorWithAlphaComponent(0.5)
        static let TrackLineWidth: CGFloat = 3.0
        static let ZoomCooldown = 1.5
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59)
        static let AnnotationViewReuseIdentifier = "waypoint"
        static let ShowImageSegue = "Show Image"
        static let EditWaypointSegue = "Edit Waypoint"
        static let EditWaypointPopoverWidth: CGFloat = 320
    }
    
    //
    //  Pin being created (not callout)
    //
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var view = mapView.dequeueReusableAnnotationViewWithIdentifier(Constants.AnnotationViewReuseIdentifier)
        
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view!.canShowCallout = true
        } else {
            view!.annotation = annotation
        }
        
        
        
        // Just a way to avoid using "view?" in the code below
        if let pinView = view {
            
            pinView.draggable = annotation is EditableWaypoint
            
            pinView.leftCalloutAccessoryView = nil
            pinView.rightCalloutAccessoryView = nil
            
            if let waypoint = annotation as? GPX.Waypoint {
                
                if waypoint.thumbnailURL != nil {
                    pinView.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
                }
                
                // also works for "if annotation is EditableWaypoint"
                if waypoint is EditableWaypoint {
                    pinView.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
                }
            }
            return pinView
        } else {
            return view     // this is nil
        }

    }
    
    // 
    //  user taps pin, callout created
    //
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        // There could be non-Waypoint annotations out there
        // We only care if it is a Waypoint annotation
        if let waypoint = view.annotation as? GPX.Waypoint {
            if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton {
                if let imageData = NSData(contentsOfURL: waypoint.thumbnailURL!) { // blocks main thread!
                    if let image = UIImage(data: imageData) {
                        thumbnailImageButton.setImage(image, forState: .Normal)
                    }
                }
            }
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if (control as? UIButton)?.buttonType == UIButtonType.DetailDisclosure {
            // edit the waypoint
            mapView.deselectAnnotation(view.annotation, animated: false)
            performSegueWithIdentifier(Constants.EditWaypointSegue, sender: view)
        } else if let waypoint = view.annotation as? GPX.Waypoint {
            if waypoint.imageURL != nil {
                performSegueWithIdentifier(Constants.ShowImageSegue, sender: view)
            }
            
        }
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.ShowImageSegue {
            if let waypoint = (sender as? MKAnnotationView)?.annotation as? GPX.Waypoint {
                if let ivc = segue.destinationViewController.contentViewController as? ImageViewController {
                    ivc.imageURL = waypoint.imageURL
                    ivc.title = waypoint.title
                }
            }
        } else if segue.identifier == Constants.EditWaypointSegue {
            if let waypoint = (sender as? MKAnnotationView)?.annotation as? EditableWaypoint {
                if let ewvc = segue.destinationViewController.contentViewController as? EditWaypointViewController {
                    if let ppc = ewvc.popoverPresentationController {
                        let coordinatePoint = mapView.convertCoordinate(waypoint.coordinate, toPointToView: mapView)
                        ppc.sourceRect = (sender as! MKAnnotationView).popoverSourceRectForCoordinatePoint(coordinatePoint)
                        let minimumSize = ewvc.view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
                        ewvc.preferredContentSize = CGSize(width: Constants.EditWaypointPopoverWidth, height: minimumSize.height)
                        ppc.delegate = self
                    }
                    ewvc.waypointToEdit = waypoint
                }
            }
        }        
    }
    
    // Called when system is adapting to something (I think)
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.OverFullScreen
    }
    
    // add in Done button for iPhone by showing Navigation View Controller
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navcon =  UINavigationController(rootViewController: controller.presentedViewController)
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))
        
        visualEffectView.frame = navcon.view.bounds
        navcon.view.insertSubview(visualEffectView, atIndex: 0)
        
        return navcon
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = NSNotificationCenter.defaultCenter()
        let queue = NSOperationQueue.mainQueue()
        let appDelegate = UIApplication.sharedApplication().delegate
        
        // this will be called every time the radio station named GPXURL.Notification broadcasts
        center.addObserverForName(GPXURL.Notification, object: appDelegate, queue: queue) { notification in
            if let url = notification.userInfo?[GPXURL.Key] as? NSURL {
                self.gpxURL = url
            }
        }
        
        gpxURL = NSURL(string: "http://cs193p.stanford.edu/Vacation.gpx")
    }

}

extension UIViewController
{
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController!
        } else {
            return self
        }
    }
}

extension MKAnnotationView {
    func popoverSourceRectForCoordinatePoint(coordinatePoint: CGPoint) -> CGRect {
        var popoverSourceRectCenter = coordinatePoint
        popoverSourceRectCenter.x -= frame.width/2 - centerOffset.x - calloutOffset.x
        popoverSourceRectCenter.y -= frame.height/2 - centerOffset.y - calloutOffset.y
        return CGRect(origin: popoverSourceRectCenter, size: frame.size)
    }
}

