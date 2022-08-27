//
//  EyeNetworkingUtil.swift
//  EyeFi
//
//  Created by admin on 2022/8/25.
//

/***
 main functions:
 1. POST and GET
 2. Set the timeout
 3. retry times
 4. request grounp
 5. request dependent
 6. chain style
 7. Set the header
 8. do some work before request
 9. reachable check
 10. search request
 */

import UIKit
import Alamofire

//struct DecodableType: Decodable { let url: String }

class EyeNetworkingOperation:Operation {
    
    let lock = NSLock()
    var _executing:Bool = false
    var _finished = true
    var dataRequest:EyeDataRequest
    
    init(dataRquest:EyeDataRequest) {
        self.dataRequest = dataRquest
        super.init()
        dataRquest.finishBlock = { [self] finished in
            workDone()
        }
    }
    
    override func start() {
        self.lock.lock()
        if self.isCancelled {
            workDone()
        } else if self.isReady {
            main()
        }
        self.lock.unlock()
    }
    
    override func cancel() {
        super.cancel()
        self.dataRequest.dataRequest.cancel()
        self.workDone()
    }
    
    
    override func main() {
        willChangeValue(forKey: "isFinished")
        _finished = false
        didChangeValue(forKey: "isFinished")
        
        willChangeValue(forKey: "isExecuting")
        _executing = true
        didChangeValue(forKey: "isExecuting")
        self.dataRequest.dataRequest.resume()
    }
    
    override var isAsynchronous:Bool {
        return true
    }

    override var isExecuting:Bool {
        return _executing
    }
    
    override var isFinished: Bool {
        return _finished
    }
    
    func workDone() {
        willChangeValue(forKey: "isFinished")
        _finished = true
        didChangeValue(forKey: "isFinished")
        
        willChangeValue(forKey: "isExecuting")
        _executing = false
        didChangeValue(forKey: "isExecuting")
    }
}

class EyeDataRequest:NSObject {
    var dataRequest:DataRequest
    var finishBlock:((Int) -> ())? = nil
    var finished:Int = 0 {
        didSet {
            self.finishBlock?(finished)
        }
    }
    init(dataRequest:DataRequest) {
        self.dataRequest = dataRequest
        super.init()
    }
}

class EyeNetworkingUtil: NSObject {
    let queue = DispatchQueue(label: "com.datarquest.queue")
    let searchQueue = OperationQueue()
    let session = Session(startRequestsImmediately: false)
    var defaultRetryableHTTPMethods: Set<HTTPMethod> = [.post, .delete, .get,.head,.options,.put]
    var defaultRetryableHTTPStatusCodes: Set<Int> = [408, 500, 502, 503, 504]
    var defaultTimeOut:TimeInterval = 10
    var defaultCachePolicy:NSURLRequest.CachePolicy = .reloadIgnoringLocalCacheData
    var defaultRetryTimes:UInt = 5
    var retryTimeOffSet:Double = 5
    var encoder:ParameterEncoder = URLEncodedFormParameterEncoder.default
    var host:String
    var networkingStatusChanged:((NetworkReachabilityManager.NetworkReachabilityStatus) -> ())?
    var operationQueueDictionary = [String:OperationQueue]()
    var operationQueueResultDictionary = [String:Int]()
    init(host:String) {
        self.host = host
        super.init()
        NetworkReachabilityManager.default?.startListening(onQueue: .main, onUpdatePerforming: { status in
            self.networkingStatusChanged?(status)
        })
        searchQueue.maxConcurrentOperationCount = 1
    }
    
