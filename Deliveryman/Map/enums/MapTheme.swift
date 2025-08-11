//
//  MapTheme.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 11.08.25.
//

enum MapTheme: String, CaseIterable {
    case spring = "Spring"
    
    var availableCategories: Set<MapAssetCategory> {
        let commonCategories: Set<MapAssetCategory> = [.tiles, .paths, .character]
        // commonCategories.union([.traffic, .neon, .smog])
        
        switch self {
        case .spring:
            return commonCategories
        
            /*
        case .winter:
            return commonCategories
            
        case .desert:
            return commonCategories
            
        case .city:
            return commonCategories
            */
        }
    }

    var uniqueCategories: Set<MapAssetCategory> {
        return availableCategories.filter { category in
            // Проверяем, есть ли эта категория в других темах
            let otherThemes = MapTheme.allCases.filter { $0 != self }
            return !otherThemes.contains { $0.availableCategories.contains(category) }
        }
    }
}
