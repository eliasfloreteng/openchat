//
//  Item.swift
//  openchat
//
//  Created by Elias Floreteng on 2026-05-07.
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