    func post<T:Decodable>(url:String,
                           param:[String:String?]? = nil,
                           success:((T)->(Void))? = nil,
                           failure:((Int, String)->(Void))? = nil,
                           headers:[String:String?]? = nil,
                           timeOut:TimeInterval? = nil,
                           cachePolicy:NSURLRequest.CachePolicy? = nil,
                           retryTimes:UInt? = nil,
                           retryTimeOffSet:Double? = nil,
                           encoder:ParameterEncoder? = nil,
                           startRequestsAutomactically:Bool = true,
                           type: T.Type = T.self
                            ) -> EyeDataRequest
    {
        var realUrl = url
        if !url.contains("http") {
            realUrl = host + url
        }
        var realParam:[String:String]?
        if param != nil {
            realParam = [String:String]()
            for key in param!.keys {
                if param![key] != nil {
                    realParam![key] = param![key]!
                }
            }
        }
        let realTimeout = timeOut == nil ?  self.defaultTimeOut : timeOut!
        
        var realHeader:HTTPHeaders? = nil
        if headers != nil {
            var headerDictionary = [String:String]()
            for key in headers!.keys {
                if headers![key] != nil {
                    headerDictionary[key] = headers![key]!!
                }
            }
            realHeader = HTTPHeaders(headerDictionary)
        }
        
        let realCachePolicy = cachePolicy == nil ? self.defaultCachePolicy : cachePolicy!
        let realRetryTimes:UInt = retryTimes == nil ? self.defaultRetryTimes : retryTimes!
        let realRetryTimeOffset:Double = retryTimeOffSet == nil ? self.retryTimeOffSet : retryTimeOffSet!
        let realEncoder:ParameterEncoder = self.encoder
        
        let request =  AF.request(realUrl, method:HTTPMethod.post, parameters:realParam, encoder:  realEncoder, headers:realHeader, interceptor:RetryPolicy(retryLimit: realRetryTimes, exponentialBackoffBase: 2, exponentialBackoffScale: realRetryTimeOffset, retryableHTTPMethods: self.defaultRetryableHTTPMethods, retryableHTTPStatusCodes: self.defaultRetryableHTTPStatusCodes)) { request in
            request.timeoutInterval = realTimeout
            request.cachePolicy = realCachePolicy
        }
        
        let dataRequest = EyeDataRequest(dataRequest: request)
        request.responseDecodable {(response:DataResponse<T, AFError>) in
            switch response.result {
            case .success(let res):
                success?(res)
                dataRequest.finished = 1
            case .failure(let error):
                dataRequest.finished = 0
                if (NetworkReachabilityManager.default?.isReachable ==  false) {
                    self.networkingStatusChanged?(NetworkReachabilityManager.NetworkReachabilityStatus.notReachable)
                    failure?(-2, error.localizedDescription)
                    return
                }
                failure?(-1, error.localizedDescription)
            }
        }
        if startRequestsAutomactically {
            request.resume()
        }
        return dataRequest
    }
    
    func addRequests(requests:[EyeDataRequest], complete: @escaping(Bool) -> ()) {
        let group = DispatchGroup()
        for request in requests {
            group.enter()
            queue.async {
                let re = request.dataRequest
                request.finishBlock = { (finish:Int) in
                    self.operationQueueResultDictionary[String(format: "%p", group)] = (self.operationQueueResultDictionary[String(format: "%p",group)] ?? 0) + finish
                    group.leave()
                }
                re.resume()
            }
        }
        group.notify(queue: queue) {
            let result = self.operationQueueResultDictionary[String(format: "%p",group)] ?? 0
            complete(result >= requests.count)
        }
    }
    
    func addDependencyRequest(first:EyeDataRequest, second:EyeDataRequest, complete:@escaping(Bool) -> ()) {
        let firstRequest = first.dataRequest
        first.finishBlock = { (finish:Int) in
            if finish == 1 {
                let secondRequest = second.dataRequest
                second.finishBlock = { (finish:Int) in
                    complete(finish == 1)
                }
                secondRequest.resume()
            } else {
                complete(false)
            }
        }
        firstRequest.resume()
    }
    
    func addSearchRequest(searchRequest:EyeDataRequest) {
        let searchOperation = EyeNetworkingOperation(dataRquest: searchRequest)
        self.searchQueue.cancelAllOperations()
        self.searchQueue.addOperation(searchOperation)
    }
    
    
}
