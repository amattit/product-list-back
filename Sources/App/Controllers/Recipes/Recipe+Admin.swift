//
//  File.swift
//  
//
//  Created by MikhailSeregin on 26.06.2022.
//

import Vapor
import Fluent

// создание рецептов
// Сначала создать категории
extension RecipeController {
    // TODO: Добавить авторизацию к запросам
    /// Создание категорий
    func createCategory(req: Request) async throws -> [DTO.CategoryRs] {
        let category = try req.content.decode(DTO.CreateCategoryRq.self)
        let newCategory = RecipeCategory(title: category.title, imagePath: category.imagePath)
        try await newCategory.save(on: req.db)
        
        return try await RecipeCategory.query(on: req.db).all().map {
            DTO.CategoryRs(id: try $0.requireID(), title: $0.title, imagePath: $0.imagePath, count: "")
        }
    }
    
    /// **[POST]/api/v1/recipe/category/:categoryId**
    func createRecipe(req: Request) async throws -> DTO.RecipeRs {
        let recipeDTO = try req.content.decode(DTO.CreateRecipeRq.self)
        guard let categoryId = req.parameters.get("categoryId"), let uid = UUID(uuidString: categoryId) else {
            throw Abort(.badRequest, reason: "Должен быть указан валидный id")
        }
        
        guard let category = try await RecipeCategory.find(uid, on: req.db) else {
            throw Abort(.badRequest, reason: "Категория с id \(categoryId) не найдена")
        }
        
        let recipe = Recipe(title: recipeDTO.title, summary: recipeDTO.summary, steps: recipeDTO.steps, imagePath: recipeDTO.imagePath)
        try await recipe.save(on: req.db)
        
        let products = try recipeDTO.products.map {
            RecipeProduct(title: $0.title, count: $0.count, recipeId: try recipe.requireID())
        }
        
        try await products.create(on: req.db)
        
        try await category.$recipes.attach(recipe, on: req.db)
        
        return try DTO.RecipeRs(recipe: recipe, products: products)
    }
}

