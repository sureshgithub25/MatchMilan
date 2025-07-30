//
//  HomeView.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Find Your Match")
                .foregroundStyle(.primary)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            Group {
                if viewModel.isLoading && viewModel.matchUsers.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    ErrorView(
                        message: errorMessage,
                        onRetry: {
                            viewModel.loadLocalMatches()
                        }
                    )
                } else {
                    MatchListView(
                        matchUsers: $viewModel.matchUsers,
                        canLoadMore: viewModel.canLoadMore,
                        onRefresh: {
                            viewModel.refresh()
                        },
                        onLoadMore: {
                            viewModel.loadMoreIfNeeded()
                        }
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            if viewModel.matchUsers.isEmpty {
                viewModel.fetchMatches()
            }
        }
    }
}

// MARK: - Subviews

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: onRetry) {
                Text("Try Again")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MatchListView: View {
    @Binding var matchUsers: [MatchUser]
    let canLoadMore: Bool
    let onRefresh: () -> Void
    let onLoadMore: () -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                ForEach($matchUsers, id: \.id) { match in
                    MatchCardView(data: match)
                        .padding(.horizontal, 16)
                        .onAppear {
                            if match.wrappedValue.id == matchUsers.last?.id && canLoadMore {
                                onLoadMore()
                            }
                        }
                }
                
                if canLoadMore {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                }
            }
            .refreshable {
                onRefresh()
            }
        }
    }
}

#Preview {
    HomeView()
}
