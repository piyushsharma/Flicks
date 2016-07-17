//
//  MoviesViewController.swift
//  Flicks
//
//  Created by Piyush Sharma on 7/16/16.
//  Copyright © 2016 Piyush Sharma. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD


class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate  {

    @IBOutlet weak var flickTableView: UITableView!
    @IBOutlet weak var networkErrorView: UIView!
    
    var movies: [NSDictionary]?
    var refreshControl: UIRefreshControl!
    var endpoint: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.flickTableView.backgroundColor = UIColor.
        self.networkErrorView.hidden = true
        flickTableView.dataSource = self
        flickTableView.delegate = self
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), forControlEvents: UIControlEvents.ValueChanged)
        flickTableView.insertSubview(refreshControl, atIndex: 0)
        
        // Reuse the method to do the first load as well
        self.refreshControlAction(refreshControl)
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if let movies = movies {
            return movies.count
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = flickTableView.dequeueReusableCellWithIdentifier("MovieCell", forIndexPath: indexPath) as! MovieCell
        let movie = self.movies?[indexPath.row]
        let title = movie?["title"] as? String
        let overview = movie?["overview"] as? String
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        
        let imageBaseUrl = "http://image.tmdb.org/t/p/w500"
        if let posterPath = movie?["poster_path"] as? String {
            let imageUrl = imageBaseUrl + posterPath
            let imageRequest = NSURLRequest(URL: NSURL(string: imageUrl)!)
            
            cell.movieImageView.setImageWithURLRequest(
                imageRequest,
                placeholderImage: nil,
                success: { (imageRequest, imageResponse, image) -> Void in
                    
                    // imageResponse will be nil if the image is cached
                    if imageResponse != nil {
                        //  print("Image was NOT cached, fade in image")
                        cell.movieImageView.alpha = 0.0
                        cell.movieImageView.image = image
                        UIView.animateWithDuration(0.3, animations: { () -> Void in
                            cell.movieImageView.alpha = 1.0
                        })
                    } else {
                        // print("Image was cached so just update the image")
                        cell.movieImageView.image = image
                    }
                },
                failure: { (imageRequest, imageResponse, error) -> Void in
                    cell.movieImageView.image = UIImage(named: "not_available.jpg")
            })
        }
        
        print("row \(indexPath.row)")
        return cell
    }

    
    // Makes a network request to get updated data
    // Updates the tableView with the new data
    // Hides the RefreshControl
    func refreshControlAction(refreshControl: UIRefreshControl) {
        
        if (!self.isConnectedToNetwork()) {
            print("Cannot reach network")
            refreshControl.endRefreshing()
            self.networkErrorView.hidden = false
            return;
        } else {
            self.networkErrorView.hidden = true
            self.networkErrorView.backgroundColor = UIColor(patternImage: UIImage(named: "networkerror.png")!)
        }
        
        let clientId = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = NSURL(string:"https://api.themoviedb.org/3/movie/\(endpoint)?api_key=\(clientId)")
        let request = NSURLRequest(URL: url!)
        let session = NSURLSession(
            configuration: NSURLSessionConfiguration.defaultSessionConfiguration(),
            delegate:nil,
            delegateQueue:NSOperationQueue.mainQueue()
        )
        
        // Display HUD right before the request is made
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        
        let task : NSURLSessionDataTask = session.dataTaskWithRequest(request,
                                                                      completionHandler: { (dataOrNil, response, error) in
                                                                        if let data = dataOrNil {
                                                                            if let responseDictionary = try! NSJSONSerialization.JSONObjectWithData(
                                                                                data, options:[]) as? NSDictionary {
                                                                                //NSLog("response: \(responseDictionary)")
                                                                                
                                                                                // Hide HUD once the network request comes back (must be done on main UI thread)
                                                                                MBProgressHUD.hideHUDForView(self.view, animated: true)
                                                                                
                                                                                self.movies = responseDictionary["results"] as? [NSDictionary]
                                                                                self.flickTableView.reloadData()
                                                                                self.refreshControl.endRefreshing()
                                                                            }
                                                                        }
        });
        task.resume()
    }
    
    // Reference: http://stackoverflow.com/questions/30743408/check-for-internet-connection-in-swift-2-ios-9
    func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        let cell = sender as! UITableViewCell
        let indexPath = flickTableView.indexPathForCell(cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destinationViewController as! DetailViewController
        detailViewController.movie = movie
        
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    

}
