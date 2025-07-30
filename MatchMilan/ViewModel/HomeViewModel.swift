//
//  HomeViewModel.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var matchUsers: [MatchUser] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var currentPage: Int = 1
    @Published var canLoadMore: Bool = true
    
    private let perPage: Int = 10
    private var dataProvider: MatchesDataProviderProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(dataProvider: MatchesDataProviderProtocol = MatchesDataProvider()) {
        self.dataProvider = dataProvider
    }
    
    func fetchMatches(isRefreshing: Bool = false) {
        if isRefreshing {
            currentPage = 1
            canLoadMore = true
            dataProvider.shouldFallbackToLocal = false 
        }
        
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        errorMessage = nil
        
        dataProvider.fetchRemoteMatches(page: currentPage, perPage: perPage)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.message
                    if error == .noResults {
                        self?.canLoadMore = false
                    }
                }
            } receiveValue: { [weak self] matches in
                guard let self = self else { return }
                
                if isRefreshing {
                    self.matchUsers = matches
                } else {
                    self.matchUsers.append(contentsOf: matches)
                }
                
                self.canLoadMore = matches.count >= self.perPage
                if self.canLoadMore {
                    self.currentPage += 1
                }
            }
            .store(in: &cancellables)
    }
    
    func loadLocalMatches() {
        isLoading = true
        errorMessage = nil
        
        dataProvider.fetchLocalMatches()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.message
                }
            } receiveValue: { [weak self] matches in
                self?.matchUsers = matches
            }
            .store(in: &cancellables)
    }
    
    func refresh() {
        fetchMatches(isRefreshing: true)
    }
    
    func loadMoreIfNeeded() {
        fetchMatches()
    }
}


