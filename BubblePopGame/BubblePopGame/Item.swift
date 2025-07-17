//
//  Item.swift
//  BubblePopGame
//  
//  Created on 2025/07/17
//


import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
