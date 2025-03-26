//
//  HomeViewModel.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation

final class HomeViewModel: ObservableObject {
    @Published var matchUser: [MatchUser] = []
    @Published var isLoading: Bool = false
    var error: String = ""
    
    
    private let data: MatchesDataProvider
    
    init(data: MatchesDataProvider) {
        self.data = data
    }
    
    func fetchUserMatches() {
        isLoading = true
        data.getProfileMatches { [weak self] data in
            DispatchQueue.main.async {
                self?.matchUser = data
                self?.isLoading = false
            }
            
        } onFailure: { [weak self] message in
            DispatchQueue.main.async {
                self?.isLoading = false
                self?.error = message
            }
        }
    }
    
}
