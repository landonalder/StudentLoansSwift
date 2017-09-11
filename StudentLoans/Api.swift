//
//  Api.swift
//  StudentLoans
//
//  Created by Landon Alder on 9/8/17.
//  Copyright © 2017 Landon. All rights reserved.
//

import Foundation
import PromiseKit

let USERNAME = "landonalder"
let PASSWORD = "98jettaVR6!"

private func getPostRequest(url: String, body: [String: Any?]?) -> URLRequest {
    var urlRequest = URLRequest(url: URL(string: url)!)
    urlRequest.httpMethod = "POST"
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
    if let body = body {
        urlRequest.httpBody = try! JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
    }
    
    return urlRequest
}

public func fetchGreatLakesId() -> Promise<NSDictionary> {
    let requestBody = [
        "userId": USERNAME,
        "password": PASSWORD,
        "pin": "",
        "deviceId": "86FB6D13-5788-42BC-B360-DA168130757E|IPHONE",
        ]
    
    let session = URLSession.shared
    var urlRequest = getPostRequest(url: "https://www.mygreatlakes.org/borrower/m/authentication/applogin", body: requestBody)
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

public func updateGreatLakesRegistration(greatLakesId: String) -> Promise<String> {
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
    var urlRequest = getPostRequest(url: "https://www.mygreatlakes.org/borrower/m/notification/registrationUpdate", body: requestBody)
    urlRequest.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
    
    return session.dataTask(with: urlRequest).asString()
}

public func fetchGreatLakesBalance() -> Promise<NSDictionary> {
    let session = URLSession.shared
    var urlRequest = getPostRequest(url: "https://www.mygreatlakes.org/borrower/m/accountData", body: nil)
    urlRequest.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
    
    return session.dataTask(with: urlRequest).asDictionary()
}

public func fetchMohelaSessionToken() -> Promise<NSDictionary> {
    let requestBody = [
        "LoginID": USERNAME,
        "Source": "ios",
        "DeviceID": "5B3FB647-9D14-422E-8CA4-2189344BCEEF",
        "DevicePrint": "5B3FB647-9D14-422E-8CA4-2189344BCEEF",
        ]
    
    let session = URLSession.shared
    let urlRequest = getPostRequest(url: "https://www.mohela.com/MobileWebServices/MobLoginService.asmx/CheckLoginAndDevice2", body: requestBody)
    
    return session.dataTask(with: urlRequest).asDictionary();
}

public func loginToMohela(sessionToken: String) -> Promise<NSDictionary> {
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

public func fetchMohelaBalance(sessionToken: String) -> Promise<NSDictionary> {
    let requestBody = [
        "PersonnelKey": "6167931",
        "SessionToken": sessionToken,
        ]
    
    let session = URLSession.shared
    let urlRequest = getPostRequest(url: "https://www.mohela.com/MobileWebServices/MobAccountHomeService.asmx/GetAccountHomeDetails", body: requestBody)
    return session.dataTask(with: urlRequest).asDictionary()
}
