//
//  MatchesDataProvider.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation
import SystemConfiguration
import Combine

protocol MatchesDataProviderProtocol {
    func fetchRemoteMatches(page: Int, perPage: Int) -> AnyPublisher<[MatchUser], APIError>
    func fetchLocalMatches() -> AnyPublisher<[MatchUser], APIError>
    var shouldFallbackToLocal: Bool { get set }
}

final class MatchesDataProvider: MatchesDataProviderProtocol {
    private let networkService: NetworkServiceProtocol
    private let coreDataManager: CoreDataManagerProtocol
    private let networkMonitor: NetworkMonitorProtocol
    
    var shouldFallbackToLocal = true
    
    init(networkService: NetworkServiceProtocol = NetworkService.shared,
         coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared,
         networkMonitor: NetworkMonitorProtocol = NetworkMonitor.shared) {
        self.networkService = networkService
        self.coreDataManager = coreDataManager
        self.networkMonitor = networkMonitor
    }
    
    func fetchRemoteMatches(page: Int, perPage: Int) -> AnyPublisher<[MatchUser], APIError> {
        guard networkMonitor.isConnected else {
            if shouldFallbackToLocal {
                shouldFallbackToLocal = false // Only fallback once
                return fetchLocalMatches()
            }
            return Fail(error: APIError.noInternetConnection).eraseToAnyPublisher()
        }
        
        return networkService.request(MatchesEndpoint.fetchMatches(page: page, perPage: perPage))
            .map { (response: UserAPIResponse) in
                let matches = MatchUser.from(response: response)
                self.saveMatchesToCoreData(matches: matches)
                return matches
            }
            .eraseToAnyPublisher()
    }
    
    func fetchLocalMatches() -> AnyPublisher<[MatchUser], APIError> {
        Future<[MatchUser], APIError> { promise in
            let storedMatches = self.coreDataManager.fetchAll(ofType: UserMatch.self)
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
            
            if profiles.isEmpty {
                promise(.failure(.noResults))
            } else {
                promise(.success(profiles))
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func saveMatchesToCoreData(matches: [MatchUser]) {
        matches.forEach { match in
            let (exists, _) = coreDataManager.objectExists(ofType: UserMatch.self,
                                                          matchingID: match.id,
                                                          withKey: "id")
            
            if !exists {
                let newUser = coreDataManager.createObject(ofType: UserMatch.self)
                newUser.name = match.name
                newUser.address = match.address
                newUser.status = match.status
                newUser.id = match.id
                newUser.profileImage = match.profileImage
                coreDataManager.saveChanges()
            }
        }
    }
}
