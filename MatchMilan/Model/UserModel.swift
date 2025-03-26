//
//  UserModel.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation

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
    
    // Factory method to map from updated API response
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

