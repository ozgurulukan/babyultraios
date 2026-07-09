//
//  EntitlementManager.swift
//  BabyUltra
//
//  Created by Ozgur Ulukan on 18/07/24.
//

import SwiftUI

class EntitlementManager: ObservableObject {
    static let userDefaults = UserDefaults(suiteName: "com.BabyUltra")
    
    @AppStorage("hasPro", store: userDefaults)
    var hasPro: Bool = false 
}
