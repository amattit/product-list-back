//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Fluent
import Vapor

final class Device: BaseEntity, Model {
    static let schema = "Device"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deletedAt", on: .delete)
    var deletedAt: Date?
    
    @Field(key: "os")
    var os: String
    
    @Field(key: "uid")
    var uid: String
    
    @Field(key: "token")
    var pushToken: String?
    
    @Parent(key: "userId")
    var user: User
    
    init() {}
    
    init(id: UUID? = nil, os: String, uid: String, token: String? = nil, userId: UUID) {
        self.id = id
        self.os = os
        self.uid = uid
        self.pushToken = token
        self.$user.id = userId
    }
}

