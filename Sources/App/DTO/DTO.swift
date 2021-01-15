//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Vapor

struct DTO {
    struct UpsertListRq: Content {
        let id: UUID?
        let title: String
    }
    
    struct ListRs: Content {
        let id: UUID
        let title: String
        let count: Int
    }
    
    struct CreateProductRq: Content {
        let title: String?
        let count: Double?
        let measureUnit: String?
    }
    
    struct ProductRs: Content {
        let id: UUID
        let title: String
        let count: Double?
        let measureUnit: String?
        let isDone: Bool
    }
    
    struct AuthRq: Content {
        let uid: String
        let pushToken: String?
        let os: String
    }
    
    struct AuthRs: Content {
        let token: String
    }
}
