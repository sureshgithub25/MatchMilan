//
//  DataModel.swift
//  MatchMilan
//
//  Created by Suresh Kumar on 26/03/25.
//

import Foundation

struct UserAPIResponse: Codable {
    let results: [UserProfile]
    let metadata: ResponseInfo

    enum CodingKeys: String, CodingKey {
        case results
        case metadata = "info"
    }
}

struct ResponseInfo: Codable {
    let seed: String?
    let resultsCount: Int?
    let currentPage: Int?
    let apiVersion: String?

    enum CodingKeys: String, CodingKey {
        case seed
        case resultsCount = "results"
        case currentPage = "page"
        case apiVersion = "version"
    }
}

struct UserProfile: Codable {
    let gender: String?
    let nameDetails: UserName?
    let address: UserLocation?
    let email: String?
    let loginCredentials: LoginInfo?
    let birthDetails, registrationDetails: DateInfo?
    let phoneNumber, cellNumber: String?
    let userID: UserID?
    let images: UserImages?
    let nationality: String?

    enum CodingKeys: String, CodingKey {
        case gender
        case nameDetails = "name"
        case address = "location"
        case email
        case loginCredentials = "login"
        case birthDetails = "dob"
        case registrationDetails = "registered"
        case phoneNumber = "phone"
        case cellNumber = "cell"
        case userID = "id"
        case images = "picture"
        case nationality = "nat"
    }
}

struct DateInfo: Codable {
    let date: String?
    let age: Int?
}

struct UserID: Codable {
    let idType: String?
    let idValue: String?

    enum CodingKeys: String, CodingKey {
        case idType = "name"
        case idValue = "value"
    }
}

struct UserLocation: Codable {
    let streetInfo: StreetAddress?
    let city, state, country: String?

    enum CodingKeys: String, CodingKey {
        case streetInfo = "street"
        case city, state, country
    }
}

struct StreetAddress: Codable {
    let houseNumber: Int?
    let streetName: String?

    enum CodingKeys: String, CodingKey {
        case houseNumber = "number"
        case streetName = "name"
    }
}

struct LoginInfo: Codable {
    let uuid, username, password, salt: String?
    let md5, sha1, sha256: String?
}

struct UserName: Codable {
    let title, firstName, lastName: String?

    enum CodingKeys: String, CodingKey {
        case title
        case firstName = "first"
        case lastName = "last"
    }
}

struct UserImages: Codable {
    let large, medium, thumbnail: String?
}


