//
//  MapAssetCategory.swift
//  Deliveryman
//
//  Created by Dmitriy Mitrofansky on 11.08.25.
//

enum MapAssetCategory: String, CaseIterable, Hashable {
    // Общие категории (есть во всех темах)
    case tiles = "Tiles"
    case paths = "Paths"
    case character = "Character"
    case buildings = "Buildings"
}
