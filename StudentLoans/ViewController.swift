//
//  ViewController.swift
//  StudentLoans
//
//  Created by Landon Alder on 9/4/17.
//  Copyright © 2017 Landon. All rights reserved.
//

import UIKit
import PromiseKit

class ViewController: UIViewController {
    @IBOutlet weak var greatLakesTotalLabel: UILabel!
    @IBOutlet weak var greatLakesLoader: UIActivityIndicatorView!
    @IBOutlet weak var mohelaTotalLabel: UILabel!
    @IBOutlet weak var mohelaLoader: UIActivityIndicatorView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var totalLoader: UIActivityIndicatorView!

    var greatLakesBalance = 0.0
    var mohelaBalance = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateBalances()
    }
    
    @IBAction func handleRefreshButtonTap(_ sender: Any) {
        updateBalances()
    }
    
    func updateBalances() {
        totalLabel.isHidden = true;
        totalLoader.startAnimating();
        
        updateMohelaBalance()
        updateGreatLakesBalance()
    }
    
    func updateGreatLakesBalance() {
        greatLakesTotalLabel.isHidden = true;
        greatLakesLoader.startAnimating();
        
        firstly {
            fetchGreatLakesId()
        }.then { json in
            let greatLakesId = "\(json["greatLakesId"]!)"
            return updateGreatLakesRegistration(greatLakesId: greatLakesId)
        }.then { (_: String) in
            fetchGreatLakesBalance()
        }.then { json -> Void in
            let summaries = json["summaries"] as! [[String: Any]]
            let total = summaries[0]["totalBalance"] as! Double
            self.handleGreatLakesBalanceSuccess(totalBalance: total)
        }.catch { error in
            self.handleGreatLakesError(error: error)
        }
    }
    
    func handleGreatLakesError(error: Error) {
        DispatchQueue.main.async {
            self.greatLakesLoader.stopAnimating()
        }
    }
    
    func handleGreatLakesBalanceSuccess(totalBalance: Double) {
        greatLakesBalance = totalBalance
        
        DispatchQueue.main.async {
            self.greatLakesLoader.stopAnimating()
            self.greatLakesTotalLabel.text = "$\(totalBalance)"
            self.greatLakesTotalLabel.isHidden = false
            
            self.updateTotal()
        }
    }
    
    func updateMohelaBalance() {
        mohelaTotalLabel.isHidden = true;
        mohelaLoader.startAnimating();

        var sessionToken: String = ""
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
            let totalBalance = parsedResponse["TotalBalance"] as! Double

            self.handleMohelaBalanceSuccess(totalBalance: totalBalance)
        }.catch { _ in
            self.handleMohelaError()
        }
    }
    
    func handleMohelaError() {
        DispatchQueue.main.async { 
            self.mohelaLoader.stopAnimating()
        }
    }
    
    func handleMohelaBalanceSuccess(totalBalance: Double) {
        mohelaBalance = totalBalance

        DispatchQueue.main.async {
            self.mohelaLoader.stopAnimating()
            self.mohelaTotalLabel.text = "$\(totalBalance)"
            self.mohelaTotalLabel.isHidden = false
            
            self.updateTotal()
        }
    }
    
    func updateTotal() {
        guard !mohelaLoader.isAnimating && !greatLakesLoader.isAnimating else { return }
        
        let grandTotal = String(format: "%.2f", mohelaBalance + greatLakesBalance)
        DispatchQueue.main.async {
            self.totalLabel.text = "$\(grandTotal)"
            self.totalLabel.isHidden = false
            self.totalLoader.stopAnimating()
        }
    }
}

