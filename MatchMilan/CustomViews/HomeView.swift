//
//  HomeView.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import SwiftUI

struct HomeView: View {
    
    @StateObject private var viewModel = HomeViewModel(data: MatchesDataProvider())
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Find Your Match")
                .foregroundStyle(.primary)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            Group {
                if viewModel.isLoading {
                    PulseLoaderView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if !viewModel.error.isEmpty {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text(viewModel.error)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            ForEach($viewModel.matchUser, id: \.id) { match in
                                MatchCardView(data: match)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(UIColor.systemGroupedBackground))
        .onAppear {
            viewModel.fetchUserMatches()
        }
    }
}

#Preview {
    HomeView()
}
