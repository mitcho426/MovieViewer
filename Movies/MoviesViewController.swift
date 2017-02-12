//
//  MoviesViewController.swift
//  Movies
//
//  Created by mwong on 1/21/17.
//  Copyright © 2017 mwong. All rights reserved.
//

import UIKit
import AFNetworking
import MBProgressHUD

class MoviesViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIScrollViewDelegate  {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var movies: [NSDictionary]?
    var filteredTitles: [NSDictionary]?
    var endPoint: String!
    var isMoreDataLoading = false
    let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize a UIRefreshControl
        
        refreshControl.addTarget(self, action: #selector(refreshControlAction(_:)), for: UIControlEvents.valueChanged)
        // add refresh control to table view
        
        tableView.insertSubview(refreshControl, at: 0)
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self
        
        self.tableView.reloadData()
        
        self.networkRequest()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /*
     @param UITableView
     @return numbersOfRowsInSection
     */
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredTitles?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) ->  UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath) as! MoviesCell
        let movie = filteredTitles![indexPath.row]
        
        let title = movie["title"] as! String
        let overview = movie["overview"] as! String
        
        let smallBaseUrl = "https://image.tmdb.org/t/p/w45"
        let largeBaseUrl = "https://image.tmdb.org/t/p/original"
        
        if let posterPath = movie["poster_path"] as? String {
            
            //let imageUrl = NSURL(string: baseUrl + posterUrl)
            let smallImageUrl = NSURL(string: smallBaseUrl + posterPath)
            let largeImageUrl = NSURL(string: largeBaseUrl + posterPath)
            
            //let imageRequest = NSURLRequest(url: imageUrl as! URL)
            let smallImageRequest = NSURLRequest(url: smallImageUrl as! URL)
            let largeImageRequest = NSURLRequest(url: largeImageUrl as! URL)
            
            // Load low resolution poster image, followed by the high resolution version
            cell.posterView.setImageWith(smallImageRequest as URLRequest, placeholderImage: nil, success: { (smallImageRequest, smallImageResponse, smallImage) in
                if smallImageResponse != nil {
                    
                    // Fade the images as they load
                    cell.posterView.alpha = 0
                    cell.posterView.image = smallImage
                    UIView.animate(withDuration: 0.5, animations: {
                        cell.posterView.alpha = 1
                        
                    }, completion: { (success) -> Void in
                        // Load high resolution after low resolution images are completed
                        cell.posterView.setImageWith(largeImageRequest as URLRequest, placeholderImage: nil, success: { (largeImageRequest, slargeImageResponse, largeImage) in
                            cell.posterView.image = largeImage
                            
                        }, failure: {(imageRequest, imageResponse, error) -> Void in
                            
                        })
                    })
                } else {
                    // If images are cached, load the large resolution image
                    cell.posterView.setImageWith(largeImageRequest as URLRequest, placeholderImage: nil, success: { (largeImageRequest, slargeImageResponse, largeImage) in
                        cell.posterView.image = largeImage
                    }, failure: {(imageRequest, imageResponse, error) -> Void in
                        
                    })
                }
            }, failure: {(imageRequest, imageResponse, error) -> Void in
                
            })
        }
        
        
        cell.titleLabel.text = title
        cell.overviewLabel.text = overview
        cell.selectionStyle = .none
        
        return cell
    }
    
    func networkRequest() {
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endPoint!)?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: OperationQueue.main)
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if let data = data {
                if let dataDictionary = try! JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                    print(dataDictionary)
                    
                    self.movies = dataDictionary["results"] as? [NSDictionary]
                    self.filteredTitles = self.movies
                    self.tableView.reloadData()
                    
                    //Hides the loading HUD while there is internet connection
                    MBProgressHUD.hide(for: self.view, animated: true)
                }
            }
        }
        task.resume()
        
    }
    
    // Makes a network request to get updated data
    // Updates the tableView with the new data
    // Hides the RefreshControl
    func refreshControlAction(_ refreshControl: UIRefreshControl) {
        
        // ... Create the URLRequest `myRequest` ...
        
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endPoint!)?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        // Configure session so that completion handler is executed on main UI thread
        
        let session = URLSession(
            configuration: .default,
            delegate: nil,
            delegateQueue: OperationQueue.main)
        
        let task: URLSessionDataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in

            self.tableView.reloadData()
            refreshControl.endRefreshing()
        }
        task.resume()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filteredTitles = searchText.isEmpty ? movies : movies?.filter({(movie: NSDictionary) -> Bool in
            
            return (movie["title"] as! String).range(of: searchText, options: .caseInsensitive) != nil
        })
        
        self.tableView.reloadData()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.showsCancelButton = true
        searchBar.text = ""
        searchBar.resignFirstResponder()
        self.tableView.reloadData()
    }
    
    /*
     When a user scrolls down, the UIScrollView continuously fires this function
     We can customize the code inside that will repeatedly fire
     */
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        if(!isMoreDataLoading) {
            
            let scrollViewContentHeight = tableView.contentSize.height
            let scrollOffsetThreshold = scrollViewContentHeight - tableView.bounds.size.height
            
            if(scrollView.contentOffset.y > scrollOffsetThreshold && tableView.isDragging) {
                isMoreDataLoading = true
                loadMoreData()
                self.tableView.reloadData()
            }
        }
    }
    
    /*
     Helper function that loads more data as we continue scrolling
    */
    
    func loadMoreData() {
        
        // Grab API request
        let apiKey = "a07e22bc18f5cb106bfe4cc1f83ad8ed"
        let url = URL(string: "https://api.themoviedb.org/3/movie/\(endPoint!)?api_key=\(apiKey)")!
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        
        // Configure session so that completion handler is executed on main UI thread
        let session = URLSession(
            configuration: URLSessionConfiguration.default,
            delegate:nil,
            delegateQueue:OperationQueue.main
        )
        
        let task : URLSessionDataTask = session.dataTask(with: request,completionHandler: { (data, response, error) in
            self.isMoreDataLoading = false
            self.tableView.reloadData()
        });
        task.resume()
    }

    /*
     Prepares transition from this viewcontroller to the next.
     Declare a variable that references label and variables inside
     the DetailViewController class
     */
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let cell = sender as! UITableViewCell
        let indexPath = tableView.indexPath(for: cell)
        let movie = movies![indexPath!.row]
        
        let detailViewController = segue.destination as! DetailViewController
        
        detailViewController.movie = movie
    }
}
