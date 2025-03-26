//
//  NetworkManager.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noResponse
    case serverError(statusCode: Int)
    case decodingFailed
    case custom(message: String)
    
    var errorDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL encountered."
        case .noResponse:
            return "No response received from the server."
        case .serverError(let statusCode):
            return "Server returned an error with status code: \(statusCode)."
        case .decodingFailed:
            return "Failed to decode the server response."
        case .custom(let message):
            return message
        }
    }
}

enum APIEndpoint {
    case fetchMatches
    
    var method: String {
        switch self {
        case .fetchMatches:
            return "GET"
        }
    }
    
    var urlString: String {
        switch self {
        case .fetchMatches:
            return "https://randomuser.me/api/?results=10"
        }
    }
    
    var url: URL? {
        return URL(string: urlString)
    }
}

final class NetworkManager {
    static let shared = NetworkManager()
    private init() {}
    
    func performRequest<T: Decodable>(for endpoint: APIEndpoint, 
                                      responseType: T.Type,
                                      completion: @escaping (Result<T, NetworkError>) -> Void) {
        
        guard let url = endpoint.url else {
            completion(.failure(.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard let httpResponse = response as? HTTPURLResponse, let data = data else {
                completion(.failure(.noResponse))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.serverError(statusCode: httpResponse.statusCode)))
                return
            }
            
            do {
                let decodedData = try JSONDecoder().decode(T.self, from: data)
                completion(.success(decodedData))
            } catch {
                completion(.failure(.decodingFailed))
            }
            
        }.resume()
    }
}

