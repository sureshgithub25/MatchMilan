//
//  NetworkManager.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation
import Combine

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

enum APIError: Error, Equatable {
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.noResults, .noResults): return true
        default: return false
        }
    }
    
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case decodingError(Error)
    case unknown(Error)
    case noResults
    case imageProcessingFailed
    case rateLimitExceeded
    case noInternetConnection
    
    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .statusCode(let code):
            return "Status code: \(code)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .unknown(_):
            return "tinny hiccup"
        case .noResults:
            return "result not found."
        case .imageProcessingFailed:
            return "image processing Falied"
        case .rateLimitExceeded:
            return "rate limit exceeded"
        case .noInternetConnection:
            return "No internet Connection"
        }
    }
}

protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}

extension Endpoint {
    var headers: [String: String]? {
        return [
            "Content-Type": "application/json",
            "Accept": "application/json"
        ]
    }
    
    var body: Data? {
        return nil
    }
        
    func makeRequest() throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw APIError.invalidURL
        }
        
        urlComponents.path = path
        urlComponents.queryItems = queryItems
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        headers?.forEach { request.addValue($1, forHTTPHeaderField: $0) }
        
        return request
    }
}

enum MatchesEndpoint: Endpoint {
    case fetchMatches(page: Int, perPage: Int)
    
    var baseURL: String {
        return "https://randomuser.me"
    }
    
    var path: String {
        switch self {
        case .fetchMatches:
            return "/api"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .fetchMatches(let page, let perPage):
            return [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "results", value: "\(perPage)")
            ]
        }
    }
}

protocol NetworkServiceProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, APIError>
}

final class NetworkService: NetworkServiceProtocol {
    static let shared = NetworkService()
    private let urlSession: URLSession
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    func request<T: Decodable>(_ endpoint: Endpoint) -> AnyPublisher<T, APIError> {
        do {
            let request = try endpoint.makeRequest()
            
            return urlSession.dataTaskPublisher(for: request)
                .tryMap { data, response -> Data in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw APIError.invalidResponse
                    }
                    
                    if httpResponse.statusCode == 403 {
                        throw APIError.rateLimitExceeded
                    }
                    
                    guard (200..<300).contains(httpResponse.statusCode) else {
                        throw APIError.statusCode(httpResponse.statusCode)
                    }
                    
                    return data
                }
                .decode(type: T.self, decoder: JSONDecoder())
                .mapError { error -> APIError in
                    if let apiError = error as? APIError {
                        return apiError
                    } else if let decodingError = error as? DecodingError {
                        return .decodingError(decodingError)
                    } else {
                        return .unknown(error)
                    }
                }
                .eraseToAnyPublisher()
        } catch {
            return Fail(error: APIError.invalidURL).eraseToAnyPublisher()
        }
    }
}

