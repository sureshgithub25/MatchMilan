//
//  UserModel.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation
import Combine
import CoreData

enum MatchResult: String, Codable {
    case accepted
    case pending
    case declined
}

struct MatchUser: Codable {
    let id: String
    let profileImage: String
    let name: String
    let address: String
    var status: String
}

struct MatchesResponse: Codable {
    let results: [MatchUser]
    let page: Int
    let totalPages: Int
}

//struct UserAPIResponse: Codable {
//    let results: [UserProfile]
//    
//    struct UserProfile: Codable {
//        let userID: UserID?
//        let images: UserImages?
//        let nameDetails: NameDetails?
//        let address: UserAddress?
//        
//        enum CodingKeys: String, CodingKey {
//            case userID = "id"
//            case images = "picture"
//            case nameDetails = "name"
//            case address = "location"
//        }
//    }
//    
//    struct UserID: Codable {
//        let idValue: String?
//        
//        enum CodingKeys: String, CodingKey {
//            case idValue = "value"
//        }
//    }
//    
//    struct UserImages: Codable {
//        let large: String
//    }
//    
//    struct NameDetails: Codable {
//        let firstName: String
//        let lastName: String
//    }
//    
//    struct UserAddress: Codable {
//        let streetInfo: StreetInfo?
//        let city: String
//        let state: String
//        
//        struct StreetInfo: Codable {
//            let houseNumber: Int
//            let streetName: String
//        }
//    }
//}

extension MatchUser {
    static func from(response: UserAPIResponse) -> [MatchUser] {
        var users: [MatchUser] = []
        
        response.results.forEach { userProfile in
            let userId = userProfile.userID?.idValue ?? UUID().uuidString
            let imageUrl = userProfile.images?.large ?? ""
            let fullName = "\(userProfile.nameDetails?.firstName ?? "") \(userProfile.nameDetails?.lastName ?? "")"
            let fullAddress = """
            \(userProfile.address?.streetInfo?.houseNumber ?? 0) \
            \(userProfile.address?.streetInfo?.streetName ?? ""), \
            \(userProfile.address?.city ?? ""), \
            \(userProfile.address?.state ?? "")
            """
            
            let matchUser = MatchUser(
                id: userId,
                profileImage: imageUrl,
                name: fullName,
                address: fullAddress,
                status: MatchResult.pending.rawValue
            )
            users.append(matchUser)
        }
        
        return users
    }
}

