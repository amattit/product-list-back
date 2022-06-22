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
        let count: String
    }
    
    struct CreateProductRq: Content {
        let title: String?
        let count: String?
        let measureUnit: String?
    }
    
    struct ProductRs: Content {
        let id: UUID
        let title: String
        let count: String?
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
    
    struct UpdatePushTokenRq: Content {
        let uid: String
        let pushToken: String?
        let os: String
    }
    
    struct Profile: Content {
        let id: UUID
        let devices: [Device]
        let username: String?
    }
    
    struct SetUsernameRq: Content {
        let username: String
    }
    
    struct Device: Content {
        let uid: String
        let pushToken: String?
        let os: String
    }
}
