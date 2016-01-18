//
//  ViewController.swift
//  Act Accordingly
//
//  Created by Matt Doyle on 22/12/2015.
//  Copyright © 2015 llumicode. All rights reserved.
//  Matt, go to http://www.colorhunt.co/c/3986 for the pallet.
//

import UIKit
import Parse
import FBSDKCoreKit
import FBSDKLoginKit
import ParseFacebookUtilsV4

class ViewController: UIViewController {
    
    deinit {
        NSUserDefaults.standardUserDefaults().removeObserver(self, forKeyPath: "usersDaysRemainingCommaSeparated", context: nil)
    }
    
    // IBOutlets
    @IBOutlet weak var dashMessage: UILabel!
    @IBOutlet weak var nameHeader: UILabel!
    @IBOutlet weak var lifeExpNumber: UILabel!
    @IBOutlet weak var daysLeftNumber: UILabel!
    @IBOutlet weak var profilePictureView: UIImageView!
    
    // IBActions
    @IBAction func logOutDidPress(sender: AnyObject) {
        
        NSUserDefaults.standardUserDefaults().removePersistentDomainForName("group.llumicode.TodayExtensionSharingDefaults2")
        
        if Reachability.isConnectedToNetwork() == true {
            
            PFUser.logOut()
            
        } else {
            
            PFUser.logOutInBackground()
            
        }
    
        self.performSegueWithIdentifier("notLoggedIn", sender: self)
        
    }
    
    @IBAction func editDidPress(sender: AnyObject) {
        
        if Reachability.isConnectedToNetwork() == true {
            
            performSegueWithIdentifier("editSegue", sender: self)
            
        } else {
            let alert = UIAlertView(title: "Hmm, we can't find a network connection", message: "Profile currently unavailable.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if Reachability.isConnectedToNetwork() == true {
            // Internet connection okay
        } else {
            let alert = UIAlertView(title: "Hmm, we can't find a network connection", message: "Make sure your device is connected to the internet.", delegate: nil, cancelButtonTitle: "OK")
            alert.show()
        }
        
        // Load user defaults
        let defaults = NSUserDefaults(suiteName: "group.llumicode.TodayExtensionSharingDefaults2")
        defaults?.synchronize()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "defaultsChanged:", name: NSUserDefaultsDidChangeNotification, object: nil)
        
        // Watch for changes in user profile
        FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "onProfileUpdated:", name: FBSDKProfileDidChangeNotification, object: nil)
        
    }
    
    func defaultsChanged(notification:NSNotification){
        
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            //User is logged in, so do things with all of the data.
            updateDashText()
            
        } else {
            // User is not logged in
        }
        
    }
    
    func loadFbImage() {
        
        PFUser.currentUser()?.fetchInBackgroundWithBlock({ (user, error) -> Void in
            
            if error == nil {
                
                let defaults = NSUserDefaults(suiteName: "group.llumicode.TodayExtensionSharingDefaults2")
                
                let fbPic = FBSDKProfile.imageURLForPictureMode(FBSDKProfile.currentProfile())
                let fbPicUrl = fbPic(FBSDKProfilePictureMode.Square, size: CGSizeMake(200, 200))
                
                let request: NSURLRequest = NSURLRequest(URL: fbPicUrl)
                
                let session = NSURLSession.sharedSession()
                let task = session.dataTaskWithRequest(request){
                    (data, response, error) -> Void in
                    
                    if (error == nil && data != nil)
                    {
                        func saveFbImageToParseAndDefaults()
                        {
                            
                            let file = PFFile(name: "profilePicture.png", data: data!)
                            user?["profilePicture"] = file
                            user?.saveInBackground()
                            
                            defaults!.setObject(data, forKey: "profilePicture")
                            defaults?.synchronize()
                            
                            if let image = UIImage(data:defaults?.objectForKey("profilePicture") as! NSData) {
                                
                                self.profilePictureView.image = image
                                
                            }
                            
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), saveFbImageToParseAndDefaults)
                    }
                    
                }
                
                task.resume()
                
            }
            
        })
        

        
    }
    
    // Function runs when users profile changes
    func onProfileUpdated(notification: NSNotification) {
        
        

    }
    
    func updateDashText () {
        
        let defaults = NSUserDefaults(suiteName: "group.llumicode.TodayExtensionSharingDefaults2")
        defaults?.synchronize()
        
        if defaults?.stringForKey("usersDaysRemaining") != nil && defaults?.stringForKey("totalDaysInLifetime") != nil {
            
            let firstName = defaults?.stringForKey("firstName")
            let lastName = defaults?.stringForKey("lastName")
            let totalDaysInLifetime = defaults?.integerForKey("totalDaysInLifetime")
            let lifeExp = totalDaysInLifetime! / 365
            let usersDaysRemaining = defaults?.stringForKey("usersDaysRemaining")
            self.nameHeader.text = firstName! + " " + lastName!
            self.lifeExpNumber.text = String(lifeExp)
            self.daysLeftNumber.text = usersDaysRemaining
            
            let textString = String(firstName!) + ", you're expected to live to " + String(lifeExp) + ", that's " + String(usersDaysRemaining!) + " days to do everything you'll ever do. Make them count!"
            
            self.dashMessage.text = textString
            
        }
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        let defaults = NSUserDefaults(suiteName: "group.llumicode.TodayExtensionSharingDefaults2")
        defaults?.synchronize()
        
        // Check if user logged in
        if (FBSDKAccessToken.currentAccessToken() != nil) {
            
            //User is logged in, so do things with all of the data.
            if defaults?.boolForKey("isNew") == true {
                
                performSegueWithIdentifier("editSegue", sender: self)
                
            }
            
            // Get image from user defaults
            if let _ = FBSDKProfile.currentProfile() {
                
                calulateUsersDaysRemaining()
                
                
                if let image = UIImage(data:defaults?.objectForKey("profilePicture") as! NSData) {
                    
                    profilePictureView.image = image
                    
                } else {
                    
                    loadFbImage()
                    
                }
                
            }
            
            updateDashText()
            
        } else {
            // User is not logged in
            self.performSegueWithIdentifier("notLoggedIn", sender: self)
        }
        
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

