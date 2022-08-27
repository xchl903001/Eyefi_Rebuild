//
//  ViewController.swift
//  EyeFi
//
//  Created by admin on 2022/8/24.
//

import UIKit

struct BaseResponse<T:Decodable>: Decodable {
    let data:T
    let message : String
    let status : Int
}

struct EyeMainGlassInfo: Decodable {
    let level:Int
    let quality:Int
    let qualityName:String
    let tokenId:Int
}

struct EyeUserBalanceModel: Decodable {
    
    let avatarUrl:String
    let email:String
    let energy:Float
    let energyCap:Float
    let estVisionReward:Float
    let eyeBalance:Float
    let ethBalance:Float
    let glasses:EyeMainGlassInfo?
    let nextRefillEnergy:Float
    let nextRefillTime:Int
    let openableVisionBags:Int
    let reward:Float
    let rewardCap:Float
    let userId:Int
    let userName:String
}



class EyefiRootViewController: UIViewController {
    let networking = EyeNetworkingUtil(host: "http://api.eyes.finance")
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.red
        let URL_USE_BLANCE = "/user/balance/summary.json"

//        let networking = EyeNetworkingUtil<BaseResponse<S: Decodable>>(host: "1")
       //
        
        
       let dataRequest =  networking.post(url: "/user/balance/summary.json", param: ["ticket":"VGKR537M8zcirhNhkH0Xl7eWIYcIPXqc66KgK2Hoo9m3L56ELxvvl6GSHrkS5yiT"]) { (result:BaseResponse<EyeUserBalanceModel>)in
            print(1)
        }
        let dataRequest2 =  networking.post(url: "/user/balance/summary.json", param: ["ticket":"VGKR537M8zcirhNhkH0Xl7eWIYcIPXqc66KgK2Hoo9m3L56ELxvvl6GSHrkS5yiT"]) { (result:BaseResponse<EyeUserBalanceModel>)in
             print(2)
         }
        let dataRequest3 =  networking.post(url: "/user/balance/summary.json", param: ["ticket":"VGKR537M8zcirhNhkH0Xl7eWIYcIPXqc66KgK2Hoo9m3L56ELxvvl6GSHrkS5yiT"]) { (result:BaseResponse<EyeUserBalanceModel>)in
             print(3)
         }
        networking.addSearchRequest(searchRequest: dataRequest)
        networking.addSearchRequest(searchRequest: dataRequest2)
        networking.addSearchRequest(searchRequest: dataRequest3)
    }
}

