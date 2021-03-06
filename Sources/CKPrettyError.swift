//
//  CKPrettyError.swift
//  OpenCloudKit
//
//  Created by Ben Johnson on 29/07/2016.
//
//

import Foundation


enum CKError {
    case network(Error)
    case server([String: Any])
    case parse(Error)
    
    var error: NSError {
        switch  self {
        case .network(let networkError):
            return ckError(forNetworkError: NSError(error: networkError))
        case .server(let dictionary):
            return ckError(forServerResponseDictionary: dictionary)
        case .parse(let parseError):
            let error = NSError(error: parseError)
            return NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: error.userInfo )
        }
    }
    
    func ckError(forNetworkError networkError: NSError) -> NSError {
        let userInfo = networkError.userInfo
        let errorCode: CKErrorCode
        
        switch networkError.code {
        case NSURLErrorNotConnectedToInternet:
            errorCode = .NetworkUnavailable
        case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
            errorCode = .ServiceUnavailable
        default:
            errorCode = .NetworkFailure
        }
        
        let error = NSError(domain: CKErrorDomain, code: errorCode.rawValue, userInfo: userInfo)
        return error
    }
    
    func ckError(forServerResponseDictionary dictionary: [String: Any]) -> NSError {
        if let recordFetchError = CKRecordFetchErrorDictionary(dictionary: dictionary) {
            
            let errorCode = CKErrorCode.errorCode(serverError: recordFetchError.serverErrorCode)!
            
            var userInfo: NSErrorUserInfoType = [:]
            
            userInfo["redirectURL"] = recordFetchError.redirectURL
            userInfo[NSLocalizedDescriptionKey] = recordFetchError.reason
            
            userInfo[CKErrorRetryAfterKey] = recordFetchError.retryAfter
            userInfo["uuid"] = recordFetchError.uuid
            
            return NSError(domain: CKErrorDomain, code: errorCode.rawValue, userInfo: userInfo)
        } else {
            
            let userInfo = [:] as NSErrorUserInfoType
            return NSError(domain: CKErrorDomain, code: CKErrorCode.InternalError.rawValue, userInfo: userInfo)
        }
    }
}

class CKPrettyError: NSError {

    /*
     
     CVarArgs not automatically supported in Swift Linux

    convenience init(code: CKErrorCode, format: String, _ args: CVarArg...){
        let description = String(format: format, arguments: args)
        self.init(code, userInfo: nil, error: nil, path: nil, URL: nil, description: description)
    }

    convenience init(code: CKErrorCode, userInfo: NSErrorUserInfoType, format: String, _ args: CVarArg...){
        let description = String(format: format, arguments: args)
        self.init(code: code, userInfo: userInfo, description: description)
    }
    */
    
    convenience init(code: CKErrorCode, description: String) {
        self.init(code, userInfo: nil, error: nil, path: nil, URL: nil, description: description)
    }
    
    convenience init(code: CKErrorCode, userInfo: NSErrorUserInfoType, description: String) {
        self.init(code, userInfo: userInfo, error: nil, path: nil, URL: nil, description: description)
    }
    
    init(_ code: CKErrorCode, userInfo: NSErrorUserInfoType?, error: Error?, path: String?, URL: URL?, description: String?){
        var userInfo = userInfo
        
        if(description != nil){
            if(userInfo == nil){
                userInfo = NSErrorUserInfoType()
            }
            userInfo?[NSLocalizedDescriptionKey] = description;
            userInfo?["CKErrorDescription"] = description;
        }
        
        super.init(domain: CKErrorDomain, code: code.rawValue, userInfo: userInfo)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    //override var description: String{
        //<CKError 0x618000240c60: "Operation Cancelled" (20); "Operation <TestOperation: 0x7f876f405ea0; operationID=1644E6818C660C6E, stateFlags=executing|cancelled, qos=Utility> was cancelled before it started">
    //}
    
    override public var description: String {
        // \(withUnsafePointer(to: self))
        return "<CKError: \"\(CKErrorCode(rawValue: self.code)?.description)\" (\(self.code)); \(self.userInfo)";
    }
}
