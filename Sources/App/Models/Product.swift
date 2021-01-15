//
//  File.swift
//  
//
//  Created by 16997598 on 15.01.2021.
//

import Fluent
import Vapor

final class Product: BaseEntity, Model {
    static var schema = "Product"
    
    @ID(key: .id)
    var id: UUID?
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deletedAt", on: .delete)
    var deletedAt: Date?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "count")
    var count: Double?
    
    @Field(key: "measureUnit")
    var measureUnit: String?
    
    @Field(key: "isDone")
    var isDone: Bool
    
    @Parent(key: "userId")
    var user: User
    
}

