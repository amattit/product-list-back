//
//  File.swift
//  
//
//  Created by MikhailSeregin on 24.06.2022.
//

import Fluent

struct CreateRecipe: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Recipe.schema)
            .id()
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime)
            .field("title", .string, .required)
            .field("summary", .string)
            .field("steps", .string)
            .field("imagePath", .string)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Recipe.schema).delete()
    }
}

struct CreateRecipeCategory: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(RecipeCategory.schema)
            .id()
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime)
            .field("title", .string, .required)
            .field("imagePath", .string)
            .field("order", .int)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(RecipeCategory.schema).delete()
    }
}

struct CreateRecipeProduct: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(RecipeProduct.schema)
            .id()
            .field("createdAt", .datetime, .required)
            .field("updatedAt", .datetime)
            .field("deletedAt", .datetime)
            .field("title", .string, .required)
            .field("count", .string)
            .field("recipeId", .uuid, .required, .references(Recipe.schema, "id", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(RecipeProduct.schema).delete()
    }
}

struct CreateRecipeCategoryRecipe: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(RecipeCategoryRecipe.schema)
            .id()
            .field("recipeCategoryId", .uuid, .required, .references(RecipeCategory.schema, "id"))
            .field("recipeId", .uuid, .required, .references(Recipe.schema, "id"))
            .unique(on: "recipeCategoryId", "recipeId")
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema(RecipeCategoryRecipe.schema).delete()
    }
}
