//
//  AppDelegate.swift
//  Trax
//
//  Created by Dan Livingston  on 3/9/16.
//  Copyright © 2016 Some Peril. All rights reserved.
//

import UIKit

struct GPXURL {
    static let Notification = "GPXURL Radio Station"
    static let Key = "GPX URL Key"
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?       // never delete this
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        
        // this setts up a radio station that the rest of the app can listen to, to see if a URL got dropped
        let center = NSNotificationCenter.defaultCenter()
        let notification = NSNotification(name: GPXURL.Notification, object: self, userInfo: [GPXURL.Key:url])
        center.postNotification(notification)
        return true
    }


}

