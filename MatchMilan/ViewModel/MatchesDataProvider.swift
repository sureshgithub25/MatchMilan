//
//  MatchesDataProvider.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation
import SystemConfiguration

class MatchesDataProvider {
    
    // Fetch profile matches either from server or local storage based on network availability
    func getProfileMatches(onSuccess: @escaping ([MatchUser]) -> Void,
                           onFailure: @escaping (String) -> Void) {
        if isNetworkAvailable() {
            NetworkManager.shared.performRequest(for: .fetchMatches,
                                                 responseType: UserAPIResponse.self) { result in
                switch result {
                case .success(let responseData):
                    let profiles = MatchUser.from(response: responseData)
                    
                    profiles.forEach { profile in
                        let (exists, _) = CoreDataManager.shared.objectExists(ofType: UserMatch.self,
                                                                              matchingID: profile.id,
                                                                              withKey: "id")
                        
                        if !exists {
                            let newUser = CoreDataManager.shared.createObject(ofType: UserMatch.self)
                            newUser.name = profile.name
                            newUser.address = profile.address
                            newUser.status = profile.status
                            newUser.id = profile.id
                            newUser.profileImage = profile.profileImage
                            CoreDataManager.shared.saveChanges()
                        }
                    }
                    
                    onSuccess(profiles)
                    
                case .failure(let networkError):
                    let errorMessage: String
                    switch networkError {
                    case .invalidURL:
                        errorMessage = networkError.errorDescription
                    case .noResponse:
                        errorMessage = networkError.errorDescription
                    case .decodingFailed:
                        errorMessage = networkError.errorDescription
                    case .serverError(let statusCode):
                        errorMessage = "Server returned error code: \(statusCode)"
                    case .custom(let message):
                        errorMessage = message
                    }
                    onFailure(errorMessage)
                }
            }
        } else {
            let storedMatches = CoreDataManager.shared.fetchAll(ofType: UserMatch.self)
            var profiles: [MatchUser] = []
            
            for storedUser in storedMatches {
                var userDictionary: [String: Any] = [:]
                
                storedUser.entity.attributesByName.keys.forEach { key in
                    userDictionary[key] = storedUser.value(forKey: key)
                }
                
                if let jsonData = try? JSONSerialization.data(withJSONObject: userDictionary, options: []),
                   let profileModel = try? JSONDecoder().decode(MatchUser.self, from: jsonData) {
                    profiles.append(profileModel)
                }
            }
            onSuccess(profiles)
        }
    }
    
    // Check for active internet connection
    private func isNetworkAvailable() -> Bool {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout.size(ofValue: address))
        address.sin_family = sa_family_t(AF_INET)
        
        guard let reachability = withUnsafePointer(to: &address, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { pointer in
                SCNetworkReachabilityCreateWithAddress(nil, pointer)
            }
        }) else {
            return false
        }
        
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return false
        }
        
        return flags.contains(.reachable) && !flags.contains(.connectionRequired)
    }
}
