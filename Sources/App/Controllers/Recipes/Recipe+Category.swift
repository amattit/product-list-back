//
//  File.swift
//  
//
//  Created by MikhailSeregin on 26.06.2022.
//

import Vapor
import Fluent

extension RecipeController {
    /// 3. Получить список категорий рецептов **[GET]/api/v1/recipe/category**
    func getCategories(req: Request) async throws -> [DTO.CategoryRs] {
        let categories = try await RecipeCategory.query(on: req.db).all()
        
        var response: [DTO.CategoryRs] = []
        
        for category in categories {
            let count = try await RecipeCategory.query(on: req.db)
                .filter(\.$id == category.requireID())
                .sort(\.$order, .ascending)
                .count()
                
            response.append(
                DTO.CategoryRs(
                    id: try category.requireID(),
                    title: category.title,
                    imagePath: category.imagePath,
                    count: count.description
                )
            )
        }
        return response
    }
    
    /// 4. Получить все рецепты в категории **[GET]/api/v1/recipe/category/:id**
    func getRecipeInCategory(req: Request) async throws -> [DTO.RecipeRs] {
        guard let id = req.parameters.get("categoryId"), let uid = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "Должен быть указан валидный id")
        }
        
        let category = try await RecipeCategory.find(uid, on: req.db)
        guard let category = category else {
            throw Abort(.notFound, reason: "Категория рецептов с id \(id) не найдена")
        }
        
        return try await category.$recipes.get(on: req.db).map { recipe in
            try DTO.RecipeRs(recipe: recipe)
        }
    }
}
