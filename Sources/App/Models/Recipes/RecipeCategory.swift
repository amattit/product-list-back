//
//  File.swift
//  
//
//  Created by MikhailSeregin on 24.06.2022.
//

import Fluent
import Vapor

final class RecipeCategory: BaseEntity, Model {
    static let schema = "RecipeCategory"
    
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
    
    @Field(key: "imagePath")
    var imagePath: String?
    
    @Field(key: "order")
    var order: Int?
    
    @Siblings(through: RecipeCategoryRecipe.self, from: \.$category, to: \.$recipe)
    var recipes: [Recipe]
    
    init() {}
    
    init(id: UUID? = nil, title: String, imagePath: String?) {
        self.id = id
        self.title = title
        self.imagePath = imagePath
    }
}

final class Recipe: BaseEntity, Model {
    static let schema = "Recipe"
    
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
    
    @Field(key: "summary")
    var summary: String?
    
    @Field(key: "steps")
    var steps: String?
    
    @Field(key: "imagePath")
    var imagePath: String?
    
    @Siblings(through: RecipeCategoryRecipe.self, from: \.$recipe, to: \.$category)
    var recipes: [RecipeCategory]
    
    @Children(for: \.$recipe)
    var products: [RecipeProduct]
    
    init() {}
    
    init(
        id: UUID? = nil,
        title: String,
        summary: String? = nil,
        steps: String? = nil,
        imagePath: String? = nil
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.steps = steps
        self.imagePath = imagePath
    }
}

final class RecipeProduct: Model, BaseEntity {
    static let schema = "RecipeProduct"
    
    @Timestamp(key: "createdAt", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updatedAt", on: .update)
    var updatedAt: Date?
    
    @Timestamp(key: "deletedAt", on: .delete)
    var deletedAt: Date?
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "count")
    var count: String?
    
    @Parent(key: "recipeId")
    var recipe: Recipe
    
    init() {}
    
    init(
        id: UUID? = nil,
        title: String,
        count: String? = nil,
        recipeId: UUID
    ) {
        self.id = id
        self.title = title
        self.count = count
        self.$recipe.id = recipeId
    }
}

final class RecipeCategoryRecipe: Model {
    static let schema = "RecipeCategoryRecipe"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "recipeCategoryId")
    var category: RecipeCategory
    
    @Parent(key: "recipeId")
    var recipe: Recipe
    
    init() {}
    
    init(id: UUID? = nil, category: RecipeCategory, recipe: Recipe) throws {
        self.id = id
        self.category = category
        self.recipe = recipe
    }
}
