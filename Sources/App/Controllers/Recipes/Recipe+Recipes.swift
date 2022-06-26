//
//  File.swift
//  
//
//  Created by MikhailSeregin on 26.06.2022.
//

import Vapor
import Fluent

/// Список рецептов
extension RecipeController {
    /// 2. Получить все рецепты **/api/v1/recipe** без привязки к категориям
    func getAllRecipes(req: Request) async throws -> [DTO.RecipeRs] {
        let recipes = try await Recipe.query(on: req.db).all()
        return try recipes.map { recipe in
            try DTO.RecipeRs(recipe: recipe)
        }
    }
    
    /// 1. Получить конкретный рецепт /api/v1/recipe/:recipeId
    func getRecipe(req: Request) async throws -> DTO.RecipeRs {
        guard let id = req.parameters.get("recipeId"), let uid = UUID(uuidString: id) else {
            throw Abort(.badRequest, reason: "Должен быть указан валидный id")
        }
        
        let recipe = try await Recipe.find(uid, on: req.db)
        guard let recipe = recipe else {
            throw Abort(.notFound, reason: "Рецепт с id \(id) не найден")
        }
        
        let products = try await recipe.$products.get(on: req.db).get()
        
        return try DTO.RecipeRs(
            recipe: recipe, products: products
        )
    }

    /// 5. Добавить продукты к списку покупок **[POST]/api/v1/list/:listId/recipe**
    /// на вход передается id списка продуктов в query
    /// В теле передается список продуктов для добавления в список
    func sendRecipeToList(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        guard let listId = req.parameters.get("listId"), let uid = UUID(uuidString: listId) else {
            throw Abort(.badRequest, reason: "Переданный id списка продуктов не валидный")
        }
        
        let list = try await ProductList.find(uid, on: req.db)
        guard let isAttach = try await list?.$user.isAttached(to: user, on: req.db), isAttach else {
            throw Abort(.badRequest, reason: "У вас нет прав модифицировать список продуктов")
        }
        
//         TODO: доработать
//         Получаем продукты в списке c признаком не купленные
//        let productsInList = try await Product
//            .query(on: req.db)
//            .filter(\.$productList.$id == uid)
//            .filter(\.$isDone == false)
//            .all()
//         проверяем какие продукты уже есть в списке (точное совпадение)
//         существующие продукты инкриментим
//         недостаюшие добавляем
        
        let products = try req.content.decode([DTO.RecipeProductRs].self).map {
            Product(
                title: $0.title,
                count: $0.count,
                isDone: false,
                userId: try user.requireID(),
                productListId: uid
            )
        }
        _ = try await products.create(on: req.db)
        return .ok
    }
    
    func getCount(from count: String) -> Double {
        let value = count.split(separator: ":")
            .map(String.init)
        guard value.count == 2 else {
            return 1
        }
        return Double(value[1]) ?? 1
    }
}
