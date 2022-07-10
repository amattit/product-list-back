//
//  File.swift
//  
//
//  Created by 16997598 on 19.01.2021.
//

import Fluent
import Vapor

final class ProductSuggest: BaseEntity, Model, Content {
    static var schema = "ProductSuggest"
    
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
    
    @Field(key: "category")
    var category: String
    
    @Field(key: "price")
    var price: Double
    
    @Field(key: "imagePath")
    var imagePath: String
    
    @Field(key: "color")
    var color: String
    
    init() {}
    
    init(id: UUID? = nil, category: String, price: Double, title: String, imagePath: String, color: String = "") {
        self.id = id
        self.title = title
        self.price = price
        self.category = category
        self.imagePath = imagePath
        self.color = color
    }
}
