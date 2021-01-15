//
//  File.swift
//  
//
//  Created by 16997598 on 14.01.2021.
//

import Fluent
import Vapor

protocol BaseEntity {
//    @ID(key: .id)
    var id: UUID? { get set }
    
//    @Field(key: "createdAt")
    var createdAt: Date? { get set }
    
//    @Field(key: "updatedAt")
    var updatedAt: Date? { get set }
    
//    @Field(key: "deletedAt")
    var deletedAt: Date? { get set }
}
