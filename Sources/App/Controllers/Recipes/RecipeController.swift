//
//  File.swift
//  
//
//  Created by MikhailSeregin on 24.06.2022.
//

import Fluent
import Vapor

/// Контроллер рецептов. Может работать без авторизации
/// Что может делать:
/// 1. Получить конкретный рецепт **[GET]/api/v1/recipe/:recipeId**
/// 2. Получить все рецепты **[GET]/api/v1/recipe без привязки к категориям**
/// 3. Получить список категорий рецептов **[GET]/api/v1/recipe/category**
/// 4. Получить все рецепты в категории **[GET]/api/v1/recipe/category/:id**
///
/// Требуется авторизация
/// 5. Добавить продукты к списку покупок **[POST]/api/v1/recipe/:recipeId**
struct RecipeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let api = routes.grouped("api")
        let v1 = api.grouped("v1")
        // группировка по пути /api/v1/recipe
        let recipe = v1.grouped("recipe")
        recipe.get(use: getAllRecipes)
        recipe.get(":recipeId", use: getRecipe)
        // группировка по пути /api/v1/recipe/category
        let category = recipe.grouped("category")
        category.get(use: getCategories)
        category.get(":categoryId", use: getRecipeInCategory)
        // для добавления продуктов из рецепта в список покупок
        let tokenProtected = v1.grouped(Token.authenticator())
        
        category.post(use: createCategory)
        category.post(":categoryId", use: createRecipe)
    }
}

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

//    /// 5. Добавить продукты к списку покупок **[POST]/api/v1/recipe/:recipeId**
//    func sendRecipeToList(req: Request) async throws -> HTTPStatus {
//
//    }
}

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
