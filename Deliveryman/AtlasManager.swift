//
//  Untitled.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 11.08.25.
//

import SpriteKit

class AtlasManager {
    
    // MARK: - Singleton
    static let shared = AtlasManager()
    private init() {}
    
    // MARK: - Properties
    private var loadedAtlases: [String: SKTextureAtlas] = [:]
    private var loadingQueue: [String: [(Bool) -> Void]] = [:]
    
    // MARK: - Loading Methods
    
    /// Загружает атласы для ключа
    /// - Parameters:
    ///   - key: Ключ группы атласов (например "SpringMap", "WinterMap", "UI")
    ///   - atlasNames: Массив названий атласов (например ["Tiles", "Paths", "Character"])
    ///   - completion: Колбэк срабатывает когда все атласы загружены (параллельно)
    func loadAtlases(for key: String, atlasNames: [String], completion: @escaping (Bool) -> Void) {
        guard !atlasNames.isEmpty else {
            completion(true)
            return
        }
        
        var completedCount = 0
        var hasErrors = false
        let totalCount = atlasNames.count
        
        // Загружаем все атласы параллельно
        for atlasName in atlasNames {
            let fullAtlasName = "\(key)\(atlasName)"
            
            loadAtlas(named: fullAtlasName) { success in
                completedCount += 1
                if !success {
                    hasErrors = true
                }
                
                // Все атласы обработаны
                if completedCount == totalCount {
                    let result = !hasErrors
                    print(result ? "✅ Все атласы загружены для \(key)" : "❌ Ошибки при загрузке \(key)")
                    completion(result)
                }
            }
        }
    }
    
    /// Получает текстуру из атласа
    /// - Parameters:
    ///   - textureName: Название текстуры (например "tile", "left-path", "play-button")
    ///   - atlasName: Название атласа (например "Tiles", "Paths", "Buttons")
    ///   - key: Ключ группы (например "SpringMap", "WinterMap", "UI")
    /// - Returns: SKTexture или nil если не найдена
    func texture(named textureName: String, atlas atlasName: String, key: String) -> SKTexture {
        let fullAtlasName = "\(key)\(atlasName)"
        
        guard let atlas = loadedAtlases[fullAtlasName] else {
            print("⚠️ Атлас не загружен: \(fullAtlasName)")
            return SKTexture()
        }

        return atlas.textureNamed(textureName)
    }
    
    // MARK: - Unloading Methods
    
    /// Выгружает всю группу полностью
    /// - Parameter key: Ключ группы для выгрузки (например "SpringMap", "UI")
    func unloadGroup(_ key: String) {
        let keysToRemove = loadedAtlases.keys.filter { $0.hasPrefix(key) }
        
        for atlasKey in keysToRemove {
            loadedAtlases.removeValue(forKey: atlasKey)
        }
    }
    
    /// Выгружает конкретные атласы из группы
    /// - Parameters:
    ///   - key: Ключ группы (например "SpringMap", "UI")
    ///   - atlasNames: Массив названий атласов для выгрузки
    func unloadAtlases(for key: String, atlasNames: [String]) {
        guard !atlasNames.isEmpty else { return }
        
        var removedCount = 0
        
        for atlasName in atlasNames {
            let fullAtlasName = "\(key)\(atlasName)"
            if loadedAtlases.removeValue(forKey: fullAtlasName) != nil {
                removedCount += 1
            }
        }
    }
    
    /// Очищает весь кеш атласов
    func clearAll() {
        loadedAtlases.removeAll()
    }
    
    // MARK: - Status Methods
    
    /// Проверяет, загружен ли атлас
    /// - Parameters:
    ///   - atlasName: Название атласа
    ///   - key: Ключ группы
    /// - Returns: true если атлас загружен
    func isAtlasLoaded(_ atlasName: String, for key: String) -> Bool {
        let fullAtlasName = "\(key)\(atlasName)"
        return loadedAtlases[fullAtlasName] != nil
    }
    
    /// Получает список всех загруженных атласов
    /// - Returns: Словарь [полное_имя_атласа: атлас]
    func getLoadedAtlases() -> [String: SKTextureAtlas] {
        return loadedAtlases
    }
    
    /// Получает статистику по группе
    /// - Parameter key: Ключ группы
    /// - Returns: (загружено_атласов, список_названий)
    func getGroupStats(for key: String) -> (count: Int, atlasNames: [String]) {
        let groupAtlases = loadedAtlases.keys.compactMap { atlasKey -> String? in
            guard atlasKey.hasPrefix(key) else { return nil }
            return String(atlasKey.dropFirst(key.count))
        }
        
        return (groupAtlases.count, groupAtlases.sorted())
    }
    
    // MARK: - Private Methods
    
    private func loadAtlas(named atlasName: String, completion: @escaping (Bool) -> Void) {
        // Уже загружен
        if loadedAtlases[atlasName] != nil {
            completion(true)
            return
        }
        
        // Уже загружается
        if loadingQueue[atlasName] != nil {
            loadingQueue[atlasName]?.append(completion)
            return
        }
        
        // Начинаем загрузку
        loadingQueue[atlasName] = [completion]
        
        let atlas = SKTextureAtlas(named: atlasName)
        atlas.preload { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Сохраняем в кеш
                self.loadedAtlases[atlasName] = atlas
                
                // Вызываем все колбэки
                let callbacks = self.loadingQueue[atlasName] ?? []
                self.loadingQueue.removeValue(forKey: atlasName)
                callbacks.forEach { $0(true) }
            }
        }
    }
}
