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

    let USERNAME = "landonalder"
    let PASSWORD = ""
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
    
    func getPostRequest(url: String, body: [String: Any?]?) -> URLRequest {
        var urlRequest = URLRequest(url: URL(string: url)!)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body = body {
            urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
        }
        
        return urlRequest
    }
    
    func fetchGreatLakesId() -> Promise<NSDictionary> {
        let requestBody = [
            "userId": USERNAME,
            "password": PASSWORD,
            "pin": "",
            "deviceId": "86FB6D13-5788-42BC-B360-DA168130757E|IPHONE",
        ]
        
        let session = URLSession.shared
        var urlRequest = self.getPostRequest(url: "https://www.mygreatlakes.org/borrower/m/authentication/applogin", body: requestBody)
        urlRequest.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/59.0.3071.115 Safari/537.36", forHTTPHeaderField: "User-Agent")
        urlRequest.setValue("TLTSID=2fe36009.5562f9953d6b4; JSESSIONID_oc_infoserv=0001FHSI28twJxuGfbYOCdwAnL3:19ia5a0s6; GLDCID=.mad", forHTTPHeaderField: "Set-Cookie")
        
        return session.dataTask(with: urlRequest).asString().then { stringValue in
            if (stringValue == "Error 202: Deprecated API Version\n") {
                return session.dataTask(with: urlRequest).asDictionary()
            }

            let json = try! JSONSerialization.jsonObject(with: stringValue.data(using: .utf8)!, options: []) as! NSDictionary
            return Promise(value: json)
        }
    }
    
    func updateGreatLakesRegistration(greatLakesId: String) -> Promise<String> {
        let requestBody: [String: Any] = [
            "id": greatLakesId,
            "notificationTypes": ["PPMTREM", "PPMTPOS"],
            "registrationType": "REGISTER",
            "device": [
                "type": "iOS",
                "appVersionNr": "22.0",
                "id": "be48a348e72fea62e4112080e08a84a30817e8608d47b26dcc7a54b5df1dbdd1",
                "uuid": "86FB6D13-5788-42BC-B360-DA168130757E",
            ],
        ]
        
        let session = URLSession.shared
        var urlRequest = self.getPostRequest(url: "https://www.mygreatlakes.org/borrower/m/notification/registrationUpdate", body: requestBody)
        urlRequest.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")

        return session.dataTask(with: urlRequest).asString()
    }
    
    func fetchGreatLakesBalance() -> Promise<NSDictionary> {
        let session = URLSession.shared
        var urlRequest = self.getPostRequest(url: "https://www.mygreatlakes.org/borrower/m/accountData", body: nil)
        urlRequest.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")

        return session.dataTask(with: urlRequest).asDictionary()
    }
    
    func updateGreatLakesBalance() {
        greatLakesTotalLabel.isHidden = true;
        greatLakesLoader.startAnimating();
        
        firstly {
            self.fetchGreatLakesId()
        }.then { json in
            let greatLakesId = "\(json["greatLakesId"]!)"
            return self.updateGreatLakesRegistration(greatLakesId: greatLakesId)
        }.then { (_: String) in
            self.fetchGreatLakesBalance()
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
    
    func fetchMohelaSessionToken() -> Promise<NSDictionary> {
        let requestBody = [
            "LoginID": USERNAME,
            "Source": "ios",
            "DeviceID": "5B3FB647-9D14-422E-8CA4-2189344BCEEF",
            "DevicePrint": "5B3FB647-9D14-422E-8CA4-2189344BCEEF",
        ]
        
        let session = URLSession.shared
        let urlRequest = self.getPostRequest(url: "https://www.mohela.com/MobileWebServices/MobLoginService.asmx/CheckLoginAndDevice2", body: requestBody)
        
        return session.dataTask(with: urlRequest).asDictionary();
    }
    
    func loginToMohela(sessionToken: String) -> Promise<NSDictionary> {
        let requestBody: [String: Any?] = [
            "LoginID": USERNAME,
            "Source": "ios",
            "DeviceID": "5B3FB647-9D14-422E-8CA4-2189344BCEEF",
            "DevicePrint": "5B3FB647-9D14-422E-8CA4-2189344BCEEF",
            "SessionToken": sessionToken,
            "AccountType": "B",
            "PersonnelKey": -1,
            "Success": true,
            "InstalledApp": true,
            "MoreThanOneLoan": nil,
            "CanPayOnline": nil,
            "CanPayLineItem": nil,
            "Password": PASSWORD,
        ]
        
        let session = URLSession.shared
        let urlRequest = getPostRequest(url: "https://www.mohela.com/MobileWebServices/MobLoginService.asmx/CheckPassword2", body: requestBody)

        return session.dataTask(with: urlRequest).asDictionary()
    }
    
    func fetchMohelaBalance(sessionToken: String) -> Promise<NSDictionary> {
        let requestBody = [
            "PersonnelKey": "6167931",
            "SessionToken": sessionToken,
        ]
        
        let session = URLSession.shared
        let urlRequest = getPostRequest(url: "https://www.mohela.com/MobileWebServices/MobAccountHomeService.asmx/GetAccountHomeDetails", body: requestBody)
        return session.dataTask(with: urlRequest).asDictionary()
    }
    
    func updateMohelaBalance() {
        mohelaTotalLabel.isHidden = true;
        mohelaLoader.startAnimating();

        var sessionToken: String = ""
        firstly {
            self.fetchMohelaSessionToken()
        }.then { json in
            let parsedResponse = json["d"] as! [String: Any]
            sessionToken = parsedResponse["SessionToken"] as! String

            return self.loginToMohela(sessionToken: sessionToken)
        }.then { (_ : NSDictionary) in
            self.fetchMohelaBalance(sessionToken: sessionToken)
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

