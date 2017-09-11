//
//  TodayViewController.swift
//  StudentLoansToday
//
//  Created by Landon Alder on 9/10/17.
//  Copyright © 2017 Landon. All rights reserved.
//

import UIKit
import NotificationCenter
import PromiseKit

class TodayViewController: UIViewController, NCWidgetProviding {
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var greatLakesBalance = 0.0
    var mohelaBalance = 0.0
    var updatingMohelaBalance = true;
    var updatingGreatLakesBalance = true;
        
    override func viewDidLoad() {
        super.viewDidLoad()
        let _border = CAShapeLayer()
        _border.path = UIBezierPath(roundedRect: refreshButton.bounds, cornerRadius:refreshButton.frame.size.width/2).cgPath
        _border.frame = refreshButton.bounds
        _border.fillColor = UIColor.lightGray.cgColor;
        _border.opacity = 0.7;
        _border.lineWidth = 3.0
        refreshButton.layer.addSublayer(_border)
        
        updateBalances()
        // Do any additional setup after loading the view from its nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    
    @IBAction func refreshTapped(_ sender: Any) {
        updateBalances()
    }
    
    func updateBalances() {
        totalLabel.isHidden = true;
        activityIndicator.startAnimating();
        
        
        updateMohelaBalance()
        updateGreatLakesBalance()
    }
    
    func updateGreatLakesBalance() {
        updatingGreatLakesBalance = true;
        firstly {
            fetchGreatLakesId()
            }.then { json in
                let greatLakesId = "\(json["greatLakesId"]!)"
                return updateGreatLakesRegistration(greatLakesId: greatLakesId)
            }.then { (_: String) in
                fetchGreatLakesBalance()
            }.then { json -> Void in
                let summaries = json["summaries"] as! [[String: Any]]
                self.greatLakesBalance = summaries[0]["totalBalance"] as! Double
                self.updatingGreatLakesBalance = false;
                self.updateTotal()
            }.catch { _ in
                self.handleError()
        }
    }
    
    func updateMohelaBalance() {
        var sessionToken: String = ""
        updatingMohelaBalance = true;
        firstly {
            fetchMohelaSessionToken()
            }.then { json in
                let parsedResponse = json["d"] as! [String: Any]
                sessionToken = parsedResponse["SessionToken"] as! String
                
                return loginToMohela(sessionToken: sessionToken)
            }.then { (_ : NSDictionary) in
                fetchMohelaBalance(sessionToken: sessionToken)
            }.then { json -> Void in
                let parsedResponse = json["d"] as! [String: Any]
                self.mohelaBalance = parsedResponse["TotalBalance"] as! Double
                self.updatingMohelaBalance = false;
                self.updateTotal()
            }.catch { _ in
                self.handleError()
        }
    }
    
    func updateTotal() {
        guard !updatingMohelaBalance && !updatingGreatLakesBalance else { return }
        activityIndicator.stopAnimating();
        
        let grandTotal = String(format: "%.2f", mohelaBalance + greatLakesBalance)
        DispatchQueue.main.async {
            self.totalLabel.text = "$\(grandTotal)"
            self.totalLabel.isHidden = false
            self.activityIndicator.stopAnimating()
        }
    }
    
    func handleError() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.totalLabel.text = "Error fetching"
            self.totalLabel.isHidden = false
        }
    }
}
